module HttpTests exposing (..)

import Expect exposing (Expectation)
import Html
import Http
import Json.Decode as Decode
import Test exposing (..)
import Test.Util exposing (..)
import TestContext exposing (TestContext)
import TestContext.Http


type LoadingMsg
    = NewData (Result Http.Error String)


loadingProgram : TestContext String LoadingMsg
loadingProgram =
    { init =
        ( "INIT"
        , Http.getString "https://example.com/books"
            |> Http.send NewData
        )
    , update =
        \msg model ->
            case msg of
                NewData (Ok data) ->
                    ( model ++ ";" ++ data, Cmd.none )

                NewData (Err (Http.BadStatus { status })) ->
                    ( model ++ ";BadStatus " ++ toString status.code, Cmd.none )

                NewData (Err error) ->
                    ( model ++ ";" ++ toString error, Cmd.none )
    , subscriptions = \_ -> Sub.none
    , view = toString >> Html.text
    }
        |> Html.program
        |> TestContext.start


type JsonMsg
    = NewList (Result Http.Error (List String))


jsonProgram : TestContext String JsonMsg
jsonProgram =
    { init =
        ( "INIT"
        , Http.get "https://example.com/books" (Decode.list Decode.string)
            |> Http.send NewList
        )
    , update =
        \msg model ->
            case msg of
                NewList (Ok data) ->
                    ( model ++ ";" ++ String.join "," data, Cmd.none )

                NewList (Err (Http.BadStatus { status })) ->
                    ( model ++ ";BadStatus " ++ toString status.code, Cmd.none )

                NewList (Err (Http.BadPayload message _)) ->
                    ( model ++ ";BadPayload " ++ toString message, Cmd.none )

                NewList (Err error) ->
                    ( model ++ ";" ++ toString error, Cmd.none )
    , subscriptions = \_ -> Sub.none
    , view = toString >> Html.text
    }
        |> Html.program
        |> TestContext.start


expectOk : (a -> Expectation) -> Result x a -> Expectation
expectOk check result =
    case result of
        Ok a ->
            check a

        Err _ ->
            Expect.fail ("Expected (Ok _), but got: " ++ toString result)


all : Test
all =
    describe "Http"
        [ test "verifying an initial HTTP request" <|
            \() ->
                loadingProgram
                    |> TestContext.Http.expectGet "https://example.com/books"
        , test "verifying an unmade request gives an error" <|
            \() ->
                loadingProgram
                    |> TestContext.Http.expectGet "https://example.com/wrong_url"
                    |> expectFailure
                        [ "pending HTTP requests:"
                        , "    - GET https://example.com/books"
                        , "╷"
                        , "│ to include (TestContext.Http.expectRequest)"
                        , "╵"
                        , "GET https://example.com/wrong_url"
                        ]
        , test "stubbing an HTTP response" <|
            \() ->
                loadingProgram
                    |> TestContext.Http.resolveGet
                        "https://example.com/books"
                        "BOOKS1"
                    |> TestContext.expectModel
                        (Expect.equal "INIT;BOOKS1")
        , test "stubbing an HTTP error" <|
            \() ->
                loadingProgram
                    |> TestContext.Http.rejectGet
                        "https://example.com/books"
                        (TestContext.Http.badStatus 404)
                    |> TestContext.expectModel
                        (Expect.equal "INIT;BadStatus 404")
        , test "requests should be removed after they are resolve" <|
            \() ->
                loadingProgram
                    |> TestContext.Http.resolveGet
                        "https://example.com/books"
                        "BOOKS1"
                    |> TestContext.Http.expectGet "https://example.com/books"
                    |> expectFailure
                        [ "pending HTTP requests (none were made)"
                        , "╷"
                        , "│ to include (TestContext.Http.expectRequest)"
                        , "╵"
                        , "GET https://example.com/books"
                        ]
        , test "decodes JSON" <|
            \() ->
                jsonProgram
                    |> TestContext.Http.resolveGet
                        "https://example.com/books"
                        """["a","b","c"]"""
                    |> TestContext.expectModel
                        (Expect.equal "INIT;a,b,c")
        , test "fails with BadPayload when the JSON fails to parse" <|
            \() ->
                jsonProgram
                    |> TestContext.Http.resolveGet
                        "https://example.com/books"
                        """@#not JSON"""
                    |> TestContext.expectModel
                        (expectContains "INIT;BadPayload \"Given an invalid JSON: Unexpected token @")

        -- TODO: nicer message when an expected request was previously resolved
        -- TODO: required body (for POST request)
        -- TODO: disallow 3xx codes in response, since Http uses XHR, which silently follows redirects
        -- TODO: verify/match HTTP headers
        -- TODO: give headers for stubbed response
        -- TODO: support Http.Progress
        -- TODO: Do we need expectHttpRequest? won't resolveHttpRequest be enough?
        -- TODO: give custom URL in response (this would happen in real life if there are redirects)
        -- TODO: handle timeouts
        -- TODO: what is Http.Request.withCredentials for?
        ]
