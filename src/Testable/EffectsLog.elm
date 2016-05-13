module Testable.EffectsLog exposing (EffectsLog, empty, insert, containsHttpAction, httpRequests, httpAction, sleepAction)

import FakeDict as Dict exposing (Dict)
import PairingHeap exposing (PairingHeap)
import Testable.Cmd
import Testable.Internal as Internal exposing (Cmd, TaskResult(..))
import Testable.Http as Http
import Time exposing (Time)


type EffectsResult action
    = Finished action
    | MoreEffects (Testable.Cmd.Cmd action)


type EffectsLog action
    = EffectsLog
        { http :
            -- TODO: should be multidict
            Dict Http.Request (Result Http.RawError Http.Response -> EffectsResult action)
        , now : Time
        , sleep : PairingHeap Time (EffectsResult action)
        }


empty : EffectsLog action
empty =
    EffectsLog
        { http = Dict.empty
        , now = 0
        , sleep = PairingHeap.empty
        }


unsafeFromResult : TaskResult a a -> EffectsResult a
unsafeFromResult result =
    case result of
        Success a ->
            Finished a

        Failure a ->
            Finished a

        Continue next ->
            MoreEffects (Internal.TaskCmd next)


{-| Returns the new EffectsLog and any actions that should be applied immediately
-}
insert : Testable.Cmd.Cmd action -> EffectsLog action -> ( EffectsLog action, List action )
insert effects (EffectsLog log) =
    case effects of
        Internal.None ->
            ( EffectsLog log, [] )

        Internal.TaskCmd (Internal.HttpTask request mapResponse) ->
            ( EffectsLog { log | http = Dict.insert request (mapResponse >> unsafeFromResult) log.http }
            , []
            )

        Internal.TaskCmd (Internal.ImmediateTask result) ->
            case unsafeFromResult result of
                Finished action ->
                    ( EffectsLog log, [ action ] )

                MoreEffects next ->
                    EffectsLog log
                        |> insert next

        Internal.TaskCmd (Internal.SleepTask milliseconds result) ->
            if milliseconds <= 0 then
                insert (Internal.TaskCmd (Internal.ImmediateTask result)) (EffectsLog log)
            else
                ( EffectsLog { log | sleep = PairingHeap.insert ( log.now + milliseconds, unsafeFromResult result ) log.sleep }
                , []
                )

        Internal.Batch list ->
            let
                step effect ( log', immediates ) =
                    case insert effect log' of
                        ( log'', immediates' ) ->
                            ( log'', immediates ++ immediates' )
            in
                List.foldl step ( EffectsLog log, [] ) list


containsHttpAction : Http.Request -> EffectsLog action -> Bool
containsHttpAction request (EffectsLog log) =
    Dict.get request log.http
        |> (/=) Nothing


httpRequests : EffectsLog action -> List Http.Request
httpRequests (EffectsLog log) =
    Dict.keys log.http


httpAction : Http.Request -> Result Http.RawError Http.Response -> EffectsLog action -> Maybe ( EffectsLog action, List action )
httpAction expectedRequest response (EffectsLog log) =
    case Dict.get expectedRequest log.http of
        Nothing ->
            Nothing

        Just mapResponse ->
            case mapResponse response of
                Finished action ->
                    Just
                        ( EffectsLog { log | http = Dict.remove expectedRequest log.http }
                        , [ action ]
                        )

                MoreEffects next ->
                    EffectsLog log
                        |> insert next
                        |> Just


sleepAction : Time -> EffectsLog action -> ( EffectsLog action, List action )
sleepAction milliseconds (EffectsLog log) =
    case PairingHeap.findMin log.sleep of
        Nothing ->
            ( EffectsLog { log | now = log.now + milliseconds }
            , []
            )

        Just ( time, result ) ->
            if time <= log.now + milliseconds then
                case result of
                    Finished action ->
                        -- TODO: recurse
                        ( EffectsLog
                            { log
                                | sleep = PairingHeap.deleteMin log.sleep
                                , now = log.now + milliseconds
                            }
                        , [ action ]
                        )

                    MoreEffects next ->
                        -- TODO: recurse
                        EffectsLog
                            { log
                                | sleep = PairingHeap.deleteMin log.sleep
                                , now = log.now + milliseconds
                            }
                            |> insert next
            else
                ( EffectsLog { log | now = log.now + milliseconds }
                , []
                )
