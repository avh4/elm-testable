module NavigationTests exposing (..)

import Expect
import Html exposing (..)
import Navigation
import Test exposing (..)
import TestContext exposing (..)


type Msg
    = UrlChange Navigation.Location
    | PushUrl String
    | ModifyUrl String
    | Back Int
    | Forward Int


type alias Model =
    { location : Navigation.Location, msgs : List Msg }


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    ( { location = location, msgs = [] }, Cmd.none )


programUpdate : Msg -> Model -> ( Model, Cmd Msg )
programUpdate msg model =
    case msg of
        UrlChange location ->
            ( { model | location = location, msgs = msg :: model.msgs }, Cmd.none )

        PushUrl url ->
            ( model, Navigation.newUrl url )

        ModifyUrl url ->
            ( model, Navigation.modifyUrl url )

        Back amount ->
            ( model, Navigation.back amount )

        Forward amount ->
            ( model, Navigation.forward amount )


sampleProgram : TestContext Model Msg
sampleProgram =
    Navigation.program UrlChange
        { init = init
        , update = programUpdate
        , subscriptions = \_ -> Sub.none
        , view = always <| div [] []
        }
        |> TestContext.start


all : Test
all =
    describe "Navigation TestContext"
        [ test "starting a navigation program" <|
            \() ->
                sampleProgram
                    |> expectHref "https://elm.testable/"
        , describe "pushUrl"
            [ test "goes to a new url" <|
                \() ->
                    sampleProgram
                        |> update (PushUrl "/foo")
                        |> expectHref "https://elm.testable/foo"
            , test "erases forward history" <|
                \() ->
                    sampleProgram
                        |> update (PushUrl "/foo")
                        |> update (Back 1)
                        |> update (PushUrl "/baz")
                        |> update (Back 100)
                        |> update (Forward 1)
                        |> expectHref "https://elm.testable/baz"
            ]
        , describe "modifyUrl"
            [ test "changes current url" <|
                \() ->
                    sampleProgram
                        |> update (ModifyUrl "/foo")
                        |> expectHref "https://elm.testable/foo"
            , test "does not erase forward history" <|
                \() ->
                    sampleProgram
                        |> update (PushUrl "/foo")
                        |> update (PushUrl "/bar")
                        |> update (Back 1)
                        |> update (ModifyUrl "/baz")
                        |> update (Forward 1)
                        |> expectHref "https://elm.testable/bar"
            ]
        , describe "navigation simulation"
            [ test "simulates navigation for testing" <|
                \() ->
                    sampleProgram
                        |> navigate "/qux"
                        |> expectHref "https://elm.testable/qux"
            , test "allows to go back" <|
                \() ->
                    sampleProgram
                        |> navigate "/foo"
                        |> navigate "/bar"
                        |> update (Back 1)
                        |> expectHref "https://elm.testable/foo"
            ]
        , describe "back"
            [ test "returns to the previous url when using back" <|
                \() ->
                    sampleProgram
                        |> update (PushUrl "/foo")
                        |> update (PushUrl "/bar")
                        |> update (Back 1)
                        |> expectHref "https://elm.testable/foo"
            , test "skip modified url" <|
                \() ->
                    sampleProgram
                        |> update (PushUrl "/foo")
                        |> update (PushUrl "/bar")
                        |> update (ModifyUrl "/baz")
                        |> update (Back 1)
                        |> expectHref "https://elm.testable/foo"
            , test "has a limit to go back" <|
                \() ->
                    sampleProgram
                        |> update (Back 100)
                        |> expectHref "https://elm.testable/"
            ]
        , describe "forward"
            [ test "goes to the next page in history using forward" <|
                \() ->
                    sampleProgram
                        |> update (PushUrl "/bar")
                        |> update (PushUrl "/baz")
                        |> update (Back 2)
                        |> update (Forward 1)
                        |> expectHref "https://elm.testable/bar"
            , test "skip modified url" <|
                \() ->
                    sampleProgram
                        |> update (PushUrl "/foo")
                        |> update (PushUrl "/bar")
                        |> update (ModifyUrl "/baz")
                        |> update (Back 2)
                        |> update (Forward 1)
                        |> expectHref "https://elm.testable/foo"
            , test "has a limit to go forward" <|
                \() ->
                    sampleProgram
                        |> update (PushUrl "/foo")
                        |> update (Back 1)
                        |> update (Forward 100)
                        |> expectHref "https://elm.testable/foo"
            ]
        ]


expectHref : String -> TestContext Model msg -> Expect.Expectation
expectHref href =
    TestContext.expectModel (.location >> .href >> Expect.equal href)
