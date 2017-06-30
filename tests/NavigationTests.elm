module NavigationTests exposing (..)

import Expect
import Html
import Navigation
import Test exposing (..)
import TestContext exposing (TestContext)


type Msg
    = UrlChange Navigation.Location


stringProgram : TestContext String Msg
stringProgram =
    Navigation.program UrlChange
        { init = \location -> ( toString location, Cmd.none )
        , update = \msg model -> ( model ++ ";" ++ toString msg, Cmd.none )
        , subscriptions = \_ -> Sub.none
        , view = Html.text
        }
        |> TestContext.start


all : Test
all =
    describe "Navigation"
        [ test "starting a navigation program" <|
            \() ->
                stringProgram
                    |> TestContext.expectModel (Expect.equal "")
        ]
