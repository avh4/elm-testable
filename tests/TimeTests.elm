module TimeTests exposing (all)

import Test exposing (..)
import Expect
import Html
import Process
import TestContext exposing (TestContext)
import Task
import Time exposing (Time)


type SleepProgramMsg
    = Sleep Time String
    | Wake String


sleepProgram : List ( Time, String ) -> TestContext String SleepProgramMsg
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
    , subscriptions = \_ -> Sub.none
    , view = \_ -> Html.text ""
    }
        |> Html.program
        |> TestContext.start


all : Test
all =
    describe "Time"
        [ describe "Process.sleep"
            [ test "does not trigger before the given delay" <|
                \() ->
                    sleepProgram [ ( 5 * Time.second, "AWOKE" ) ]
                        |> TestContext.advanceTime (4.999 * Time.second)
                        |> TestContext.model
                        |> Expect.equal "INIT"
            , test "triggers when the given delay has elapsed" <|
                \() ->
                    sleepProgram [ ( 5 * Time.second, "AWOKE" ) ]
                        |> TestContext.advanceTime (5 * Time.second)
                        |> TestContext.model
                        |> Expect.equal "INIT;AWOKE"
            , test "current time is remembered" <|
                \() ->
                    sleepProgram [ ( 5 * Time.second, "AWOKE" ) ]
                        |> TestContext.advanceTime (3 * Time.second)
                        |> TestContext.advanceTime (2 * Time.second)
                        |> TestContext.model
                        |> Expect.equal "INIT;AWOKE"
            , test "task is scheduled relative to the current time" <|
                \() ->
                    sleepProgram []
                        |> TestContext.advanceTime (2 * Time.second)
                        |> TestContext.update (Sleep (1 * Time.second) "WAKE")
                        |> TestContext.advanceTime (0.999 * Time.second)
                        |> TestContext.model
                        |> Expect.equal "INIT"
            , test "tasks are only triggered once" <|
                \() ->
                    sleepProgram [ ( 5 * Time.second, "AWOKE" ) ]
                        |> TestContext.advanceTime (5 * Time.second)
                        |> TestContext.advanceTime (5 * Time.second)
                        |> TestContext.model
                        |> Expect.equal "INIT;AWOKE"
            , test "triggers all tasks up to now" <|
                \() ->
                    sleepProgram
                        [ ( 5 * Time.second, "5" )
                        , ( 3 * Time.second, "3" )
                        ]
                        |> TestContext.advanceTime (5 * Time.second)
                        |> TestContext.model
                        |> Expect.equal "INIT;3;5"
            ]
        ]
