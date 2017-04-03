module TimeTests exposing (all)

import Test exposing (..)
import Expect
import Html
import Process
import TestContext exposing (TestContext)
import Task
import Time exposing (Time)


sleepProgram : Time -> String -> TestContext String String
sleepProgram delay msg =
    { init =
        ( "INIT"
        , Process.sleep delay
            |> Task.perform (always msg)
        )
    , update = \msg _ -> ( msg, Cmd.none )
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
                    sleepProgram (5 * Time.second) "AWOKE"
                        |> TestContext.advanceTime (4.999 * Time.second)
                        |> TestContext.model
                        |> Expect.equal "INIT"
            , test "triggers when the given delay has elapsed" <|
                \() ->
                    sleepProgram (5 * Time.second) "AWOKE"
                        |> TestContext.advanceTime (5 * Time.second)
                        |> TestContext.model
                        |> Expect.equal "AWOKE"
            ]
        ]
