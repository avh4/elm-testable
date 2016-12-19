module HttpTests exposing (..)

import Test exposing (..)
import Html
import TestContext exposing (TestContext)
import Http


type LoadingMsg
    = NewData (Result Http.Error String)


loadingProgram : TestContext (Maybe String) LoadingMsg
loadingProgram =
    { init =
        ( Nothing
        , Http.getString "https://example.com/books"
            |> Http.send NewData
        )
    , update =
        \msg model ->
            case msg of
                NewData (Ok data) ->
                    ( Just data, Cmd.none )

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
        [ test "verifying that an Http request was made" <|
            \() ->
                loadingProgram
                    |> TestContext.expectHttpRequest "GET" "https://example.com/books"
        ]
