module Testable.Task exposing (Task, succeed, fail, map, andThen, sequence, onError, mapError, perform, attempt)

{-|
`Testable.Task` is a replacement for the core `Task` module.  You can use it
to create components that can be tested with `Testable.TestContext`.  You can
convert `Testable.Task` into a core `Task` with the `Testable` module.

# Basics
@docs Task, succeed, fail

# Mapping
@docs map

# Chaining
@docs andThen, sequence

# Errors
@docs onError, mapError

# Commands
@docs perform, attempt
-}

import Testable.Internal as Internal exposing (TaskResult(..))


{-| Represents asynchronous effects that may fail. It is useful for stuff like
HTTP.
For example, maybe we have a task with the type (`Task String User`). This means
that when we perform the task, it will either fail with a `String` message or
succeed with a `User`. So this could represent a task that is asking a server
for a certain user.
-}
type alias Task error success =
    Internal.Task error success


{-| A task that succeeds immediately when run.

    succeed 42    -- results in 42
-}
succeed : a -> Task x a
succeed value =
    Internal.ImmediateTask (Success value)


{-| A task that fails immediately when run.

    fail "file not found" : Task String a
-}
fail : x -> Task x a
fail error =
    Internal.ImmediateTask (Failure error)


{-| Transform a task.

    map sqrt (succeed 9) == succeed 3
-}
map : (a -> b) -> Task x a -> Task x b
map f source =
    transform (resultMap f) source



-- Chaining


{-| Chain together a task and a callback. The first task will run, and if it is
successful, you give the result to the callback resulting in another task. This
task then gets run.

    succeed 2 |> andThen (\n -> succeed (n + 2)) == succeed 4

This is useful for chaining tasks together. Maybe you need to get a user from
your servers *and then* lookup their picture once you know their name.
-}
andThen : (a -> Task x b) -> Task x a -> Task x b
andThen next source =
    transform (resultAndThen next) source


{-| Start with a list of tasks, and turn them into a single task that returns a list. The tasks will be run in order one-by-one and if any task fails the whole sequence fails.

    sequence [ succeed 1, succeed 2 ] -- succeed [ 1, 2 ]

This can be useful if you need to make a bunch of HTTP requests one-by-one.}
-}
sequence : List (Task x a) -> Task x (List a)
sequence list =
    case list of
        task :: nextTasks ->
            task
                |> andThen
                    (\value ->
                        (sequence nextTasks)
                            |> andThen
                                (\nextValue -> succeed (value :: nextValue))
                    )

        [] ->
            succeed []



-- Errors


{-| Recover from a failure in a task. If the given task fails, we use the callback to recover.
-}
onError : (x -> Task y a) -> Task x a -> Task y a
onError f task =
    case task of
        Internal.HttpTask settings onError onSuccess ->
            Internal.HttpTask settings (onError >> resultOnError f) (onSuccess >> resultOnError f)

        Internal.ImmediateTask response ->
            Internal.ImmediateTask (resultOnError f response)

        Internal.SleepTask milliseconds response ->
            Internal.SleepTask milliseconds (resultOnError f response)


{-| Transform the error value. This can be useful if you need a bunch of error
types to match up.

    type Error = Http Http.Error | WebGL WebGL.Error

    getResources : Task Error Resource
    getResources =
        sequence [ mapError Http serverTask, mapError WebGL textureTask ]
-}
mapError : (x -> y) -> Task x a -> Task y a
mapError f task =
    transform
        (\res ->
            case res of
                Success value ->
                    Success value

                Failure error ->
                    Failure (f error)

                Continue next ->
                    Continue (mapError f next)
        )
        task


toResult : Task x a -> Task never (Result x a)
toResult source =
    transform resultToResult source


transform : (TaskResult x a -> TaskResult y b) -> Task x a -> Task y b
transform tx source =
    case source of
        Internal.HttpTask settings onError onSuccess ->
            Internal.HttpTask settings (onError >> tx) (onSuccess >> tx)

        Internal.ImmediateTask result ->
            Internal.ImmediateTask (result |> tx)

        Internal.SleepTask milliseconds result ->
            Internal.SleepTask milliseconds (result |> tx)



-- Commands


{-| The only way to do things in Elm is to give commands to the Elm runtime.
So we describe some complex behavior with a Task and then command the runtime to perform that task.
-}
perform : (a -> msg) -> Task Never a -> Internal.Cmd msg
perform onSuccess task =
    task
        |> toResult
        |> map
            (\res ->
                case res of
                    Ok value ->
                        onSuccess value

                    Err error ->
                        Debug.crash "Impossible to have an error on a Never Task"
            )
        |> Internal.TaskCmd


{-| Command the Elm runtime to attempt a task that might fail!
-}
attempt : (Result x a -> msg) -> Task x a -> Internal.Cmd msg
attempt f task =
    task
        |> toResult
        |> map f
        |> Internal.TaskCmd


resultMap : (a -> b) -> TaskResult x a -> TaskResult x b
resultMap f source =
    case source of
        Success value ->
            Success (f value)

        Failure error ->
            Failure error

        Continue next ->
            Continue (map f next)


resultOnError : (x -> Task y a) -> TaskResult x a -> TaskResult y a
resultOnError f source =
    case source of
        Success value ->
            Success value

        Failure error ->
            Continue (f error)

        Continue next ->
            Continue (onError f next)


resultAndThen : (a -> Task x b) -> TaskResult x a -> TaskResult x b
resultAndThen f source =
    case source of
        Success value ->
            Continue (f value)

        Failure error ->
            Failure error

        Continue next ->
            Continue (andThen f next)


resultToResult : TaskResult x a -> TaskResult never (Result x a)
resultToResult source =
    case source of
        Success value ->
            Success (Ok value)

        Failure error ->
            Success (Err error)

        Continue next ->
            Continue (toResult next)
