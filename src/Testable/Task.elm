module Testable.Task
    exposing
        ( ProcessId(..)
        , Task(..)
        , andThen
        , fromPlatformTask
        , map
        , mapError
        )

{-| `Testable.Task` can be generated from a elm-lang/core Task and is used
internally by elm-testable to inspect and simulate Tasks.


# Inspecting elm-lang/core tasks

@docs fromPlatformTask, Task, ProcessId


## Basics

@docs map, andThen, mapError

-}

import Mapper exposing (Mapper)
import Native.Testable.Task
import
    -- This "unused" import is required because Native.Testable.Task needs
    -- it at runtime:
    Process
import Task as PlatformTask
import Test.Http
import Test.Time
import Testable.EffectManager as EffectManager
import Time exposing (Time)
import WebSocket.LowLevel


fromPlatformTask : PlatformTask.Task x a -> Task x a
fromPlatformTask task =
    List.filterMap (\f -> f task)
        [ Test.Http.fromTask
            >> Maybe.map (Test.Http.map fromPlatformTask >> Http_NativeHttp_toTask)
        , Test.Time.fromTask
            >> Maybe.map (\f -> Core_Time_now (f >> fromPlatformTask))
        ]
        |> List.head
        |> Maybe.withDefault (Native.Testable.Task.fromPlatformTask task)


type ProcessId
    = ProcessId Int


{-| Testable.Task values represent the possible future values of a Task, in
contrast to elm-lang/core Tasks, which store functions that will be evaluated
later.
-}
type Task error success
    = Success success
    | Failure error
      -- Special task types that elm-testable uses internally
    | IgnoredTask
    | MockTask String (Mapper (Task error success))
    | ToApp EffectManager.AppMsg (Task error success)
    | ToEffectManager String EffectManager.SelfMsg (Task error success)
    | NewEffectManagerState String String EffectManager.State -- first String is for debugging
      -- Native binding tasks in elm-lang/core
    | Core_NativeScheduler_sleep Time (() -> Task error success)
    | Core_NativeScheduler_spawn (Task Never Never) (ProcessId -> Task error success)
    | Core_NativeScheduler_kill ProcessId (Task error success)
    | Core_Time_now (Time -> Task error success)
    | Core_Time_setInterval Time (Task Never ())
      -- Native binding tasks in elm-lang/http
    | Http_NativeHttp_toTask (Test.Http.Request (Task error success))
      -- Native bindings for tasks in elm-lang/Websocket
    | WebSocket_NativeWebSocket_open String WebSocket.LowLevel.Settings (Result WebSocket.LowLevel.BadOpen () -> Task error success)
    | WebSocket_NativeWebSocket_send String String (Maybe WebSocket.LowLevel.BadSend -> Task error success)


{-| Transform a task.

    map sqrt (succeed 9) == succeed 3

-}
map : (a -> b) -> Task x a -> Task x b
map f source =
    andThen (f >> Success) source



-- Chaining


{-| Chain together a task and a callback. The first task will run, and if it is
successful, you give the result to the callback resulting in another task. This
task then gets run.

    succeed 2 |> andThen (\n -> succeed (n + 2)) == succeed 4

This is useful for chaining tasks together. Maybe you need to get a user from
your servers _and then_ lookup their picture once you know their name.

-}
andThen : (a -> Task x b) -> Task x a -> Task x b
andThen f source =
    case source of
        Success a ->
            f a

        Failure x ->
            Failure x

        IgnoredTask ->
            IgnoredTask

        MockTask tag mapper ->
            MockTask tag (mapper |> Mapper.map (andThen f))

        ToApp msg next ->
            ToApp msg (next |> andThen f)

        ToEffectManager home msg next ->
            ToEffectManager home msg (next |> andThen f)

        NewEffectManagerState junk home msg ->
            NewEffectManagerState junk home msg

        Core_NativeScheduler_sleep time next ->
            Core_NativeScheduler_sleep time (next >> andThen f)

        Core_NativeScheduler_spawn task next ->
            Core_NativeScheduler_spawn task (next >> andThen f)

        Core_NativeScheduler_kill processId next ->
            Core_NativeScheduler_kill processId (next |> andThen f)

        Core_Time_now next ->
            Core_Time_now (next >> andThen f)

        Core_Time_setInterval delay task ->
            Core_Time_setInterval delay task

        Http_NativeHttp_toTask request ->
            Http_NativeHttp_toTask (Test.Http.map (andThen f) request)

        WebSocket_NativeWebSocket_open url settings next ->
            WebSocket_NativeWebSocket_open url settings (next >> andThen f)

        WebSocket_NativeWebSocket_send url string next ->
            WebSocket_NativeWebSocket_send url string (next >> andThen f)



-- Errors


{-| Transform the error value. This can be useful if you need a bunch of error
types to match up.

    type Error
        = Http Http.Error
        | WebGL WebGL.Error

    getResources : Task Error Resource
    getResources =
        sequence [ mapError Http serverTask, mapError WebGL textureTask ]

-}
mapError : (x -> y) -> Task x a -> Task y a
mapError f =
    onError (f >> Failure)


onError : (x -> Task y a) -> Task x a -> Task y a
onError f source =
    case source of
        Success a ->
            Success a

        Failure x ->
            f x

        IgnoredTask ->
            IgnoredTask

        MockTask tag mapper ->
            MockTask tag (mapper |> Mapper.map (onError f))

        ToApp msg next ->
            ToApp msg (next |> onError f)

        ToEffectManager home msg next ->
            ToEffectManager home msg (next |> onError f)

        NewEffectManagerState junk home msg ->
            NewEffectManagerState junk home msg

        Core_NativeScheduler_sleep time next ->
            Core_NativeScheduler_sleep time (next >> onError f)

        Core_NativeScheduler_spawn task next ->
            Core_NativeScheduler_spawn task (next >> onError f)

        Core_NativeScheduler_kill processId next ->
            Core_NativeScheduler_kill processId (next |> onError f)

        Core_Time_now next ->
            Core_Time_now (next >> onError f)

        Core_Time_setInterval delay task ->
            Core_Time_setInterval delay task

        Http_NativeHttp_toTask request ->
            Http_NativeHttp_toTask (Test.Http.map (onError f) request)

        WebSocket_NativeWebSocket_open url settings next ->
            WebSocket_NativeWebSocket_open url settings (next >> onError f)

        WebSocket_NativeWebSocket_send url string next ->
            WebSocket_NativeWebSocket_send url string (next >> onError f)
