module Test.TaskTests exposing (..)

import Expect
import Task
import Test exposing (..)
import Test.Task
import Time


all : Test
all =
    describe "Test.Task"
        [ describe "resolvedTask"
            [ test "for Task.succeed gives Ok" <|
                \() ->
                    Task.succeed "A"
                        |> Test.Task.resolvedTask
                        |> Expect.equal (Just (Ok "A"))
            , test "for Task.fail gives Err" <|
                \() ->
                    Task.fail "X"
                        |> Test.Task.resolvedTask
                        |> Expect.equal (Just (Err "X"))
            , test "for other tasks, gives Nothing" <|
                \() ->
                    Time.now
                        |> Test.Task.resolvedTask
                        |> Expect.equal Nothing
            , test "works with Task.map" <|
                \() ->
                    Task.succeed 1
                        |> Task.map toString
                        |> Test.Task.resolvedTask
                        |> Expect.equal (Just (Ok "1"))
            , test "works with Task.onError" <|
                \() ->
                    Task.fail 1
                        |> Task.onError (toString >> Task.succeed)
                        |> Test.Task.resolvedTask
                        |> Expect.equal (Just (Ok "1"))
            , test "works with nested Task.andThen" <|
                \() ->
                    Task.succeed 1
                        |> Task.andThen (\x -> Task.succeed (x + 1))
                        |> Task.andThen (\x -> Task.fail (x + 1))
                        |> Test.Task.resolvedTask
                        |> Expect.equal (Just (Err 3))
            ]
        ]
