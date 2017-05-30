effect module Test.EffectManager where { command = MyCmd, subscription = MySub } exposing (..)

import Task as Task exposing (Task)


type MyCmd msg
    = GetState (String -> msg)
    | PingSubs
    | UpdateSelf String


getState : (String -> msg) -> Cmd msg
getState tagger =
    command (GetState tagger)


pingSubs : Cmd msg
pingSubs =
    command PingSubs


updateSelf : String -> Cmd msg
updateSelf msg =
    command (UpdateSelf msg)


cmdMap : (a -> b) -> MyCmd a -> MyCmd b
cmdMap f cmd =
    case cmd of
        GetState tagger ->
            GetState (tagger >> f)

        PingSubs ->
            PingSubs

        UpdateSelf msg ->
            UpdateSelf msg


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
    String


init : Task Never State
init =
    Task.succeed "INIT"


onEffects : Platform.Router msg SelfMsg -> List (MyCmd msg) -> List (MySub msg) -> State -> Task Never State
onEffects router cmds subs state =
    let
        task cmd =
            case cmd of
                GetState tagger ->
                    Platform.sendToApp router <| tagger ("(" ++ state ++ ")")

                PingSubs ->
                    subs
                        |> List.map (\(SubState tagger) -> Platform.sendToApp router <| tagger ("[" ++ state ++ "]"))
                        |> Task.sequence
                        |> Task.map (always ())

                UpdateSelf msg ->
                    Platform.sendToSelf router msg
    in
    cmds
        |> List.map task
        |> Task.sequence
        |> Task.map (always state)


onSelfMsg : Platform.Router msg SelfMsg -> SelfMsg -> State -> Task Never State
onSelfMsg router msg state =
    Task.succeed (state ++ ";" ++ msg)
