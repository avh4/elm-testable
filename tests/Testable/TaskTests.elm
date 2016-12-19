module Testable.TaskTests exposing (all)

import Test exposing (..)
import Expect
import Task as PlatformTask
import Testable.Task exposing (..)
import Process


all : Test
all =
    describe "Testable.Task"
        [ describe "fromPlatformTask"
            [ test "succeed" <|
                \() ->
                    PlatformTask.succeed "A"
                        |> fromPlatformTask
                        |> Expect.equal (Success "A")
            , test "fail" <|
                \() ->
                    PlatformTask.fail "A"
                        |> fromPlatformTask
                        |> Expect.equal (Failure "A")
            , test "sleep" <|
                \() ->
                    Process.sleep 5
                        |> fromPlatformTask
                        |> Expect.equal (SleepTask 5 <| Success ())
            , describe "map"
                [ test "with succeed" <|
                    \() ->
                        PlatformTask.succeed "A"
                            |> PlatformTask.map Ok
                            |> fromPlatformTask
                            |> Expect.equal (Success <| Ok "A")
                , test "with fail" <|
                    \() ->
                        PlatformTask.fail "A"
                            |> PlatformTask.map Ok
                            |> fromPlatformTask
                            |> Expect.equal (Failure "A")
                , test "with sleep" <|
                    \() ->
                        Process.sleep 5
                            |> PlatformTask.map Ok
                            |> fromPlatformTask
                            |> Expect.equal (SleepTask 5 <| Success <| Ok ())
                , test "with chained tasks" <|
                    \() ->
                        Process.sleep 1
                            |> PlatformTask.andThen (\_ -> Process.sleep 2)
                            |> PlatformTask.andThen (\_ -> Process.sleep 3)
                            |> PlatformTask.map Just
                            |> fromPlatformTask
                            |> Expect.equal (SleepTask 1 <| SleepTask 2 <| SleepTask 3 <| Success (Just ()))
                ]
            , describe "andThen"
                [ test "with succeed" <|
                    \() ->
                        PlatformTask.succeed 7
                            |> PlatformTask.andThen Process.sleep
                            |> fromPlatformTask
                            |> Expect.equal (SleepTask 7 <| Success ())
                , test "with fail" <|
                    \() ->
                        PlatformTask.fail "X"
                            |> PlatformTask.andThen Process.sleep
                            |> fromPlatformTask
                            |> Expect.equal (Failure "X")
                , test "with sleep" <|
                    \() ->
                        Process.sleep 2
                            |> PlatformTask.map (always 7)
                            |> PlatformTask.andThen Process.sleep
                            |> fromPlatformTask
                            |> Expect.equal (SleepTask 2 <| SleepTask 7 <| Success ())
                , test "chained tasks" <|
                    \() ->
                        (Process.sleep 2 |> PlatformTask.map (always 7))
                            |> PlatformTask.map ((+) 10)
                            |> PlatformTask.andThen (Process.sleep >> PlatformTask.map (always 20))
                            |> PlatformTask.map ((+) 10)
                            |> fromPlatformTask
                            |> Expect.equal (SleepTask 2 <| SleepTask 17 <| Success 30)
                ]
            , describe "onError"
                [ test "with succeed" <|
                    \() ->
                        PlatformTask.succeed ()
                            |> PlatformTask.onError Process.sleep
                            |> fromPlatformTask
                            |> Expect.equal (Success ())
                , test "with fail" <|
                    \() ->
                        PlatformTask.fail 9
                            |> PlatformTask.onError Process.sleep
                            |> fromPlatformTask
                            |> Expect.equal (SleepTask 9 <| Success ())
                ]
            ]
        ]
