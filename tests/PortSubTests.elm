module PortSubTests exposing (..)

import Expect exposing (Expectation)
import Html
import Test exposing (..)
import Test.Ports as Ports
import Test.Util exposing (..)
import TestContext exposing (TestContext)


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
                subProgram (Ports.stringSub identity)
                    |> TestContext.send Ports.stringSub "1"
                    |> TestContext.expectModel
                        (Expect.equal "INIT;1")
        , test "the tagger is applied" <|
            \() ->
                subProgram
                    (Ports.stringSub (prefix "a"))
                    |> TestContext.send Ports.stringSub "1"
                    |> TestContext.expectModel
                        (Expect.equal "INIT;a1")
        , test "gives an error when not subscribed" <|
            \() ->
                subProgram Sub.none
                    |> TestContext.send Ports.stringSub "VALUE"
                    |> TestContext.expectModel (always Expect.pass)
                    |> expectFailure [ "Not subscribed to port: stringSub" ]
        , test "Sub.map" <|
            \() ->
                subProgram (Sub.map (prefix "z") <| Ports.stringSub identity)
                    |> TestContext.send Ports.stringSub "1"
                    |> TestContext.expectModel
                        (Expect.equal "INIT;z1")
        , test "send triggers all taggers" <|
            \() ->
                subProgram
                    (Sub.batch
                        [ Ports.stringSub (prefix "a")
                        , Ports.stringSub (prefix "b")
                        ]
                    )
                    |> TestContext.send Ports.stringSub "1"
                    |> TestContext.expectModel
                        (Expect.equal "INIT;a1;b1")
        ]
