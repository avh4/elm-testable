module Testable.EffectsLogTests exposing (..)

import ElmTest exposing (..)
import Testable.Cmd
import Testable.EffectsLog as EffectsLog exposing (EffectsLog)
import Testable.Http as Http
import Testable.Task as Task


type MyWrapper a
    = MyWrapper a


httpGetAction : String -> String -> EffectsLog action -> Maybe ( EffectsLog action, List action )
httpGetAction url responseBody =
    EffectsLog.httpAction
        { verb = "GET"
        , headers = []
        , url = url
        , body = Http.empty
        }
        (Http.ok responseBody)


all : Test
all =
    suite "Testable.EffectsLog"
        [ suite "resulting actions"
            [ EffectsLog.empty
                |> EffectsLog.insert (Http.getString "https://example.com/" |> Task.perform Err Ok)
                |> fst
                |> httpGetAction "https://example.com/" "responseBody"
                |> Maybe.map snd
                |> assertEqual (Just [ Ok "responseBody" ])
                |> test "directly consuming the result"
            , EffectsLog.empty
                |> EffectsLog.insert (Http.getString "https://example.com/" |> Task.perform (Err >> MyWrapper) (Ok >> MyWrapper))
                |> fst
                |> httpGetAction "https://example.com/" "responseBody"
                |> Maybe.map snd
                |> assertEqual (Just [ MyWrapper <| Ok "responseBody" ])
                |> test "mapping the result"
            , EffectsLog.empty
                |> EffectsLog.insert (Http.getString "https://example.com/" |> Task.perform Err Ok)
                |> fst
                |> httpGetAction "https://XXXX/" "responseBody"
                |> Maybe.map snd
                |> assertEqual Nothing
                |> test "resolving a request that doesn't match gives Nothing"
            , EffectsLog.empty
                |> EffectsLog.insert (Testable.Cmd.none |> Testable.Cmd.map MyWrapper)
                |> fst
                |> httpGetAction "https://example.com/" "responseBody"
                |> Maybe.map snd
                |> assertEqual Nothing
                |> test "resolving a non-Http effect gives Nothing"
            ]
        ]
