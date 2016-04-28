module Testable.Task (Task, succeed, fail, map, andThen, toMaybe, toResult) where

{-|
`Testable.Task` is a replacement for the core `Task` module.  You can use it
to create components that can be tested with `Testable.TestContext`.  You can
convert `Testable.Task` into a core `Task` with the `Testable` module.

# Basics
@docs Task, succeed, fail

# Mapping
@docs map

# Chaining
@docs andThen

# Errors
@docs toMaybe, toResult
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
  case source of
    Internal.HttpTask request mapResponse ->
      Internal.HttpTask request (mapResponse >> resultMap f)

    Internal.ImmediateTask result ->
      Internal.ImmediateTask (result |> resultMap f)



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
  case source of
    Internal.HttpTask request mapResponse ->
      Internal.HttpTask request (mapResponse >> resultAndThen next)

    Internal.ImmediateTask result ->
      Internal.ImmediateTask (result |> resultAndThen next)



-- Errors


{-| Helps with handling failure. Instead of having a task fail with some value
of type `x` it promotes the failure to a `Nothing` and turns all successes into
`Just` something.

    toMaybe (fail "file not found") == succeed Nothing
    toMaybe (succeed 42)            == succeed (Just 42)

This means you can handle the error with the `Maybe` module instead.
-}
toMaybe : Task x a -> Task never (Maybe a)
toMaybe source =
  case source of
    Internal.HttpTask request mapResponse ->
      Internal.HttpTask request (mapResponse >> resultToResult >> resultMap Result.toMaybe)

    Internal.ImmediateTask result ->
      Internal.ImmediateTask (result |> resultToResult >> resultMap Result.toMaybe)


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
    Internal.HttpTask request mapResponse ->
      Internal.HttpTask request (mapResponse >> resultToResult)

    Internal.ImmediateTask result ->
      Internal.ImmediateTask (result |> resultToResult)



-- TaskResult


resultMap : (a -> b) -> TaskResult x a -> TaskResult x b
resultMap f source =
  case source of
    Success value ->
      Success (f value)

    Failure error ->
      Failure error

    Continue next ->
      Continue (map f next)


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
