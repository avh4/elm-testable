module WebSocketsTests exposing (..)

import Test exposing (..)
import Testable.TestContext exposing (..)
import Testable.Html.Selector exposing (..)
import WebSockets
import WebSocket


webSocketsComponent : Testable.TestContext.Component WebSockets.Msg WebSockets.Model
webSocketsComponent =
    { init = WebSockets.init
    , update = WebSockets.update
    , view = WebSockets.view
    }


all : Test
all =
    describe "WebSockets"
        [ test "sends inputed message through websocket" <|
            \() ->
                webSocketsComponent
                    |> startForTest
                    |> find [ tag "input" ]
                    |> trigger "input" "{\"target\": {\"value\": \"dogs\"}}"
                    |> find [ tag "button" ]
                    |> trigger "click" "{}"
                    |> assertCalled (WebSocket.send WebSockets.echoServer "dogs")
        ]
