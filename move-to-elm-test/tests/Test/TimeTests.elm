module Test.TimeTests exposing (all)

import Expect
import Task
import Test exposing (..)
import Test.Task
import Test.Time
import Time


all : Test
all =
    describe "Test.Time"
        [ test "returns Nothing for non-Time task" <|
            \() ->
                Task.succeed ()
                    |> Test.Time.fromTask
                    |> Expect.equal Nothing
        , test "simulating advancing time" <|
            \() ->
                Time.now
                    |> Test.Time.fromTask
                    |> Maybe.map ((|>) 0)
                    |> Maybe.map Test.Task.resolvedTask
                    |> Expect.equal (Just (Just (Ok 0)))
        , test "works with andThen" <|
            \() ->
                Time.now
                    |> Task.andThen ((+) 1 >> Task.fail)
                    |> Test.Time.fromTask
                    |> Maybe.map ((|>) 0)
                    |> Maybe.map Test.Task.resolvedTask
                    |> Expect.equal (Just (Just (Err 1)))
        , test "works with onError" <|
            \() ->
                Time.now
                    |> Task.onError ((+) 1 >> Task.fail)
                    |> Task.andThen ((+) 10 >> Task.fail)
                    |> Task.onError ((+) 100 >> Task.succeed)
                    |> Test.Time.fromTask
                    |> Maybe.map ((|>) 0)
                    |> Maybe.map Test.Task.resolvedTask
                    |> Expect.equal (Just (Just (Ok 110)))
        ]
