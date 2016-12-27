port module Testable.EffectsLogTests exposing (..)

import Expect
import Test exposing (..)
import Testable.Cmd
import Testable.EffectsLog as EffectsLog exposing (EffectsLog, wrappedCmds)
import Testable.Http as Http
import Testable.Task as Task
import Platform.Cmd


type MyWrapper a
    = MyWrapper a


port myPort : String -> Platform.Cmd.Cmd msg


httpGetMsg : String -> String -> EffectsLog msg -> Maybe ( EffectsLog msg, List msg )
httpGetMsg url responseBody =
    EffectsLog.httpMsg Http.defaultSettings (Http.ok responseBody)


all : Test
all =
    describe "Testable.EffectsLog"
        [ describe "resulting msgs"
            [ test "directly consuming the result" <|
                \() ->
                    EffectsLog.empty
                        |> EffectsLog.insert
                            (Http.getString "https://example.com/"
                                |> Http.toTask
                                |> Task.attempt identity
                            )
                        |> Tuple.first
                        |> httpGetMsg "https://example.com/" "responseBody"
                        |> Maybe.map Tuple.second
                        |> Expect.equal (Just [ Ok "responseBody" ])
            , test "mapping the result" <|
                \() ->
                    EffectsLog.empty
                        |> EffectsLog.insert
                            (Http.getString "https://example.com/"
                                |> Http.toTask
                                |> Task.attempt MyWrapper
                            )
                        |> Tuple.first
                        |> httpGetMsg "https://example.com/" "responseBody"
                        |> Maybe.map Tuple.second
                        |> Expect.equal (Just [ MyWrapper <| Ok "responseBody" ])
            , test "resolving a request that doesn't match gives Nothing" <|
                \() ->
                    EffectsLog.empty
                        |> EffectsLog.insert
                            (Http.getString "https://example.com/"
                                |> Http.toTask
                                |> Task.attempt identity
                            )
                        |> Tuple.first
                        |> httpGetMsg "https://XXXX/" "responseBody"
                        |> Maybe.map Tuple.second
                        |> Expect.equal Nothing
            , test "resolving a non-Http effect gives Nothing" <|
                \() ->
                    EffectsLog.empty
                        |> EffectsLog.insert (Testable.Cmd.none |> Testable.Cmd.map MyWrapper)
                        |> Tuple.first
                        |> httpGetMsg "https://example.com/" "responseBody"
                        |> Maybe.map Tuple.second
                        |> Expect.equal Nothing
            , test "inserting a port inserts the port cmd" <|
                \() ->
                    EffectsLog.insert (Testable.Cmd.wrap <| myPort "foo") EffectsLog.empty
                        |> Tuple.first
                        |> wrappedCmds
                        |> Expect.equal [ myPort "foo" ]
            , test "does not treat ports with different values as equal" <|
                \() ->
                    EffectsLog.insert (Testable.Cmd.wrap <| myPort "foo") EffectsLog.empty
                        |> Tuple.first
                        |> wrappedCmds
                        |> Expect.notEqual [ myPort "bar" ]
            ]
        ]
