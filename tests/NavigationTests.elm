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
    | Load String
    | Reload


type alias Model =
    { location : Navigation.Location, flags : String }


init : String -> Navigation.Location -> ( Model, Cmd Msg )
init flags location =
    ( { location = location, flags = flags }, Cmd.none )


initWithStringFlags : String -> Navigation.Location -> ( Model, Cmd Msg )
initWithStringFlags flags location =
    init flags location


programUpdate : Msg -> Model -> ( Model, Cmd Msg )
programUpdate msg model =
    case msg of
        UrlChange location ->
            ( { model | location = location }, Navigation.modifyUrl location.pathname )

        PushUrl url ->
            ( model, Navigation.newUrl url )

        ModifyUrl url ->
            ( model, Navigation.modifyUrl url )

        Back amount ->
            ( model, Navigation.back amount )

        Forward amount ->
            ( model, Navigation.forward amount )

        Load url ->
            ( model, Navigation.load url )

        Reload ->
            ( model, Navigation.reload )


sampleProgram : TestContext Model Msg
sampleProgram =
    Navigation.program UrlChange
        { init = init ""
        , update = programUpdate
        , subscriptions = \_ -> Sub.none
        , view = always <| div [] []
        }
        |> TestContext.start


sampleProgramWithFlags : String -> TestContext Model Msg
sampleProgramWithFlags flags =
    Navigation.programWithFlags UrlChange
        { init = initWithStringFlags
        , update = programUpdate
        , subscriptions = \_ -> Sub.none
        , view = always <| div [] []
        }
        |> TestContext.startWithFlags flags


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
        , test "load" <|
            \() ->
                sampleProgram
                    |> update (Load "/foo")
                    |> expectHref "https://elm.testable/foo"
        , test "refresh does nothing" <|
            \() ->
                sampleProgram
                    |> update Reload
                    |> done
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
                sampleProgramWithFlags "something"
                    |> navigate "/foo"
                    |> expectHref "https://elm.testable/foo"
        , test "flags are used" <|
            \() ->
                sampleProgramWithFlags "barbaz"
                    |> expectModel
                        (\model ->
                            Expect.equal "barbaz" model.flags
                        )
        ]


expectHref : String -> TestContext Model msg -> Expect.Expectation
expectHref href =
    TestContext.expectModel (.location >> .href >> Expect.equal href)
