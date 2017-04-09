module TaskTests exposing (all)

import Test exposing (..)
import Expect exposing (Expectation)
import Html
import TestContext exposing (TestContext)
import Task


testEqual : Gen a -> String -> (a -> a -> Expectation) -> Test
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
    describe "Tasks"
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
                    |> TestContext.expectModel (Expect.equal expected)
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
                    |> TestContext.expectModel
                        (Expect.equal expected)
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
                    |> TestContext.expectModel
                        (Expect.equal 321)

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
                    |> TestContext.expectModel
                        (Expect.equal (Err expected))
        ]
