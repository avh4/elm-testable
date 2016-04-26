module Tests (..) where

import ElmTest exposing (..)
import TestableTests


all : Test
all =
  suite
    "avh4/elm-testable"
    [ TestableTests.all
    ]
