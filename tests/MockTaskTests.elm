module MockTaskTests exposing (all)

import Test exposing (..)
import Expect
import Html
import TestContext exposing (TestContext)
import Task


all : Test
all =
    describe "mock tasks"
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
