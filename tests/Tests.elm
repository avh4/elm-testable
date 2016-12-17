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


stringProgram : String -> TestContext String String
stringProgram init =
    { model = init
    , update = \msg model -> model ++ ";" ++ msg
    , view = Html.text
    }
        |> Html.beginnerProgram
        |> TestContext.start


all : Test
all =
    describe "Testable"
        [ describe "Model"
            [ test "verifying an initial model" <|
                \() ->
                    stringProgram "Start"
                        |> TestContext.model
                        |> Expect.equal "Start"
            , test "verifying an updated model" <|
                \() ->
                    stringProgram "Start"
                        |> TestContext.update "1"
                        |> TestContext.model
                        |> Expect.equal "Start;1"
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
                        |> Expect.equal expected
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
                        |> Expect.equal expected
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
                        |> Expect.equal 321
              -- TODO: ensure correct ordering of interleaved Cmds and Tasks
            , testEqual string "Task.fail" <|
                \actual expected ->
                    { init = ( Ok (), Task.fail actual |> Task.attempt identity )
                    , update = \msg model -> ( msg, Cmd.none )
                    , subscriptions = \_ -> Sub.none
                    , view = \_ -> Html.text ""
                    }
                        |> Html.program
                        |> TestContext.start
                        |> TestContext.model
                        |> Expect.equal (Err expected)
            ]
          -- , describe "Process.sleep" []
          -- , describe "Http" []
        , describe "Subscriptions"
            [ testEqual string "send triggers an update with the correct Msg" <|
                \actual expected ->
                    { init = ( Nothing, Cmd.none )
                    , update = \msg model -> ( msg, Cmd.none )
                    , subscriptions = \_ -> TestPorts.stringSub Just
                    , view = \_ -> Html.text ""
                    }
                        |> Html.program
                        |> TestContext.start
                        |> TestContext.send TestPorts.stringSub actual
                        |> Result.map TestContext.model
                        |> Expect.equal (Ok <| Just expected)
            , test "gives an error when not subscribed" <|
                \() ->
                    { init = ( Nothing, Cmd.none )
                    , update = \msg model -> ( msg, Cmd.none )
                    , subscriptions = \_ -> Sub.none
                    , view = \_ -> Html.text ""
                    }
                        |> Html.program
                        |> TestContext.start
                        |> TestContext.send TestPorts.stringSub "VALUE"
                        |> Expect.equal (Err "Not subscribed to port: stringSub")
            ]
          -- , describe "Flags" []
        ]
