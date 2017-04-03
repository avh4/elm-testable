module HttpTests exposing (..)

import Test exposing (..)
import Expect exposing (Expectation)
import Html
import TestContext exposing (TestContext)
import Http


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


all : Test
all =
    describe "Http"
        [ test "verifying an initial HTTP request" <|
            \() ->
                loadingProgram
                    |> TestContext.expectHttpRequest "GET" "https://example.com/books"
        , test "verifying an unmade request gives an error" <|
            \() ->
                loadingProgram
                    |> TestContext.expectHttpRequest "GET" "https://example.com/wrong_url"
                    |> Expect.getFailure
                    |> Expect.equal
                        (Just
                            { given = ""
                            , message = "pending HTTP requests:\n    - GET https://example.com/books\n╷\n│ to include (TestContext.expectHttpRequest)\n╵\nGET https://example.com/wrong_url"
                            }
                        )
        , test "stubbing an HTTP response" <|
            \() ->
                loadingProgram
                    |> TestContext.resolveHttpRequest "GET"
                        "https://example.com/books"
                        "BOOKS1"
                    |> Result.map (TestContext.model)
                    |> Expect.equal (Ok "BOOKS1")

        -- TODO: test an HTTP request with a JSON decoder
        ]
