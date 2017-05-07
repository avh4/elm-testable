module MockTaskTests exposing (all)

import Test exposing (..)
import Expect exposing (Expectation)
import Html
import Process
import Task
import TestContextWithMocks as TestContext exposing (SingleQueryTest)
import Test.Util exposing (..)


cmdProgram :
    Cmd msg
    -> SingleQueryTest (List msg) msg
cmdProgram cmd =
    Html.program
        { init = ( [], cmd )
        , update = \msg model -> ( msg :: model, Cmd.none )
        , subscriptions = \_ -> Sub.none
        , view = \_ -> Html.text ""
        }
        |> TestContext.start


expectNotInclude : a -> List a -> Expectation
expectNotInclude what list =
    if List.member what list then
        Expect.fail ("Expected " ++ toString list ++ " to not include " ++ toString what)
    else
        Expect.pass


singleMock : TestContext.MockTask String String
singleMock =
    TestContext.mockTask "singleton"


listMock : TestContext.MockTask String (List Int)
listMock =
    TestContext.mockTask "listMock"


mocks :
    { a : TestContext.MockTask String Int
    , b : Int -> TestContext.MockTask String Int
    , int : TestContext.MockTask Never Int
    , string : TestContext.MockTask Never String
    }
mocks =
    { a = TestContext.mockTask "a"
    , b = \i -> TestContext.mockTask ("b-" ++ toString i)
    , int = TestContext.mockTask "Int task"
    , string = TestContext.mockTask "String task"
    }


all : Test
all =
    describe "mock tasks"
        [ test "can verify a mock task is pending" <|
            \() ->
                cmdProgram
                    (singleMock |> TestContext.toTask |> Task.attempt (always ()))
                    |> TestContext.expectMockTask singleMock
        , test "can verify that a mock task is not pending" <|
            \() ->
                cmdProgram
                    (Cmd.none)
                    |> TestContext.expectMockTask singleMock
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
                    (singleMock |> TestContext.toTask |> Task.attempt (always ()))
                    |> TestContext.resolveMockTask singleMock (Ok "")
                    |> TestContext.expectMockTask singleMock
                    |> expectFailure
                        [ "pending mock tasks (none were initiated)"
                        , "╷"
                        , "│ to include (TestContext.expectMockTask)"
                        , "╵"
                        , "mockTask \"singleton\""
                        , ""
                        , "but mockTask \"singleton\" was previously resolved with value Ok \"\""
                        ]
        , test "can resolve a mock task with success" <|
            \() ->
                cmdProgram
                    (listMock |> TestContext.toTask |> Task.attempt Just)
                    |> TestContext.resolveMockTask listMock
                        (Ok [ 7, 8, 9 ])
                    |> TestContext.expectModel
                        (Expect.equal [ Just <| Ok [ 7, 8, 9 ] ])
        , test "can resolve a mock task with an error" <|
            \() ->
                cmdProgram
                    (singleMock |> TestContext.toTask |> Task.attempt Just)
                    |> TestContext.resolveMockTask singleMock (Err "failure")
                    |> TestContext.expectModel
                        (Expect.equal [ Just <| Err "failure" ])
        , test "works with Task.andThen" <|
            \() ->
                cmdProgram
                    (singleMock
                        |> TestContext.toTask
                        |> Task.andThen ((++) "andThen!" >> Task.succeed)
                        |> Task.attempt identity
                    )
                    |> TestContext.resolveMockTask singleMock (Ok "good")
                    |> TestContext.expectModel
                        (Expect.equal [ Ok "andThen!good" ])
        , test "works with Task.onError" <|
            \() ->
                cmdProgram
                    (singleMock
                        |> TestContext.toTask
                        |> Task.onError ((++) "onError!" >> Task.succeed)
                        |> Task.attempt identity
                    )
                    |> TestContext.resolveMockTask singleMock (Err "bad")
                    |> TestContext.expectModel
                        (Expect.equal [ Ok "onError!bad" ])
        , test "works with Cmd.map" <|
            \() ->
                cmdProgram
                    (singleMock
                        |> TestContext.toTask
                        |> Task.attempt identity
                        |> Cmd.map ((,) "mapped")
                    )
                    |> TestContext.resolveMockTask singleMock (Ok "")
                    |> TestContext.expectModel
                        (Expect.equal [ ( "mapped", Ok "" ) ])
        , test "can chain mock tasks" <|
            \() ->
                cmdProgram
                    (mocks.a
                        |> TestContext.toTask
                        |> Task.andThen (mocks.b >> TestContext.toTask)
                        |> Task.attempt identity
                    )
                    |> TestContext.resolveMockTask mocks.a (Ok 999)
                    |> TestContext.expectMockTask (mocks.b 999)
        , test "can resolve chained mock tasks" <|
            \() ->
                cmdProgram
                    (mocks.a
                        |> TestContext.toTask
                        |> Task.andThen ((+) 10000 >> mocks.b >> TestContext.toTask)
                        |> Task.attempt identity
                    )
                    |> TestContext.resolveMockTask mocks.a (Ok 999)
                    |> TestContext.resolveMockTask (mocks.b 10999) (Ok 55)
                    |> TestContext.expectModel
                        (Expect.equal [ Ok 55 ])
        , test "example of mock task with multiple task types" <|
            \() ->
                cmdProgram
                    (Cmd.batch
                        [ mocks.int |> TestContext.toTask |> Task.attempt Ok
                        , mocks.string |> TestContext.toTask |> Task.attempt Err
                        ]
                    )
                    |> TestContext.resolveMockTask mocks.int (Ok 9)
                    |> TestContext.resolveMockTask mocks.string (Ok "good")
                    |> TestContext.expectModel
                        (Expect.equal
                            [ Err <| Ok "good"
                            , Ok <| Ok 9
                            ]
                        )
        , test "inspecting spawned tasks" <|
            \() ->
                cmdProgram
                    (singleMock |> TestContext.toTask |> Process.spawn |> Task.attempt identity)
                    |> TestContext.expectMockTask singleMock
        , test "resolving a spawned task does nothing" <|
            \() ->
                cmdProgram
                    (singleMock |> TestContext.toTask |> Process.spawn |> Task.attempt (Result.map toString))
                    |> TestContext.resolveMockTask singleMock (Ok "spawned task")
                    |> TestContext.expectModel
                        (List.filterMap (Result.toMaybe)
                            >> expectNotInclude "spawned task"
                        )
        ]
