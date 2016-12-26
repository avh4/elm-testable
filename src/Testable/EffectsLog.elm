module Testable.EffectsLog exposing (EffectsLog, empty, insert, containsHttpMsg, httpRequests, wrappedCmds, containsCmd, httpMsg, sleepMsg)

import FakeDict as Dict exposing (Dict)
import PairingHeap exposing (PairingHeap)
import Testable.Cmd
import Testable.Internal as Internal exposing (Cmd, TaskResult(..))
import Testable.Http as Http
import Time exposing (Time)
import Platform.Cmd


type EffectsResult msg
    = Finished msg
    | MoreEffects (Testable.Cmd.Cmd msg)


type EffectsLog msg
    = EffectsLog
        { http :
            Dict Http.Settings (Result Http.Error (Http.Response String) -> EffectsResult msg)
        , now : Time
        , sleep : PairingHeap Time (EffectsResult msg)
        , wrappedCmds : List (Platform.Cmd.Cmd msg)
        }


empty : EffectsLog msg
empty =
    EffectsLog
        { http = Dict.empty
        , now = 0
        , sleep = PairingHeap.empty
        , wrappedCmds = []
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

        Internal.TaskCmd (Internal.HttpTask settings mapResponse) ->
            ( EffectsLog { log | http = Dict.insert settings (mapResponse >> unsafeFromResult) log.http }
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
                step effect ( log_, immediates ) =
                    case insert effect log_ of
                        ( log__, immediates_ ) ->
                            ( log__, immediates ++ immediates_ )
            in
                List.foldl step ( EffectsLog log, [] ) list

        Internal.WrappedCmd cmd ->
            ( EffectsLog { log | wrappedCmds = cmd :: log.wrappedCmds }, [] )


containsHttpMsg : Http.Settings -> EffectsLog msg -> Bool
containsHttpMsg settings (EffectsLog log) =
    Dict.get settings log.http
        |> (/=) Nothing


httpRequests : EffectsLog msg -> List Http.Settings
httpRequests (EffectsLog log) =
    Dict.keys log.http


containsCmd : Platform.Cmd.Cmd msg -> EffectsLog msg -> Bool
containsCmd cmd =
    List.member cmd << wrappedCmds


wrappedCmds : EffectsLog msg -> List (Platform.Cmd.Cmd msg)
wrappedCmds (EffectsLog log) =
    log.wrappedCmds


httpMsg : Http.Settings -> Result Http.Error (Http.Response String) -> EffectsLog msg -> Maybe ( EffectsLog msg, List msg )
httpMsg expectedSettings response (EffectsLog log) =
    case Dict.get expectedSettings log.http of
        Nothing ->
            Nothing

        Just mapResponse ->
            case mapResponse response of
                Finished msg ->
                    Just
                        ( EffectsLog { log | http = Dict.remove expectedSettings log.http }
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
