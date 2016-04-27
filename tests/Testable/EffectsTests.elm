module Testable.EffectsTests (..) where

import ElmTest exposing (..)
import Testable.Effects as Effects


type MyWrapper a
  = MyWrapper a


all : Test
all =
  suite
    "Testable.Effects"
    [ suite
        "comparison"
        [ assertEqual
            (Effects.none)
            (Effects.none)
            |> test "(1)"
        , assertNotEqual
            (Effects.none)
            (Effects.http "https://example.com/")
            |> test "(2)"
        , assertNotEqual
            (Effects.http "gopher://gopher.example.com")
            (Effects.http "https://example.com/")
            |> test "(3)"
        ]
    ]
