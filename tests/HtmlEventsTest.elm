module HtmlEventsTest exposing (all)

import ElmTest exposing (..)
import Html
import Html.Events as Html
import Testable.Cmd
import Testable.TestContext as TestContext exposing (..)


type Msg
    = ButtonClick


component : TestContext.Component Msg (List Msg)
component =
    { init = ( [], Testable.Cmd.none )
    , update = \msg model -> ( msg :: model, Testable.Cmd.none )
    , view =
        \model ->
            Html.div []
                [ Html.button [ Html.onClick ButtonClick ] []
                ]
    }


all : Test
all =
    suite "Html events"
        [ startForTest component
            |> TestContext.click
            |> currentModel
            |> assertEqual (Ok [ ButtonClick ])
            |> test "onClick"
        ]
