module Test.HttpTests exposing (..)

import Expect exposing (Expectation)
import Http
import Json.Decode
import Random
import Task
import Test exposing (..)
import Test.Http
import Test.Task
import Time


type Msg a
    = Msg a


decoderA : Json.Decode.Decoder ( Int, String )
decoderA =
    Json.Decode.map2 (,)
        (Json.Decode.field "a" Json.Decode.int)
        (Json.Decode.field "b" Json.Decode.string)


all : Test
all =
    describe "Test.Http"
        [ describe "Test.Http.Result" <|
            let
                resultTest name check =
                    describe name
                        [ test "(fromTask)" <|
                            \() ->
                                check
                                    (Http.toTask
                                        >> Test.Http.fromTask
                                        >> orCrash
                                        >> Test.Http.map (Test.Task.resolvedTask >> orCrash)
                                    )
                        , test "(fromCmd)" <|
                            \() ->
                                check
                                    (Http.send identity
                                        >> Test.Http.fromCmd
                                        >> List.head
                                        >> orCrash
                                    )
                        ]
            in
            [ resultTest ".url" <|
                \toRequest ->
                    Http.getString "https://example.com/kumquats"
                        |> toRequest
                        |> .url
                        |> Expect.equal "https://example.com/kumquats"
            , resultTest ".method" <|
                \toRequest ->
                    Http.getString "https://example.com/kumquats"
                        |> toRequest
                        |> .method
                        |> Expect.equal "GET"
            , resultTest "decoding JSON body" <|
                \toRequest ->
                    Http.get "https://example.com/kumquats" decoderA
                        |> toRequest
                        |> .callback
                        |> (|>) (Ok """{"a":1,"b":"x"}""")
                        |> Expect.equal (Ok ( 1, "x" ))
            , resultTest ".headers" <|
                \toRequest ->
                    Http.request
                        { method = "PUT"
                        , headers =
                            [ Http.header "If-Modified-Since" "Sat 29 Oct 1994 19:43:31 GMT"
                            , Http.header "Max-Forwards" "10"
                            , Http.header "X-Requested-With" "XMLHttpRequest"
                            ]
                        , url = "https://example.com/kumquats"
                        , body = Http.emptyBody
                        , expect = Http.expectString
                        , timeout = Nothing
                        , withCredentials = False
                        }
                        |> toRequest
                        |> .headers
                        |> Expect.equal
                            [ ( "If-Modified-Since", "Sat 29 Oct 1994 19:43:31 GMT" )
                            , ( "Max-Forwards", "10" )
                            , ( "X-Requested-With", "XMLHttpRequest" )
                            ]
            , resultTest ".body (empty body)" <|
                \toRequest ->
                    Http.post "https://example.com/kumquats" Http.emptyBody (Json.Decode.fail "")
                        |> toRequest
                        |> .body
                        |> Expect.equal ""
            , resultTest ".body (string body)" <|
                \toRequest ->
                    Http.post "https://example.com/kumquats" (Http.stringBody "text/plain" "XYZ") (Json.Decode.fail "")
                        |> toRequest
                        |> .body
                        |> Expect.equal "XYZ"

            -- TODO: Content-Type header
            -- TODO: multipart bodies
            ]
        , describe "fromTask"
            [ test "we can get the request from an Http Task" <|
                \() ->
                    Http.getString "https://example.com/kumquats"
                        |> Http.toTask
                        |> Test.Http.fromTask
                        |> expectIsJust
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
                        |> expectIsJust
            , test "works with Task.onError" <|
                \() ->
                    Http.getString "https://example.com/kumquats"
                        |> Http.toTask
                        |> Task.onError Task.fail
                        |> Test.Http.fromTask
                        |> expectIsJust
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
        , describe "send"
            [ test "we can get the request from an Http Cmd" <|
                \() ->
                    Http.getString "https://example.com/kumquats"
                        |> Http.send Msg
                        |> Test.Http.fromCmd
                        |> List.head
                        |> expectIsJust
            , test "for Cmd.none, returns Nothing" <|
                \() ->
                    Cmd.none
                        |> Test.Http.fromCmd
                        |> Expect.equal []
            , test "for non-Http Cmds, returns Nothing" <|
                \() ->
                    Random.generate identity Random.bool
                        |> Test.Http.fromCmd
                        |> Expect.equal []
            , test "works with Cmd.batch" <|
                \() ->
                    Cmd.batch
                        [ Http.send Msg (Http.getString "https://example.com/kumquats")
                        ]
                        |> Test.Http.fromCmd
                        |> List.map .url
                        |> Expect.equal [ "https://example.com/kumquats" ]
            , test "works with Cmd.batch (returns all pending requests)" <|
                \() ->
                    Cmd.batch
                        [ Http.send Msg (Http.getString "https://example.com/kumquats")
                        , Cmd.batch
                            [ Http.send Msg (Http.getString "https://example.com/kumquats")
                            , Http.send Msg (Http.getString "https://example.com/cucumbers")
                            ]
                        ]
                        |> Test.Http.fromCmd
                        |> List.map .url
                        |> Expect.equal
                            [ "https://example.com/kumquats"
                            , "https://example.com/kumquats"
                            , "https://example.com/cucumbers"
                            ]
            , test "works with Cmd.map" <|
                \() ->
                    Http.getString "https://example.com/kumquats"
                        |> Http.send Msg
                        |> Cmd.map List.singleton
                        |> Test.Http.fromCmd
                        |> List.map .url
                        |> Expect.equal [ "https://example.com/kumquats" ]
            , test "simulate a successful response" <|
                \() ->
                    Http.getString "https://example.com/kumquats"
                        |> Http.send Msg
                        |> Test.Http.fromCmd
                        |> List.map (\task -> task.callback (Ok "several kumquats"))
                        |> Expect.equal [ Msg (Ok "several kumquats") ]
            , test "simulate an error response" <|
                \() ->
                    Http.getString "https://example.com/kumquats"
                        |> Http.send Msg
                        |> Test.Http.fromCmd
                        |> List.map (\task -> task.callback (Err Http.NetworkError))
                        |> Expect.equal [ Msg (Err Http.NetworkError) ]
            , test "simulating a response works with Cmd.map" <|
                \() ->
                    Http.getString "https://example.com/kumquats"
                        |> Http.send Msg
                        |> Cmd.map List.singleton
                        |> Test.Http.fromCmd
                        |> List.map (\task -> task.callback (Ok "several kumquats"))
                        |> Expect.equal [ [ Msg (Ok "several kumquats") ] ]

            -- TODO: what happens using Task.perform with a Task that is a chain of Http tasks?
            ]
        ]


orCrash : Maybe a -> a
orCrash maybe =
    case maybe of
        Just a ->
            a

        Nothing ->
            Debug.crash "Expected Just a, but got Nothing"


expectIsJust : Maybe a -> Expectation
expectIsJust maybe =
    case maybe of
        Just _ ->
            Expect.pass

        Nothing ->
            Expect.fail "Expected Just a, but got Nothing"
