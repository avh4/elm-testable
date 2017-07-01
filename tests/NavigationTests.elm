module NavigationTests exposing (..)

import Expect
import Html exposing (..)
import Navigation
import Test exposing (..)
import TestContext exposing (TestContext)


type Msg
    = UrlChange Navigation.Location
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
    describe "Navigation"
        [ test "starting a navigation program" <|
            \() ->
                stringProgram
                    |> TestContext.expectModel (.location >> .href >> Expect.equal "https://elm.testable/")
        , test "updates the root path" <|
            \() ->
                stringProgram
                    |> TestContext.update (AskToModifyUrl "/foo")
                    |> TestContext.expectModel (.location >> .href >> Expect.equal "https://elm.testable/foo")
        , test "updates to a relative path" <|
            \() ->
                stringProgram
                    |> TestContext.update (AskToModifyUrl "/foo/bar")
                    |> TestContext.update (AskToModifyUrl "baz")
                    |> TestContext.expectModel (.location >> .href >> Expect.equal "https://elm.testable/foo/baz")
        , test "updates the query string" <|
            \() ->
                stringProgram
                    |> TestContext.update (AskToModifyUrl "/foo")
                    |> TestContext.update (AskToModifyUrl "?q=bar")
                    |> TestContext.expectModel (.location >> .href >> Expect.equal "https://elm.testable/foo?q=bar")
        , test "updates the hash" <|
            \() ->
                stringProgram
                    |> TestContext.update (AskToModifyUrl "/foo?bar#baz")
                    |> TestContext.update (AskToModifyUrl "#qux")
                    |> TestContext.expectModel (.location >> .href >> Expect.equal "https://elm.testable/foo?bar#qux")
        , test "updates the whole path" <|
            \() ->
                stringProgram
                    |> TestContext.update (AskToModifyUrl "http://www.google.com")
                    |> TestContext.expectModel (.location >> .href >> Expect.equal "http://www.google.com")
        ]
