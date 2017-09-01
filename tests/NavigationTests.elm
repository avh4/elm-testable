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


sampleProgram : Program Never Model Msg
sampleProgram =
    Navigation.program UrlChange
        { init = init ""
        , update = programUpdate
        , subscriptions = \_ -> Sub.none
        , view = always <| div [] []
        }


startSampleProgram : TestContext Model Msg
startSampleProgram =
    sampleProgram
        |> TestContext.startWithLocation "https://mywebsite.com/"


sampleProgramWithFlags : Program String Model Msg
sampleProgramWithFlags =
    Navigation.programWithFlags UrlChange
        { init = initWithStringFlags
        , update = programUpdate
        , subscriptions = \_ -> Sub.none
        , view = always <| div [] []
        }


startSampleProgramWithFlags : String -> TestContext Model Msg
startSampleProgramWithFlags flags =
    sampleProgramWithFlags
        |> TestContext.startWithFlagsAndLocation flags "https://mywebsite.com/"


all : Test
all =
    describe "Navigation TestContext"
        [ test "starting a navigation program" <|
            \() ->
                startSampleProgram
                    |> expectHref "https://mywebsite.com/"
        , test "pushUrl" <|
            \() ->
                startSampleProgram
                    |> update (PushUrl "/foo")
                    |> expectHref "https://mywebsite.com/foo"
        , test "modifyUrl" <|
            \() ->
                startSampleProgram
                    |> update (ModifyUrl "/foo")
                    |> expectHref "https://mywebsite.com/foo"
        , test "back" <|
            \() ->
                startSampleProgram
                    |> update (PushUrl "/foo")
                    |> update (PushUrl "/bar")
                    |> update (Back 1)
                    |> expectHref "https://mywebsite.com/foo"
        , test "forward" <|
            \() ->
                startSampleProgram
                    |> update (PushUrl "/bar")
                    |> update (PushUrl "/baz")
                    |> update (Back 2)
                    |> update (Forward 1)
                    |> expectHref "https://mywebsite.com/bar"
        , test "load" <|
            \() ->
                startSampleProgram
                    |> update (Load "/foo")
                    |> expectHref "https://mywebsite.com/foo"
        , test "refresh does nothing" <|
            \() ->
                startSampleProgram
                    |> update Reload
                    |> done
        , describe "navigation simulation"
            [ test "simulates navigation for testing" <|
                \() ->
                    startSampleProgram
                        |> navigate "/qux"
                        |> expectHref "https://mywebsite.com/qux"
            , test "allows to go back" <|
                \() ->
                    startSampleProgram
                        |> navigate "/foo"
                        |> navigate "/bar"
                        |> back
                        |> expectHref "https://mywebsite.com/foo"
            , test "erases forward history" <|
                \() ->
                    startSampleProgram
                        |> navigate "/foo"
                        |> back
                        |> navigate "/baz"
                        |> back
                        |> back
                        |> back
                        |> forward
                        |> expectHref "https://mywebsite.com/baz"
            ]
        , test "works on program with flags" <|
            \() ->
                startSampleProgramWithFlags "something"
                    |> navigate "/foo"
                    |> expectHref "https://mywebsite.com/foo"
        , test "flags are used" <|
            \() ->
                startSampleProgramWithFlags "barbaz"
                    |> expectModel
                        (\model ->
                            Expect.equal "barbaz" model.flags
                        )
        , describe "start a navigation Program without using startWithLocation"
            [ test "has a default url" <|
                \() ->
                    sampleProgram
                        |> TestContext.start
                        |> expectHref "https://elm.testable/"
            , test "has a default url and flags" <|
                \() ->
                    sampleProgramWithFlags
                        |> TestContext.startWithFlags "barbaz"
                        |> Expect.all
                            [ expectHref "https://elm.testable/"
                            , expectModel
                                (\model ->
                                    Expect.equal "barbaz" model.flags
                                )
                            ]
            ]
        ]


expectHref : String -> TestContext Model msg -> Expect.Expectation
expectHref href =
    TestContext.expectModel (.location >> .href >> Expect.equal href)
