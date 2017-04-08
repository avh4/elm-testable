module FlagsTests exposing (..)

import Test exposing (..)
import Expect
import Html
import TestContext exposing (TestContext)


type alias Flags =
    String


stringProgram : Program Flags String String
stringProgram =
    { init = \flags -> ( flags, Cmd.none )
    , update = \msg model -> ( model ++ ";" ++ msg, Cmd.none )
    , subscriptions = \_ -> Sub.none
    , view = Html.text
    }
        |> Html.programWithFlags


all : Test
all =
    describe "Flags"
        [ test "starting a program with flags" <|
            \() ->
                stringProgram
                    |> TestContext.startWithFlags "Start"
                    |> TestContext.model
                    |> Expect.equal "Start"
        ]
