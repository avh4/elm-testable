module WebsocketChatTests exposing (all)

import Test exposing (..)
import TestContext exposing (..)
import TestContext.WebSocket
import WebsocketChat exposing (Msg(..))


all : Test
all =
    describe "WebsocketChat"
        [ test "sends messages to the server" <|
            \() ->
                WebsocketChat.program
                    |> start
                    |> update (TypeMessage "hi!")
                    |> update SendMessage
                    |> TestContext.WebSocket.acceptConnection "ws://localhost:3000/chat"
                    |> TestContext.WebSocket.acceptMessage "ws://localhost:3000/chat"
                        "hi!"
                    |> done
        ]
