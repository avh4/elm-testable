module Tests exposing (..)

import Test exposing (..)
import RandomGifTests
import SpellingTests


all : Test
all =
    describe "avh4/elm-testable examples"
        [ RandomGifTests.all
        , SpellingTests.all
        ]
