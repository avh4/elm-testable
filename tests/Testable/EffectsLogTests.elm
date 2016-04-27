module Testable.EffectsLogTests (..) where

import ElmTest exposing (..)
import Testable.Effects as Effects
import Testable.EffectsLog as EffectsLog


type MyWrapper a
  = MyWrapper a


all : Test
all =
  suite
    "Testable.EffectsLog"
    [ suite
        "resulting actions"
        [ EffectsLog.empty
            |> EffectsLog.insert (Effects.http "https://example.com/")
            |> EffectsLog.httpAction "https://example.com/" "responseBody"
            |> Maybe.map snd
            |> assertEqual (Just "responseBody")
            |> test "directly consuming the result"
        , EffectsLog.empty
            |> EffectsLog.insert (Effects.http "https://example.com/" |> Effects.map MyWrapper)
            |> EffectsLog.httpAction "https://example.com/" "responseBody"
            |> Maybe.map snd
            |> assertEqual (Just <| MyWrapper "responseBody")
            |> test "mapping the result"
        , EffectsLog.empty
            |> EffectsLog.insert (Effects.http "https://example.com/")
            |> EffectsLog.httpAction "https://XXXX/" "responseBody"
            |> Maybe.map snd
            |> assertEqual Nothing
            |> test "resolving a request that doesn't match gives Nothing"
        , EffectsLog.empty
            |> EffectsLog.insert (Effects.none |> Effects.map MyWrapper)
            |> EffectsLog.httpAction "https://example.com/" "responseBody"
            |> Maybe.map snd
            |> assertEqual Nothing
            |> test "resolving a non-Http effect gives Nothing"
        ]
    ]
