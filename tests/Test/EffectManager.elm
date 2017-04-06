effect module Test.EffectManager where { command = MyCmd, subscription = MySub } exposing (..)

import Task as Task exposing (Task)


type MyCmd msg
    = GetState (String -> msg)


getState : (String -> msg) -> Cmd msg
getState tagger =
    command (GetState tagger)


cmdMap : (a -> b) -> MyCmd a -> MyCmd b
cmdMap f cmd =
    case cmd of
        GetState tagger ->
            GetState (tagger >> f)


type MySub msg
    = SubState (String -> msg)


subState : (String -> msg) -> Sub msg
subState tagger =
    subscription (SubState tagger)


subMap : (a -> b) -> MySub a -> MySub b
subMap f sub =
    case sub of
        SubState tagger ->
            SubState (tagger >> f)


type alias State =
    String


type alias SelfMsg =
    Never


init : Task Never State
init =
    Task.succeed "INIT"


onEffects : Platform.Router msg SelfMsg -> List (MyCmd msg) -> List (MySub msg) -> State -> Task Never State
onEffects router cmds subs state =
    cmds
        |> List.map (\(GetState msg) -> Platform.sendToApp router <| msg ("(" ++ state ++ ")"))
        |> Task.sequence
        |> Task.map (always state)


onSelfMsg : Platform.Router msg SelfMsg -> SelfMsg -> State -> Task Never State
onSelfMsg router msg state =
    Task.succeed state
