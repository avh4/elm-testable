module Testable.TaskTests exposing (all)

import Test exposing (..)
import Expect exposing (Expectation)
import Task as PlatformTask
import Testable.Task exposing (..)
import Time exposing (Time)
import Process


expectSleepTask : Time -> (Task x a -> Expectation) -> Task x a -> Expectation
expectSleepTask expectedDelay checkNext task =
    case task of
        Core_NativeScheduler_sleep delay next ->
            Expect.all
                [ always delay >> Expect.equal expectedDelay
                , next >> checkNext
                ]
                ()

        _ ->
            Expect.fail ("Expected (Core_NativeScheduler_sleep " ++ toString expectedDelay ++ " ...), but got: " ++ toString task)


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
                        |> expectSleepTask 5 (Expect.equal <| Success ())
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
                            |> expectSleepTask 5 (Expect.equal <| Success <| Ok ())
                , test "with chained tasks" <|
                    \() ->
                        Process.sleep 1
                            |> PlatformTask.andThen (\_ -> Process.sleep 2)
                            |> PlatformTask.andThen (\_ -> Process.sleep 3)
                            |> PlatformTask.map Just
                            |> fromPlatformTask
                            |> expectSleepTask 1 (expectSleepTask 2 <| expectSleepTask 3 <| Expect.equal <| Success (Just ()))
                ]
            , describe "andThen"
                [ test "with succeed" <|
                    \() ->
                        PlatformTask.succeed 7
                            |> PlatformTask.andThen Process.sleep
                            |> fromPlatformTask
                            |> expectSleepTask 7 (Expect.equal <| Success ())
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
                            |> expectSleepTask 2 (expectSleepTask 7 <| Expect.equal <| Success ())
                , test "chained tasks" <|
                    \() ->
                        (Process.sleep 2 |> PlatformTask.map (always 7))
                            |> PlatformTask.map ((+) 10)
                            |> PlatformTask.andThen (Process.sleep >> PlatformTask.map (always 20))
                            |> PlatformTask.map ((+) 10)
                            |> fromPlatformTask
                            |> expectSleepTask 2 (expectSleepTask 17 <| Expect.equal <| Success 30)
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
                            |> expectSleepTask 9 (Expect.equal <| Success ())
                ]
            ]
        ]
