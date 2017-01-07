module Tests exposing (..)

import Test exposing (..)
import Expect
import Html
import TestContext exposing (TestContext)
import Task
import CmdTests
import HttpTests
import ModelTests
import SubTests
import Testable.TaskTests


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
        [ Testable.TaskTests.all
        , ModelTests.all
        , CmdTests.all
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
        , describe "mock tasks"
            [ test "can verify a mock task is pending" <|
                \() ->
                    (\mockTask ->
                        { init = ( (), mockTask ( "label", 1 ) |> Task.attempt (always ()) )
                        , update = \msg model -> ( msg, Cmd.none )
                        , subscriptions = \_ -> Sub.none
                        , view = \_ -> Html.text ""
                        }
                            |> Html.program
                    )
                        |> TestContext.startWithMockTask
                        |> TestContext.expectMockTask ( "label", 1 )
            , test "a resolved task is no longer pending" <|
                \() ->
                    (\mockTask ->
                        { init = ( (), mockTask ( "label", 1 ) |> Task.attempt (always ()) )
                        , update = \msg model -> ( msg, Cmd.none )
                        , subscriptions = \_ -> Sub.none
                        , view = \_ -> Html.text ""
                        }
                            |> Html.program
                    )
                        |> TestContext.startWithMockTask
                        |> TestContext.resolveMockTask ( "label", 1 ) (Ok ())
                        |> Result.map (TestContext.expectMockTask ( "label", 1 ))
                        |> Result.map Expect.getFailure
                        |> -- TODO: message says is was previously resolved
                           Expect.equal (Ok <| Just { given = "", message = "pending mock tasks (none were initiated)\n╷\n│ to include (TestContext.expectMockTask)\n╵\nmockTask (\"label\",1)" })
            , test "can resolve a mock task with success" <|
                \() ->
                    (\mockTask ->
                        { init = ( Nothing, mockTask ( "label", 1 ) |> Task.attempt Just )
                        , update = \msg model -> ( msg, Cmd.none )
                        , subscriptions = \_ -> Sub.none
                        , view = \_ -> Html.text ""
                        }
                            |> Html.program
                    )
                        |> TestContext.startWithMockTask
                        |> TestContext.resolveMockTask ( "label", 1 ) (Ok [ 7, 8, 9 ])
                        |> Result.map TestContext.model
                        |> Expect.equal (Ok <| Just <| Ok [ 7, 8, 9 ])
              -- TODO: a resolved task is no longer pending
              -- TODO: can resolve a mock task with error
              -- TODO: mockTask works with Task.andThen
              -- TODO: mockTask works with Task.onError
              -- TODO: mockTask works with Cmd.map
              -- TODO: what happens when mockTask |> andThen mockTask
            ]
        , HttpTests.all
        , SubTests.all
          -- , describe "Flags" []
        ]
