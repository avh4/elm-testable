module Tests exposing (..)

import Test exposing (..)
import RandomGifTests


all : Test
all =
    describe "avh4/elm-testable examples"
        [ RandomGifTests.all
        ]
