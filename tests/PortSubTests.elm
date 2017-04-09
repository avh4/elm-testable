module PortSubTests exposing (..)

import Test exposing (..)
import Expect exposing (Expectation)
import Html
import TestContext exposing (TestContext)
import Test.Ports as Ports


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


expectOk : (a -> Expectation) -> Result x a -> Expectation
expectOk check result =
    case result of
        Ok a ->
            check a

        Err _ ->
            Expect.fail ("Expected (Ok _), but got: " ++ toString result)


all : Test
all =
    describe "port subscriptions"
        [ test "send triggers an update" <|
            \() ->
                subProgram (Ports.stringSub identity)
                    |> TestContext.send Ports.stringSub "1"
                    |> expectOk
                        (TestContext.expectModel
                            (Expect.equal "INIT;1")
                        )
        , test "the tagger is applied" <|
            \() ->
                subProgram
                    (Ports.stringSub (prefix "a"))
                    |> TestContext.send Ports.stringSub "1"
                    |> expectOk
                        (TestContext.expectModel
                            (Expect.equal "INIT;a1")
                        )
        , test "gives an error when not subscribed" <|
            \() ->
                subProgram (Sub.none)
                    |> TestContext.send Ports.stringSub "VALUE"
                    |> Expect.equal (Err "Not subscribed to port: stringSub")
        , test "Sub.map" <|
            \() ->
                subProgram (Sub.map (prefix "z") <| Ports.stringSub identity)
                    |> TestContext.send Ports.stringSub "1"
                    |> expectOk
                        (TestContext.expectModel
                            (Expect.equal "INIT;z1")
                        )
        , test "send triggers all taggers" <|
            \() ->
                subProgram
                    (Sub.batch
                        [ Ports.stringSub (prefix "a")
                        , Ports.stringSub (prefix "b")
                        ]
                    )
                    |> TestContext.send Ports.stringSub "1"
                    |> expectOk
                        (TestContext.expectModel
                            (Expect.equal "INIT;a1;b1")
                        )
        ]
