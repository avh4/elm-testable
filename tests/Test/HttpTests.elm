module Test.HttpTests exposing (..)

import Expect
import Http
import Task
import Test exposing (..)
import Test.Http
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

            -- TODO: mapping to a different type when simulating repsonses
            -- TODO: onError to a different type?
            -- TODO: what to do with Process.spawn? :frog:
            ]
        ]
