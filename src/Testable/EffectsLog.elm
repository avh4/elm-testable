module Testable.EffectsLog exposing (EffectsLog, empty, insert, containsHttpMsg, httpRequests, httpMsg, sleepMsg)

import FakeDict as Dict exposing (Dict)
import PairingHeap exposing (PairingHeap)
import Testable.Cmd
import Testable.Internal as Internal exposing (Cmd, TaskResult(..))
import Testable.Http as Http
import Time exposing (Time)


type EffectsResult msg
    = Finished msg
    | MoreEffects (Testable.Cmd.Cmd msg)


type EffectsLog msg
    = EffectsLog
        { http :
            -- TODO: should be multidict
            Dict ( Http.Settings, Http.Request ) (Result Http.RawError Http.Response -> EffectsResult msg)
        , now : Time
        , sleep : PairingHeap Time (EffectsResult msg)
        }


empty : EffectsLog msg
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


{-| Returns the new EffectsLog and any msgs that should be applied immediately
-}
insert : Testable.Cmd.Cmd msg -> EffectsLog msg -> ( EffectsLog msg, List msg )
insert effects (EffectsLog log) =
    case effects of
        Internal.None ->
            ( EffectsLog log, [] )

        Internal.TaskCmd (Internal.HttpTask settings request mapResponse) ->
            ( EffectsLog { log | http = Dict.insert ( settings, request ) (mapResponse >> unsafeFromResult) log.http }
            , []
            )

        Internal.TaskCmd (Internal.ImmediateTask result) ->
            case unsafeFromResult result of
                Finished msg ->
                    ( EffectsLog log, [ msg ] )

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


containsHttpMsg : Http.Settings -> Http.Request -> EffectsLog msg -> Bool
containsHttpMsg settings request (EffectsLog log) =
    Dict.get ( settings, request ) log.http
        |> (/=) Nothing


httpRequests : EffectsLog msg -> List Http.Request
httpRequests (EffectsLog log) =
    Dict.keys log.http
        |> List.map snd


httpMsg : Http.Settings -> Http.Request -> Result Http.RawError Http.Response -> EffectsLog msg -> Maybe ( EffectsLog msg, List msg )
httpMsg expectedSettings expectedRequest response (EffectsLog log) =
    case Dict.get ( expectedSettings, expectedRequest ) log.http of
        Nothing ->
            Nothing

        Just mapResponse ->
            case mapResponse response of
                Finished msg ->
                    Just
                        ( EffectsLog { log | http = Dict.remove ( expectedSettings, expectedRequest ) log.http }
                        , [ msg ]
                        )

                MoreEffects next ->
                    EffectsLog log
                        |> insert next
                        |> Just


sleepMsg : Time -> EffectsLog msg -> ( EffectsLog msg, List msg )
sleepMsg milliseconds (EffectsLog log) =
    case PairingHeap.findMin log.sleep of
        Nothing ->
            ( EffectsLog { log | now = log.now + milliseconds }
            , []
            )

        Just ( time, result ) ->
            if time <= log.now + milliseconds then
                case result of
                    Finished msg ->
                        -- TODO: recurse
                        ( EffectsLog
                            { log
                                | sleep = PairingHeap.deleteMin log.sleep
                                , now = log.now + milliseconds
                            }
                        , [ msg ]
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
