module Testable.Task
    exposing
        ( fromPlatformTask
        , Task(..)
        )

{-|
`Testable.Task` can be generated from a elm-lang/core Task and is used
internally by elm-testable to inspect and simulate Tasks.

# Inspecting elm-lang/core tasks
@docs fromPlatformTask, Task, Binding


# Unnecessary implementation

The following are all an unnecessary reimplementation of most of the Task API.
This is here simply as a helpful check to make sure everything compiles and
makes sense when refactoring Testable.Task.

## Basics
@docs Task, succeed, fail

## Mapping
@docs map

## Chaining
@docs andThen

## Errors
@docs mapError, toMaybe, toResult

## Threads
@docs sleep
-}

import Native.Testable.Task
import Time exposing (Time)
import Task as PlatformTask
import Http


-- This "unused" import is required because Native.Testable.Task needs
-- it at runtime:

import Process


fromPlatformTask : PlatformTask.Task x a -> Task x a
fromPlatformTask =
    Native.Testable.Task.fromPlatformTask


{-| Testable.Task values represent the possible future values of a Task, in
contrast to elm-lang/core Tasks, which store functions that will be evaluated
later.
-}
type Task error success
    = Success success
    | Failure error
    | SleepTask Time (Task error success)
    | HttpTask { method : String, url : String } (Http.Response String -> Task error success)
    | MockTask String


{-| A task that succeeds immediately when run.

    succeed 42    -- results in 42
-}
succeed : a -> Task x a
succeed value =
    Success value


{-| A task that fails immediately when run.

    fail "file not found" : Task String a
-}
fail : x -> Task x a
fail error =
    Failure error


{-| Transform a task.

    map sqrt (succeed 9) == succeed 3
-}
map : (a -> b) -> Task x a -> Task x b
map f source =
    case source of
        Success a ->
            Success (f a)

        Failure x ->
            Failure x

        MockTask tag ->
            MockTask tag

        SleepTask time next ->
            SleepTask time (next |> map f)

        HttpTask options next ->
            HttpTask options (next >> map f)



-- Chaining


{-| Chain together a task and a callback. The first task will run, and if it is
successful, you give the result to the callback resulting in another task. This
task then gets run.

    succeed 2 |> andThen (\n -> succeed (n + 2)) == succeed 4

This is useful for chaining tasks together. Maybe you need to get a user from
your servers *and then* lookup their picture once you know their name.
-}
andThen : (a -> Task x b) -> Task x a -> Task x b
andThen f source =
    case source of
        Success a ->
            f a

        Failure x ->
            Failure x

        MockTask tag ->
            MockTask tag

        SleepTask time next ->
            SleepTask time (next |> andThen f)

        HttpTask options next ->
            HttpTask options (next >> andThen f)



-- Errors


{-| Transform the error value. This can be useful if you need a bunch of error
types to match up.

    type Error = Http Http.Error | WebGL WebGL.Error

    getResources : Task Error Resource
    getResources =
        sequence [ mapError Http serverTask, mapError WebGL textureTask ]
-}
mapError : (x -> y) -> Task x a -> Task y a
mapError f source =
    case source of
        Success a ->
            Success a

        Failure x ->
            Failure (f x)

        MockTask tag ->
            MockTask tag

        SleepTask time next ->
            SleepTask time (next |> mapError f)

        HttpTask options next ->
            HttpTask options (next >> mapError f)


{-| Helps with handling failure. Instead of having a task fail with some value
of type `x` it promotes the failure to a `Nothing` and turns all successes into
`Just` something.

    toMaybe (fail "file not found") == succeed Nothing
    toMaybe (succeed 42)            == succeed (Just 42)

This means you can handle the error with the `Maybe` module instead.
-}
toMaybe : Task x a -> Task never (Maybe a)
toMaybe source =
    (toResult >> map Result.toMaybe) source


{-| Helps with handling failure. Instead of having a task fail with some value
of type `x` it promotes the failure to an `Err` and turns all successes into
`Ok` something.

    toResult (fail "file not found") == succeed (Err "file not found")
    toResult (succeed 42)            == succeed (Ok 42)

This means you can handle the error with the `Result` module instead.
-}
toResult : Task x a -> Task never (Result x a)
toResult source =
    case source of
        Success a ->
            Success (Ok a)

        Failure x ->
            Success (Err x)

        MockTask tag ->
            MockTask tag

        SleepTask time next ->
            SleepTask time (next |> toResult)

        HttpTask options next ->
            HttpTask options (next >> toResult)



-- Threads


{-| Make a thread sleep for a certain amount of time. The following example
sleeps for 1 second and then succeeds with 42.

    sleep 1000 |> andThen \_ -> succeed 42
-}
sleep : Time -> Task never ()
sleep milliseconds =
    SleepTask milliseconds (Success ())
