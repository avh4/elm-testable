module Tests (..) where

import ElmTest exposing (..)
import TestableTests
import Testable.EffectsTests
import Testable.EffectsLogTests


all : Test
all =
  suite
    "avh4/elm-testable"
    [ TestableTests.all
    , Testable.EffectsTests.all
    , Testable.EffectsLogTests.all
    ]
