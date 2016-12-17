module Tests exposing (..)

import Test exposing (..)
import Expect
import Html
import TestContext exposing (TestContext)


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
                    , update = \_ _ -> "Beta"
                    , view = \_ -> Html.text ""
                    }
                        |> Html.beginnerProgram
                        |> TestContext.start
                        |> TestContext.model
                        |> Expect.notEqual (Ok expected)
            ]
          -- , describe "Cmds" []
          -- , describe "Http" []
          -- , describe "Tasks" []
          -- , describe "Subscriptions" []
        ]
