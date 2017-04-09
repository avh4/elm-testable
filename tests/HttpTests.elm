module HttpTests exposing (..)

import Expect exposing (Expectation)
import Html
import Http
import Test exposing (..)
import TestContext exposing (TestContext)
import Test.Http
import Test.Util exposing (..)


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
                    ( data, Cmd.none )

                NewData (Err _) ->
                    ( model, Cmd.none )
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
                    |> Test.Http.expectGet "https://example.com/books"
        , test "verifying an unmade request gives an error" <|
            \() ->
                loadingProgram
                    |> Test.Http.expectGet "https://example.com/wrong_url"
                    |> expectFailure
                        [ "pending HTTP requests:"
                        , "    - GET https://example.com/books"
                        , "╷"
                        , "│ to include (Test.Http.expectRequest)"
                        , "╵"
                        , "GET https://example.com/wrong_url"
                        ]
        , test "stubbing an HTTP response" <|
            \() ->
                loadingProgram
                    |> Test.Http.resolveGet
                        "https://example.com/books"
                        "BOOKS1"
                    |> TestContext.expectModel (Expect.equal "BOOKS1")
        , test "requests should be removed after they are resolve" <|
            \() ->
                loadingProgram
                    |> Test.Http.resolveGet
                        "https://example.com/books"
                        "BOOKS1"
                    |> Test.Http.expectGet "https://example.com/books"
                    |> expectFailure
                        [ "pending HTTP requests (none were made)"
                        , "╷"
                        , "│ to include (Test.Http.expectRequest)"
                        , "╵"
                        , "GET https://example.com/books"
                        ]

        -- TODO: nicer message when an expected request was previously resolved
        -- TODO: test an HTTP request with a JSON decoder
        -- TODO: give custom status code in response
        -- TODO: disallow 3xx codes in response, since Http uses XHR, which silently follows redirects
        -- TODO: verify/match HTTP headers
        -- TODO: give headers for stubbed response
        -- TODO: support Http.Progress
        -- TODO: Do we need expectHttpRequest? won't resolveHttpRequest be enough?
        -- TODO: give custom URL in response (this would happen in real life if there are redirects)
        -- TODO: handle timeouts
        -- TODO: what is Http.Request.withCredentials for?
        ]
