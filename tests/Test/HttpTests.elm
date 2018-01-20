module Test.HttpTests exposing (..)

import Expect
import Http
import Task
import Test exposing (..)
import Test.Http
import Test.Task
import Time


all : Test
all =
    describe "Test.Http"
        [ describe "fromTask"
            [ test "we can get the URL from an Http Task" <|
                \() ->
                    Http.getString "https://example.com/kumquats"
                        |> Http.toTask
                        |> Test.Http.fromTask
                        |> Maybe.map .url
                        |> Expect.equal (Just "https://example.com/kumquats")
            , test "for non-Http tasks (without elmTestable field), returns Nothing" <|
                \() ->
                    Task.succeed ()
                        |> Test.Http.fromTask
                        |> Expect.equal Nothing
            , test "for non-Http tasks, returns Nothing" <|
                \() ->
                    Time.now
                        |> Test.Http.fromTask
                        |> Expect.equal Nothing
            , test "works with Task.map" <|
                \() ->
                    Http.getString "https://example.com/kumquats"
                        |> Http.toTask
                        |> Task.map toString
                        |> Test.Http.fromTask
                        |> Maybe.map .url
                        |> Expect.equal (Just "https://example.com/kumquats")
            , test "works with Task.map (to a different type)" <|
                \() ->
                    Http.getString "https://example.com/kumquats"
                        |> Http.toTask
                        |> Task.map List.singleton
                        |> Test.Http.fromTask
                        |> Maybe.map .url
                        |> Expect.equal (Just "https://example.com/kumquats")
            , test "works with Task.onError" <|
                \() ->
                    Http.getString "https://example.com/kumquats"
                        |> Http.toTask
                        |> Task.onError Task.fail
                        |> Test.Http.fromTask
                        |> Maybe.map .url
                        |> Expect.equal (Just "https://example.com/kumquats")
            , test "gets the request method" <|
                \() ->
                    Http.getString "https://example.com/kumquats"
                        |> Http.toTask
                        |> Test.Http.fromTask
                        |> Maybe.map .method
                        |> Expect.equal (Just "GET")
            , test "simulate a successful response" <|
                \() ->
                    Http.getString "https://example.com/kumquats"
                        |> Http.toTask
                        |> Test.Http.fromTask
                        |> Maybe.map (\task -> task.callback (Ok "several kumquats"))
                        |> Maybe.andThen Test.Task.resolvedTask
                        |> Expect.equal (Just (Ok "several kumquats"))
            , test "simulated response works with Task.andThen" <|
                \() ->
                    Http.getString "https://example.com/kumquats"
                        |> Http.toTask
                        |> Task.map List.singleton
                        |> Test.Http.fromTask
                        |> Maybe.map (\task -> task.callback (Ok "several kumquats"))
                        |> Maybe.andThen Test.Task.resolvedTask
                        |> Expect.equal (Just (Ok [ "several kumquats" ]))
            , test "simulate an error response" <|
                \() ->
                    Http.getString "https://example.com/kumquats"
                        |> Http.toTask
                        |> Test.Http.fromTask
                        |> Maybe.map (\task -> task.callback (Err Http.NetworkError))
                        |> Maybe.andThen Test.Task.resolvedTask
                        |> Expect.equal (Just (Err Http.NetworkError))
            , test "simulated response works with Task.onError" <|
                \() ->
                    Http.getString "https://example.com/kumquats"
                        |> Http.toTask
                        |> Task.onError (List.singleton >> Task.fail)
                        |> Test.Http.fromTask
                        |> Maybe.map (\task -> task.callback (Err Http.NetworkError))
                        |> Maybe.andThen Test.Task.resolvedTask
                        |> Expect.equal (Just (Err [ Http.NetworkError ]))
            , test "simulated response works with nested Task.andThen" <|
                \() ->
                    Http.getString "https://example.com/kumquats"
                        |> Http.toTask
                        |> Task.andThen ((++) "1" >> Task.succeed)
                        |> Task.andThen ((++) "2" >> Task.succeed)
                        |> Test.Http.fromTask
                        |> Maybe.map (\task -> task.callback (Ok "A"))
                        |> Maybe.andThen Test.Task.resolvedTask
                        |> Expect.equal (Just (Ok "21A"))
            , test "simulated response works with nested Task.onError" <|
                \() ->
                    Http.getString "https://example.com/kumquats"
                        |> Http.toTask
                        |> Task.onError (toString >> Task.fail)
                        |> Task.onError ((++) "1" >> Task.fail)
                        |> Task.onError ((++) "2" >> Task.fail)
                        |> Test.Http.fromTask
                        |> Maybe.map (\task -> task.callback (Err Http.NetworkError))
                        |> Maybe.andThen Test.Task.resolvedTask
                        |> Expect.equal (Just (Err "21NetworkError"))
            , test "simulated response works with nested Task transformations" <|
                \() ->
                    Http.getString "https://example.com/kumquats"
                        |> Http.toTask
                        |> Task.onError (toString >> Task.succeed)
                        |> Task.andThen ((++) "1" >> Task.succeed)
                        |> Task.andThen ((++) "2" >> Task.fail)
                        |> Task.onError ((++) "3" >> Task.succeed)
                        |> Test.Http.fromTask
                        |> Maybe.map (\task -> task.callback (Ok "A"))
                        |> Maybe.map Test.Task.resolvedTask
                        |> Expect.equal (Just <| Just (Ok "321A"))

            -- TODO: what to do with Process.spawn? :frog:
            ]
        ]
