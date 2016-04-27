module Testable.EffectsTests (..) where

import ElmTest exposing (..)
import Testable.Effects as Effects
import Testable.Http as Http


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
            (Http.getString "https://example.com/")
            |> test "(2)"
        , assertNotEqual
            (Http.getString "gopher://gopher.example.com")
            (Http.getString "https://example.com/")
            |> test "(3)"
        ]
    ]
