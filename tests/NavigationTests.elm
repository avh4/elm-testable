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


initWithStringFlags : String -> Navigation.Location -> ( Model, Cmd Msg )
initWithStringFlags flags location =
    init location


programUpdate : Msg -> Model -> ( Model, Cmd Msg )
programUpdate msg model =
    case msg of
        UrlChange location ->
            ( { model | location = location, msgs = msg :: model.msgs }, Navigation.modifyUrl location.pathname )

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


sampleProgramWithFlags : TestContext Model Msg
sampleProgramWithFlags =
    Navigation.programWithFlags UrlChange
        { init = initWithStringFlags
        , update = programUpdate
        , subscriptions = \_ -> Sub.none
        , view = always <| div [] []
        }
        |> TestContext.startWithFlags "foo"


all : Test
all =
    describe "Navigation TestContext"
        [ test "starting a navigation program" <|
            \() ->
                sampleProgram
                    |> expectHref "https://elm.testable/"
        , test "pushUrl" <|
            \() ->
                sampleProgram
                    |> update (PushUrl "/foo")
                    |> expectHref "https://elm.testable/foo"
        , test "modifyUrl" <|
            \() ->
                sampleProgram
                    |> update (ModifyUrl "/foo")
                    |> expectHref "https://elm.testable/foo"
        , test "back" <|
            \() ->
                sampleProgram
                    |> update (PushUrl "/foo")
                    |> update (PushUrl "/bar")
                    |> update (Back 1)
                    |> expectHref "https://elm.testable/foo"
        , test "forward" <|
            \() ->
                sampleProgram
                    |> update (PushUrl "/bar")
                    |> update (PushUrl "/baz")
                    |> update (Back 2)
                    |> update (Forward 1)
                    |> expectHref "https://elm.testable/bar"
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
            , test "erases forward history" <|
                \() ->
                    sampleProgram
                        |> navigate "/foo"
                        |> update (Back 1)
                        |> navigate "/baz"
                        |> update (Back 100)
                        |> update (Forward 1)
                        |> expectHref "https://elm.testable/baz"
            ]
        , test "works on program with flags" <|
            \() ->
                sampleProgramWithFlags
                    |> navigate "/foo"
                    |> expectHref "https://elm.testable/foo"
        ]


expectHref : String -> TestContext Model msg -> Expect.Expectation
expectHref href =
    TestContext.expectModel (.location >> .href >> Expect.equal href)
