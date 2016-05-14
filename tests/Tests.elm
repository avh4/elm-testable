module Tests exposing (..)

import ElmTest exposing (..)
import HtmlEventsTest
import TestableTests
import Testable.EffectsLogTests


all : Test
all =
    suite "avh4/elm-testable"
        [ HtmlEventsTest.all
        , TestableTests.all
        , Testable.EffectsLogTests.all
        ]
