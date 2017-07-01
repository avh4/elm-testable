module NavigationTests exposing (..)

import Expect
import Html exposing (..)
import Navigation
import Test exposing (..)
import TestContext exposing (TestContext)


type Msg
    = UrlChange Navigation.Location
    | AskToPushUrl String
    | AskToModifyUrl String


type alias Model =
    { location : Navigation.Location, msgs : List Msg }


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    ( { location = location, msgs = [] }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange location ->
            ( { model | location = location, msgs = msg :: model.msgs }, Cmd.none )

        AskToPushUrl url ->
            ( model, Navigation.newUrl url )

        AskToModifyUrl url ->
            ( model, Navigation.modifyUrl url )


stringProgram : TestContext Model Msg
stringProgram =
    Navigation.program UrlChange
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = always <| div [] []
        }
        |> TestContext.start


all : Test
all =
    describe "Navigation TestContext"
        [ test "starting a navigation program" <|
            \() ->
                stringProgram
                    |> TestContext.expectModel (.location >> .href >> Expect.equal "https://elm.testable/")
        , test "pushUrl" <|
            \() ->
                stringProgram
                    |> TestContext.update (AskToPushUrl "/foo")
                    |> TestContext.expectModel (.location >> .href >> Expect.equal "https://elm.testable/foo")
        , test "modifyUrl" <|
            \() ->
                stringProgram
                    |> TestContext.update (AskToModifyUrl "/foo")
                    |> TestContext.expectModel (.location >> .href >> Expect.equal "https://elm.testable/foo")
        ]
