module Tests exposing (..)

import Test exposing (..)


-- import RandomGifTests
-- import SpellingTests

import WebSocketsTests
import HelloWorldTests


all : Test
all =
    describe "avh4/elm-testable examples"
        [ HelloWorldTests.all
          -- , RandomGifTests.all
          -- , SpellingTests.all
        , WebSocketsTests.all
        ]
