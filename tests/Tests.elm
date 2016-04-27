module Tests (..) where

import ElmTest exposing (..)
import TestableTests
import Testable.EffectsLogTests


all : Test
all =
  suite
    "avh4/elm-testable"
    [ TestableTests.all
    , Testable.EffectsLogTests.all
    ]
