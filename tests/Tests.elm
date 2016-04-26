module Tests (..) where

import ElmTest exposing (..)
import Testable.TaskTests


all : Test
all =
  suite
    "avh4/elm-testable"
    [ Testable.TaskTests.all
    ]
