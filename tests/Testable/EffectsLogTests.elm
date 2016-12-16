module Testable.EffectsLogTests exposing (..)

import Expect
import Test exposing (..)
import Testable.Cmd
import Testable.EffectsLog as EffectsLog exposing (EffectsLog)
import Testable.Task as Task


type MyWrapper a
    = MyWrapper a


all : Test
all =
    describe "Testable.EffectsLog"
        [ describe "resulting msgs"
            [-- test "directly consuming the result" <|
             --     \() ->
             --         EffectsLog.empty
             --             |> EffectsLog.insert (Http.getString "https://example.com/" |> Task.perform Err Ok)
             --             |> Tuple.first
             --             |> httpGetMsg "https://example.com/" "responseBody"
             --             |> Maybe.map Tuple.second
             --             |> Expect.equal (Just [ Ok "responseBody" ])
             -- , test "mapping the result" <|
             --     \() ->
             --         EffectsLog.empty
             --             |> EffectsLog.insert (Http.getString "https://example.com/" |> Task.perform (Err >> MyWrapper) (Ok >> MyWrapper))
             --             |> Tuple.first
             --             |> httpGetMsg "https://example.com/" "responseBody"
             --             |> Maybe.map Tuple.second
             --             |> Expect.equal (Just [ MyWrapper <| Ok "responseBody" ])
             -- , test "resolving a request that doesn't match gives Nothing" <|
             --     \() ->
             --         EffectsLog.empty
             --             |> EffectsLog.insert (Http.getString "https://example.com/" |> Task.perform Err Ok)
             --             |> Tuple.first
             --             |> httpGetMsg "https://XXXX/" "responseBody"
             --             |> Maybe.map Tuple.second
             --             |> Expect.equal Nothing
             -- , test "resolving a non-Http effect gives Nothing" <|
             --   \() ->
             --       EffectsLog.empty
             --           |> EffectsLog.insert (Testable.Cmd.none |> Testable.Cmd.map MyWrapper)
             --           |> Tuple.first
             --           |> httpGetMsg "https://example.com/" "responseBody"
             --           |> Maybe.map Tuple.second
             --           |> Expect.equal Nothing
            ]
        ]
