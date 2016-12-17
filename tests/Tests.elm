module Tests exposing (..)

import Test exposing (..)
import Expect
import Html
import TestContext exposing (TestContext)
import TestPorts
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
    describe "Testable"
        [ describe "Model"
            [ testEqual string "verifying an initial model" <|
                \actual expected ->
                    { model = actual
                    , update = \msg _ -> msg
                    , view = Html.text
                    }
                        |> Html.beginnerProgram
                        |> TestContext.start
                        |> TestContext.model
                        |> Expect.equal (Ok expected)
            , testEqual string "verifying an updated model" <|
                \actual expected ->
                    { model = "Start"
                    , update = \msg _ -> msg
                    , view = Html.text
                    }
                        |> Html.beginnerProgram
                        |> TestContext.start
                        |> TestContext.update actual
                        |> TestContext.model
                        |> Expect.equal (Ok expected)
            ]
        , describe "Cmds"
            [ testEqual string "verifying an initial Cmd" <|
                \actual expected ->
                    { init = ( (), TestPorts.string actual )
                    , update = \msg _ -> ( msg, Cmd.none )
                    , subscriptions = \_ -> Sub.none
                    , view = \_ -> Html.text ""
                    }
                        |> Html.program
                        |> TestContext.start
                        |> TestContext.expectCmd (TestPorts.string expected)
            , testEqual string "verifying a Cmd from update" <|
                \actual expected ->
                    { init = ( (), Cmd.none )
                    , update = \msg _ -> ( msg, TestPorts.string actual )
                    , subscriptions = \_ -> Sub.none
                    , view = \_ -> Html.text ""
                    }
                        |> Html.program
                        |> TestContext.start
                        |> TestContext.update ()
                        |> TestContext.expectCmd (TestPorts.string expected)
            , testEqual string "verifying an initial Cmd after an update" <|
                \actual expected ->
                    { init = ( (), TestPorts.string actual )
                    , update = \msg _ -> ( msg, Cmd.none )
                    , subscriptions = \_ -> Sub.none
                    , view = \_ -> Html.text ""
                    }
                        |> Html.program
                        |> TestContext.start
                        |> TestContext.update ()
                        |> TestContext.expectCmd (TestPorts.string expected)
            ]
        , describe "Tasks"
            [ testEqual string "tasks in initial commands should immediately be processed" <|
                \actual expected ->
                    { init =
                        ( "Start"
                        , Task.succeed actual |> Task.perform identity
                        )
                    , update = \msg _ -> ( msg, Cmd.none )
                    , subscriptions = \_ -> Sub.none
                    , view = \_ -> Html.text ""
                    }
                        |> Html.program
                        |> TestContext.start
                        |> TestContext.model
                        |> Expect.equal (Ok expected)
            , testEqual string "tasks in update commands should immediately be processed" <|
                \actual expected ->
                    { init = ( "Start", Cmd.none )
                    , update =
                        \msg model ->
                            case msg of
                                Ok s ->
                                    ( s, Cmd.none )

                                Err s ->
                                    ( model, Task.succeed s |> Task.perform Ok )
                    , subscriptions = \_ -> Sub.none
                    , view = \_ -> Html.text ""
                    }
                        |> Html.program
                        |> TestContext.start
                        |> TestContext.update (Err actual)
                        |> TestContext.model
                        |> Expect.equal (Ok expected)
            , test "tasks should only be processed once" <|
                \() ->
                    { init = ( 0, Task.succeed 1 |> Task.perform identity )
                    , update = \msg model -> ( msg + model, Cmd.none )
                    , subscriptions = \_ -> Sub.none
                    , view = \_ -> Html.text ""
                    }
                        |> Html.program
                        |> TestContext.start
                        |> TestContext.update 20
                        |> TestContext.update 300
                        |> TestContext.model
                        |> Expect.equal (Ok 321)
              -- TODO: ensure correct ordering of interleaved Cmds and Tasks
            ]
          -- , describe "Http" []
          -- , describe "Subscriptions" []
        ]
