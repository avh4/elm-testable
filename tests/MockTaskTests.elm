module MockTaskTests exposing (all)

import Test exposing (..)
import Expect
import Html
import TestContextWithMocks as TestContext exposing (TestContext)
import Task


cmdProgram :
    ((mockLabel -> Platform.Task x a) -> Cmd msg)
    -> TestContext mockLabel (Result x a) (List msg) msg
cmdProgram cmd =
    (\mockTask ->
        { init = ( [], cmd mockTask )
        , update = \msg model -> ( msg :: model, Cmd.none )
        , subscriptions = \_ -> Sub.none
        , view = \_ -> Html.text ""
        }
            |> Html.program
    )
        |> TestContext.start


expectFailure : List String -> Expect.Expectation -> Expect.Expectation
expectFailure expectedMessage expectation =
    expectation
        |> Expect.getFailure
        |> Expect.equal (Just { given = "", message = String.join "\n" expectedMessage })


expectOk : (a -> Expect.Expectation) -> Result x a -> Expect.Expectation
expectOk expectation result =
    case result of
        Err x ->
            [ toString result
            , "╷"
            , "│ expectOk"
            , "╵"
            , "Ok _"
            ]
                |> String.join "\n"
                |> Expect.fail

        Ok a ->
            expectation a


all : Test
all =
    describe "mock tasks"
        [ test "can verify a mock task is pending" <|
            \() ->
                cmdProgram
                    (\mockTask -> mockTask ( "label", 1 ) |> Task.attempt (always ()))
                    |> TestContext.expectMockTask ( "label", 1 )
        , test "can verify that a mock task is not pending" <|
            \() ->
                cmdProgram (\mockTask -> Cmd.none)
                    |> TestContext.expectMockTask ( "label", 1 )
                    |> expectFailure
                        [ "pending mock tasks (none were initiated)"
                        , "╷"
                        , "│ to include (TestContext.expectMockTask)"
                        , "╵"
                        , "mockTask (\"label\",1)"
                        ]
        , test "a resolved task is no longer pending" <|
            \() ->
                cmdProgram
                    (\mockTask -> mockTask ( "label", 1 ) |> Task.attempt (always ()))
                    |> TestContext.resolveMockTask ( "label", 1 ) (Ok ())
                    |> Result.map (TestContext.expectMockTask ( "label", 1 ))
                    |> expectOk
                        (expectFailure
                            [ "pending mock tasks (none were initiated)"
                            , "╷"
                            , "│ to include (TestContext.expectMockTask)"
                            , "╵"
                            , "mockTask (\"label\",1)"
                            , ""
                            , "but mockTask (\"label\",1) was previously resolved with value Ok ()"
                            ]
                        )
        , test "can resolve a mock task with success" <|
            \() ->
                cmdProgram (\mockTask -> mockTask ( "label", 1 ) |> Task.attempt Just)
                    |> TestContext.resolveMockTask ( "label", 1 ) (Ok [ 7, 8, 9 ])
                    |> Result.map TestContext.model
                    |> Expect.equal (Ok <| [ Just <| Ok [ 7, 8, 9 ] ])
        , test "can resolve a mock task with an error" <|
            \() ->
                cmdProgram (\mockTask -> mockTask ( "label", 1 ) |> Task.attempt Just)
                    |> TestContext.resolveMockTask ( "label", 1 ) (Err "failure")
                    |> Result.map TestContext.model
                    |> Expect.equal (Ok <| [ Just <| Err "failure" ])
        , test "works with Task.andThen" <|
            \() ->
                cmdProgram
                    (\mockTask ->
                        mockTask ( "label", 1 )
                            |> Task.andThen ((++) "andThen!" >> Task.succeed)
                            |> Task.attempt identity
                    )
                    |> TestContext.resolveMockTask ( "label", 1 ) (Ok "good")
                    |> Result.map TestContext.model
                    |> Expect.equal (Ok <| [ Ok "andThen!good" ])
        , test "works with Task.onErro" <|
            \() ->
                cmdProgram
                    (\mockTask ->
                        mockTask ( "label", 1 )
                            |> Task.onError ((++) "onError!" >> Task.succeed)
                            |> Task.attempt identity
                    )
                    |> TestContext.resolveMockTask ( "label", 1 ) (Err "bad")
                    |> Result.map TestContext.model
                    |> Expect.equal (Ok <| [ Ok "onError!bad" ])
        , test "works with Cmd.map" <|
            \() ->
                cmdProgram
                    (\mockTask ->
                        mockTask ( "label", 1 )
                            |> Task.attempt identity
                            |> Cmd.map ((,) "mapped")
                    )
                    |> TestContext.resolveMockTask ( "label", 1 ) (Ok ())
                    |> Result.map TestContext.model
                    |> Expect.equal (Ok <| [ ( "mapped", Ok () ) ])
          -- TODO: what happens when mockTask |> andThen mockTask
        ]
