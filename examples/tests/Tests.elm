module Tests exposing (..)

import RandomGifTests
import Test exposing (..)
import WebsocketChatTests


all : Test
all =
    describe "avh4/elm-testable examples"
        [ RandomGifTests.all
        , WebsocketChatTests.all
        ]
