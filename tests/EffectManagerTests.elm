module EffectManagerTests exposing (all)

import Test exposing (..)
import Expect
import Html
import Process
import Task
import TestContext exposing (TestContext)
import Test.EffectManager
import Time exposing (Time)


program cmd sub =
    { init =
        ( "INIT"
        , cmd
        )
    , update =
        \msg model ->
            ( model ++ ";" ++ msg, Cmd.none )
    , subscriptions =
        \_ -> sub
    , view = \_ -> Html.text ""
    }
        |> Html.program
        |> TestContext.start


all : Test
all =
    describe "effect managers"
        [ test "it can process a Cmd" <|
            \() ->
                program (Test.EffectManager.getState identity) (Sub.none)
                    |> TestContext.expect (TestContext.model)
                        (Expect.equal "INIT;(INIT)")
        ]
