module PortCmdTests exposing (..)

import Test exposing (..)
import Expect
import Html
import TestContext exposing (TestContext)
import Test.Ports as Ports
import Task


testEqual : Gen a -> String -> (a -> a -> Expect.Expectation) -> Test
testEqual ( a, b ) name testCase =
    Test.describe name
        [ Test.test "when equal" <|
            \() -> testCase a a
        , Test.test "when not equal" <|
            \() ->
                testCase a b
                    |> Expect.getFailure
                    |> Maybe.map (always True)
                    |> Maybe.withDefault False
                    |> Expect.true ("Expected test case to fail when inputs are different: " ++ toString ( a, b ))
        ]


type alias Gen a =
    ( a, a )


string : Gen String
string =
    ( "Alpha", "Beta" )


all : Test
all =
    describe "port Cmds"
        [ testEqual string "verifying an initial Cmd" <|
            \actual expected ->
                { init = ( (), Ports.string actual )
                , update = \msg _ -> ( msg, Cmd.none )
                , subscriptions = \_ -> Sub.none
                , view = \_ -> Html.text ""
                }
                    |> Html.program
                    |> TestContext.start
                    |> TestContext.expectCmd (Ports.string expected)
        , testEqual string "verifying a Cmd from update" <|
            \actual expected ->
                { init = ( (), Cmd.none )
                , update = \msg _ -> ( msg, Ports.string actual )
                , subscriptions = \_ -> Sub.none
                , view = \_ -> Html.text ""
                }
                    |> Html.program
                    |> TestContext.start
                    |> TestContext.update ()
                    |> TestContext.expectCmd (Ports.string expected)
        , testEqual string "verifying an initial Cmd after an update" <|
            \actual expected ->
                { init = ( (), Ports.string actual )
                , update = \msg _ -> ( msg, Cmd.none )
                , subscriptions = \_ -> Sub.none
                , view = \_ -> Html.text ""
                }
                    |> Html.program
                    |> TestContext.start
                    |> TestContext.update ()
                    |> TestContext.expectCmd (Ports.string expected)
        , describe "Cmd.map"
            [ test "with Tasks" <|
                \() ->
                    { init =
                        ( Just "INIT"
                        , Cmd.map Just <|
                            Task.perform identity <|
                                Task.succeed "TASK"
                        )
                    , update = \msg _ -> ( msg, Cmd.none )
                    , subscriptions = \_ -> Sub.none
                    , view = \_ -> Html.text ""
                    }
                        |> Html.program
                        |> TestContext.start
                        |> TestContext.model
                        |> Expect.equal (Just "TASK")
            ]
        ]
