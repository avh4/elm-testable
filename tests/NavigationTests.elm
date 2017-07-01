module NavigationTests exposing (..)

import Expect
import Html exposing (..)
import Navigation
import Test exposing (..)
import TestContext exposing (TestContext)


type Msg
    = UrlChange Navigation.Location
    | PushUrl String
    | ModifyUrl String
    | Back Int


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

        PushUrl url ->
            ( model, Navigation.newUrl url )

        ModifyUrl url ->
            ( model, Navigation.modifyUrl url )

        Back amount ->
            ( model, Navigation.back amount )


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
                    |> TestContext.update (PushUrl "/foo")
                    |> TestContext.expectModel (.location >> .href >> Expect.equal "https://elm.testable/foo")
        , test "modifyUrl" <|
            \() ->
                stringProgram
                    |> TestContext.update (ModifyUrl "/foo")
                    |> TestContext.expectModel (.location >> .href >> Expect.equal "https://elm.testable/foo")
        , describe "back"
            [ test "returns to the previous url when using back" <|
                \() ->
                    stringProgram
                        |> TestContext.update (PushUrl "/foo")
                        |> TestContext.update (PushUrl "/bar")
                        |> TestContext.update (Back 1)
                        |> TestContext.expectModel (.location >> .href >> Expect.equal "https://elm.testable/foo")
            , test "returns two times" <|
                \() ->
                    stringProgram
                        |> TestContext.update (PushUrl "/foo")
                        |> TestContext.update (PushUrl "/bar")
                        |> TestContext.update (PushUrl "/baz")
                        |> TestContext.update (Back 2)
                        |> TestContext.expectModel (.location >> .href >> Expect.equal "https://elm.testable/foo")
            , test "skip modified url" <|
                \() ->
                    stringProgram
                        |> TestContext.update (PushUrl "/foo")
                        |> TestContext.update (PushUrl "/bar")
                        |> TestContext.update (ModifyUrl "/baz")
                        |> TestContext.update (Back 1)
                        |> TestContext.expectModel (.location >> .href >> Expect.equal "https://elm.testable/foo")
            ]
        ]
