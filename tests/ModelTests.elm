module ModelTests exposing (..)

import Test exposing (..)
import Expect
import Html
import TestContext exposing (TestContext)


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
    describe "Model"
        [ test "verifying an initial model" <|
            \() ->
                stringProgram "Start"
                    |> TestContext.expectModel
                        (Expect.equal "Start")
        , test "verifying an updated model" <|
            \() ->
                stringProgram "Start"
                    |> TestContext.update "1"
                    |> TestContext.expectModel
                        (Expect.equal "Start;1")
        ]
