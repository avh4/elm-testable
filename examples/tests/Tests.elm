module Tests exposing (..)

import Test exposing (..)
import RandomGifTests
import WebsocketChatTests


all : Test
all =
    describe "avh4/elm-testable examples"
        [ RandomGifTests.all
        , WebsocketChatTests.all
        ]
