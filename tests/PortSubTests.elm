module PortSubTests exposing (..)

import Test exposing (..)
import Expect
import Html
import TestContext exposing (TestContext)
import TestPorts


subProgram : Sub String -> TestContext String String
subProgram subs =
    { init = ( "INIT", Cmd.none )
    , update = \msg model -> ( model ++ ";" ++ msg, Cmd.none )
    , subscriptions = \_ -> subs
    , view = \_ -> Html.text ""
    }
        |> Html.program
        |> TestContext.start


prefix : String -> String -> String
prefix pref s =
    pref ++ s


all : Test
all =
    describe "port subscriptions"
        [ test "send triggers an update" <|
            \() ->
                subProgram (TestPorts.stringSub identity)
                    |> TestContext.send TestPorts.stringSub "1"
                    |> Result.map TestContext.model
                    |> Expect.equal (Ok "INIT;1")
        , test "the tagger is applied" <|
            \() ->
                subProgram
                    (TestPorts.stringSub (prefix "a"))
                    |> TestContext.send TestPorts.stringSub "1"
                    |> Result.map TestContext.model
                    |> Expect.equal (Ok <| "INIT;a1")
        , test "gives an error when not subscribed" <|
            \() ->
                subProgram (Sub.none)
                    |> TestContext.send TestPorts.stringSub "VALUE"
                    |> Expect.equal (Err "Not subscribed to port: stringSub")
        , test "Sub.map" <|
            \() ->
                subProgram (Sub.map (prefix "z") <| TestPorts.stringSub identity)
                    |> TestContext.send TestPorts.stringSub "1"
                    |> Result.map TestContext.model
                    |> Expect.equal (Ok "INIT;z1")
        ]
