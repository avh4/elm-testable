module WebSocketsTests exposing (..)

import Test exposing (..)
import Testable.TestContext exposing (..)
import WebSockets
import WebSocket


webSocketsComponent : Testable.TestContext.Component WebSockets.Msg WebSockets.Model
webSocketsComponent =
    { init = WebSockets.init
    , update = WebSockets.update
    }


all : Test
all =
    describe "WebSockets"
        [ test "sends inputed message through websocket" <|
            \() ->
                webSocketsComponent
                    |> startForTest
                    |> update (WebSockets.Input "dogs")
                    |> update WebSockets.Send
                    |> assertCalled (WebSocket.send WebSockets.echoServer "dogs")
        ]
