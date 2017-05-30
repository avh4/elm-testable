module WebsocketChatTests exposing (all)

import Test exposing (..)
import Test.WebSocket
import TestContext exposing (..)
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
                    |> Test.WebSocket.acceptConnection "ws://localhost:3000/chat"
                    |> Test.WebSocket.acceptMessage "ws://localhost:3000/chat"
                        "hi!"
                    |> done
        ]
