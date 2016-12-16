module Tests exposing (..)

import Test exposing (..)
import Expect
import Html
import TestContext exposing (TestContext)


all : Test
all =
    describe "Testable"
        [ describe "Model"
            [ test "verifying an initial model" <|
                \() ->
                    { model = "Alpha"
                    , update = \_ _ -> "Beta"
                    , view = \_ -> Html.text ""
                    }
                        |> Html.beginnerProgram
                        |> TestContext.start
                        |> TestContext.model
                        |> Expect.equal (Ok "Alpha")
            ]
          -- , describe "Cmds" []
          -- , describe "Http" []
          -- , describe "Tasks" []
          -- , describe "Subscriptions" []
        ]
