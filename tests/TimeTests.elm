module TimeTests exposing (all)

import Test exposing (..)
import Expect
import Html
import Process
import TestContext exposing (TestContext, SingleQuery)
import Task
import Time exposing (Time)


type SleepProgramMsg
    = Sleep Time String
    | Wake String
    | Custom (List (Cmd String))


sleepProgram : List ( Time, String ) -> TestContext SingleQuery String SleepProgramMsg
sleepProgram initSleeps =
    { init =
        ( "INIT"
        , initSleeps
            |> List.map
                (\( delay, msg ) ->
                    Process.sleep delay
                        |> Task.perform (always <| Wake msg)
                )
            |> Cmd.batch
        )
    , update =
        \msg model ->
            case msg of
                Sleep time m ->
                    ( model
                    , Process.sleep time
                        |> Task.perform (always <| Wake m)
                    )

                Wake m ->
                    ( model ++ ";" ++ m, Cmd.none )

                Custom cmds ->
                    ( model, Cmd.batch cmds |> Cmd.map Wake )
    , subscriptions = \_ -> Sub.none
    , view = \_ -> Html.text ""
    }
        |> Html.program
        |> TestContext.start


nowProgram : TestContext SingleQuery String Time
nowProgram =
    { init =
        ( "INIT"
        , Cmd.batch
            [ Time.now |> Task.perform identity
            , Process.sleep (sec 3)
                |> Task.andThen (always Time.now)
                |> Task.perform identity
            ]
        )
    , update =
        \msg model -> ( model ++ ";" ++ toString msg, Cmd.none )
    , subscriptions = \_ -> Sub.none
    , view = \_ -> Html.text ""
    }
        |> Html.program
        |> TestContext.start


everyProgram : Program Never String Time
everyProgram =
    { init = ( "INIT", Cmd.none )
    , update =
        \msg model -> ( model ++ ";" ++ toString msg, Cmd.none )
    , subscriptions =
        \_ -> Time.every (sec 1) identity
    , view = \_ -> Html.text ""
    }
        |> Html.program


onceProgram : Program Never (List Time) Time
onceProgram =
    { init = ( [], Cmd.none )
    , update =
        \msg model -> ( msg :: model, Cmd.none )
    , subscriptions =
        \model ->
            case model of
                [] ->
                    Time.every (sec 1) identity

                _ ->
                    Sub.none
    , view = \_ -> Html.text ""
    }
        |> Html.program


sec : Float -> Time
sec =
    (*) Time.second


all : Test
all =
    describe "simulating time"
        [ describe "Process.sleep"
            [ test "does not trigger before the given delay" <|
                \() ->
                    sleepProgram [ ( sec 5, "AWOKE" ) ]
                        |> TestContext.advanceTime (sec 4.999)
                        |> TestContext.expectModel
                            (Expect.equal "INIT")
            , test "triggers when the given delay has elapsed" <|
                \() ->
                    sleepProgram [ ( sec 5, "AWOKE" ) ]
                        |> TestContext.advanceTime (sec 5)
                        |> TestContext.expectModel
                            (Expect.equal "INIT;AWOKE")
            , test "current time is remembered" <|
                \() ->
                    sleepProgram [ ( sec 5, "AWOKE" ) ]
                        |> TestContext.advanceTime (sec 3)
                        |> TestContext.advanceTime (sec 2)
                        |> TestContext.expectModel
                            (Expect.equal "INIT;AWOKE")
            , test "task is scheduled relative to the current time" <|
                \() ->
                    sleepProgram []
                        |> TestContext.advanceTime (sec 2)
                        |> TestContext.update (Sleep (sec 1) "WAKE")
                        |> TestContext.advanceTime (sec 0.999)
                        |> TestContext.expectModel
                            (Expect.equal "INIT")
            , test "tasks are only triggered once" <|
                \() ->
                    sleepProgram [ ( sec 5, "AWOKE" ) ]
                        |> TestContext.advanceTime (sec 5)
                        |> TestContext.advanceTime (sec 5)
                        |> TestContext.expectModel
                            (Expect.equal "INIT;AWOKE")
            , test "triggers all tasks up to now" <|
                \() ->
                    sleepProgram
                        [ ( sec 5, "5" )
                        , ( sec 3, "3" )
                        ]
                        |> TestContext.advanceTime (sec 5)
                        |> TestContext.expectModel
                            (Expect.equal "INIT;3;5")
            , test "task is scheduled from when it starts, not from whe it's created" <|
                \() ->
                    sleepProgram []
                        |> TestContext.update
                            (Custom
                                [ Process.sleep (sec 3)
                                    |> Task.andThen (\_ -> Process.sleep (sec 3))
                                    |> Task.perform (\_ -> "AFTER 6")
                                , Process.sleep (sec 5)
                                    |> Task.perform (\_ -> "AFTER 5")
                                ]
                            )
                        |> TestContext.advanceTime (sec 5)
                        |> TestContext.expectModel
                            (Expect.equal "INIT;AFTER 5")
            ]
        , describe "Time.now"
            [ test "initially 0" <|
                \() ->
                    nowProgram
                        |> TestContext.expectModel
                            (Expect.equal "INIT;0")
            , test "tracks current time" <|
                \() ->
                    nowProgram
                        |> TestContext.advanceTime (sec 5)
                        |> TestContext.expectModel
                            (Expect.equal "INIT;0;3000")
            ]
        , describe "Time.every"
            [ test "triggers after initial delay" <|
                \() ->
                    everyProgram
                        |> TestContext.start
                        |> TestContext.advanceTime (sec 1)
                        |> TestContext.expectModel
                            (Expect.equal "INIT;1000")
            , test "triggers again after the first time" <|
                \() ->
                    everyProgram
                        |> TestContext.start
                        |> TestContext.advanceTime (sec 2)
                        |> TestContext.expectModel
                            (Expect.equal "INIT;1000;2000")
            , test "can be unsubscribed" <|
                \() ->
                    onceProgram
                        |> TestContext.start
                        |> TestContext.advanceTime (sec 2)
                        |> TestContext.expectModel
                            (Expect.equal [ 1000 ])
            ]
        ]
