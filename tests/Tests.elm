module Tests exposing (..)

import Test exposing (..)
import TestableTests
import Testable.EffectsLogTests


all : Test
all =
    describe "avh4/elm-testable"
        [ TestableTests.all
        , Testable.EffectsLogTests.all
        ]
