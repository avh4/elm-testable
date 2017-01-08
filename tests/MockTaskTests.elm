module MockTaskTests exposing (all)

import Test exposing (..)
import Expect
import Html
import TestContextWithMocks as TestContext exposing (TestContext)
import Task


cmdProgram :
    (mocks -> Cmd msg)
    -> (TestContext.Token -> mocks)
    -> TestContext mocks (List msg) msg
cmdProgram cmd createMocks =
    TestContext.start
        (\mocks ->
            { init = ( [], cmd mocks )
            , update = \msg model -> ( msg :: model, Cmd.none )
            , subscriptions = \_ -> Sub.none
            , view = \_ -> Html.text ""
            }
                |> Html.program
        )
        createMocks


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
                    (\mocks -> mocks |> TestContext.toTask |> Task.attempt (always ()))
                    (\token -> TestContext.mockTask token "singleton")
                    |> TestContext.expectMockTask identity
        , test "can verify that a mock task is not pending" <|
            \() ->
                cmdProgram
                    (\mocks -> Cmd.none)
                    (\token -> TestContext.mockTask token "singleton")
                    |> TestContext.expectMockTask identity
                    |> expectFailure
                        [ "pending mock tasks (none were initiated)"
                        , "╷"
                        , "│ to include (TestContext.expectMockTask)"
                        , "╵"
                        , "mockTask \"singleton\""
                        ]
        , test "a resolved task is no longer pending" <|
            \() ->
                cmdProgram
                    (\mocks -> mocks |> TestContext.toTask |> Task.attempt (always ()))
                    (\token -> TestContext.mockTask token "singleton")
                    |> TestContext.resolveMockTask identity (Ok ())
                    |> Result.map (TestContext.expectMockTask identity)
                    |> expectOk
                        (expectFailure
                            [ "pending mock tasks (none were initiated)"
                            , "╷"
                            , "│ to include (TestContext.expectMockTask)"
                            , "╵"
                            , "mockTask \"singleton\""
                            , ""
                            , "but mockTask \"singleton\" was previously resolved with value Ok ()"
                            ]
                        )
        , test "can resolve a mock task with success" <|
            \() ->
                cmdProgram
                    (\mocks -> mocks |> TestContext.toTask |> Task.attempt Just)
                    (\token -> TestContext.mockTask token "singleton")
                    |> TestContext.resolveMockTask identity (Ok [ 7, 8, 9 ])
                    |> Result.map TestContext.model
                    |> Expect.equal (Ok <| [ Just <| Ok [ 7, 8, 9 ] ])
        , test "can resolve a mock task with an error" <|
            \() ->
                cmdProgram
                    (\mocks -> mocks |> TestContext.toTask |> Task.attempt Just)
                    (\token -> TestContext.mockTask token "singleton")
                    |> TestContext.resolveMockTask identity (Err "failure")
                    |> Result.map TestContext.model
                    |> Expect.equal (Ok <| [ Just <| Err "failure" ])
        , test "works with Task.andThen" <|
            \() ->
                cmdProgram
                    (\mocks ->
                        mocks
                            |> TestContext.toTask
                            |> Task.andThen ((++) "andThen!" >> Task.succeed)
                            |> Task.attempt identity
                    )
                    (\token -> TestContext.mockTask token "singleton")
                    |> TestContext.resolveMockTask identity (Ok "good")
                    |> Result.map TestContext.model
                    |> Expect.equal (Ok <| [ Ok "andThen!good" ])
        , test "works with Task.onError" <|
            \() ->
                cmdProgram
                    (\mocks ->
                        mocks
                            |> TestContext.toTask
                            |> Task.onError ((++) "onError!" >> Task.succeed)
                            |> Task.attempt identity
                    )
                    (\token -> TestContext.mockTask token "singleton")
                    |> TestContext.resolveMockTask identity (Err "bad")
                    |> Result.map TestContext.model
                    |> Expect.equal (Ok <| [ Ok "onError!bad" ])
        , test "works with Cmd.map" <|
            \() ->
                cmdProgram
                    (\mocks ->
                        mocks
                            |> TestContext.toTask
                            |> Task.attempt identity
                            |> Cmd.map ((,) "mapped")
                    )
                    (\token -> TestContext.mockTask token "singleton")
                    |> TestContext.resolveMockTask identity (Ok ())
                    |> Result.map TestContext.model
                    |> expectOk (Expect.equal [ ( "mapped", Ok () ) ])
        , test "can chain mock tasks" <|
            \() ->
                cmdProgram
                    (\mocks ->
                        mocks.a
                            |> TestContext.toTask
                            |> Task.andThen (mocks.b >> TestContext.toTask)
                            |> Task.attempt identity
                    )
                    (\token ->
                        { a = TestContext.mockTask token "a"
                        , b = \i -> TestContext.mockTask token ("b-" ++ toString i)
                        }
                    )
                    |> TestContext.resolveMockTask .a (Ok 999)
                    |> expectOk (TestContext.expectMockTask (\m -> m.b 999))
        , test "can resolve chained mock tasks" <|
            \() ->
                cmdProgram
                    (\mocks ->
                        mocks.initial
                            |> TestContext.toTask
                            |> Task.andThen ((,) "andThen" >> mocks.b >> TestContext.toTask)
                            |> Task.attempt identity
                    )
                    (\token ->
                        { initial = TestContext.mockTask token "initial"
                        , b = \i -> TestContext.mockTask token ("b-" ++ toString i)
                        }
                    )
                    |> TestContext.resolveMockTask .initial (Ok 999)
                    |> Result.andThen
                        (TestContext.resolveMockTask (\m -> m.b ( "andThen", 999 )) (Ok 55))
                    |> Result.map TestContext.model
                    |> expectOk (Expect.equal [ Ok 55 ])
        , test "example of mock task with multiple task types" <|
            \() ->
                cmdProgram
                    (\mocks ->
                        Cmd.batch
                            [ mocks.int |> TestContext.toTask |> Task.attempt Ok
                            , mocks.string |> TestContext.toTask |> Task.attempt Err
                            ]
                    )
                    (\token ->
                        { int = TestContext.mockTask token "Int task"
                        , string = TestContext.mockTask token "String task"
                        }
                    )
                    |> TestContext.resolveMockTask .int (Ok 9)
                    |> Result.andThen (TestContext.resolveMockTask .string (Ok "good"))
                    |> Result.map TestContext.model
                    |> Expect.equal
                        (Ok <|
                            [ Err <| Ok "good"
                            , Ok <| Ok 9
                            ]
                        )
        ]
