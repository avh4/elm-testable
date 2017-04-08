module EffectManagerTests exposing (all)

import Test exposing (..)
import Expect
import Html
import TestContext exposing (TestContext)
import Test.EffectManager


program : Cmd String -> Sub String -> Program Never String String
program cmd sub =
    { init =
        ( "INIT"
        , cmd
        )
    , update =
        \msg model ->
            case msg of
                "PING" ->
                    ( model, Test.EffectManager.pingSubs )

                "GET" ->
                    ( model, Test.EffectManager.getState identity )

                _ ->
                    ( model ++ ";" ++ msg, Cmd.none )
    , subscriptions =
        \_ -> sub
    , view = \_ -> Html.text ""
    }
        |> Html.program


prefix : String -> String -> String
prefix pref s =
    pref ++ s


all : Test
all =
    describe "effect managers"
        [ test "it can process a Cmd" <|
            \() ->
                program
                    (Test.EffectManager.getState identity)
                    (Sub.none)
                    |> TestContext.start
                    |> TestContext.expect
                        (TestContext.model)
                        (Expect.equal "INIT;(INIT)")
        , test "it can process a Sub" <|
            \() ->
                program
                    (Cmd.none)
                    (Test.EffectManager.subState identity)
                    |> TestContext.start
                    |> TestContext.update "PING"
                    |> TestContext.expect
                        (TestContext.model)
                        (Expect.equal "INIT;[INIT]")
        , test "it works with Cmd.map" <|
            \() ->
                program
                    (Cmd.map (prefix "a") <| Test.EffectManager.getState identity)
                    (Sub.none)
                    |> TestContext.start
                    |> TestContext.expect
                        (TestContext.model)
                        (Expect.equal "INIT;a(INIT)")
        , test "it works with Sub.map" <|
            \() ->
                program
                    (Cmd.none)
                    (Sub.map (prefix "b") <| Test.EffectManager.subState identity)
                    |> TestContext.start
                    |> TestContext.update "PING"
                    |> TestContext.expect
                        (TestContext.model)
                        (Expect.equal "INIT;b[INIT]")
        , test "it can process a self msg" <|
            \() ->
                program
                    (Test.EffectManager.updateSelf "UP")
                    (Sub.none)
                    |> TestContext.start
                    |> TestContext.update "GET"
                    |> TestContext.expect
                        (TestContext.model)
                        (Expect.equal "INIT;(INIT;UP)")
        ]
