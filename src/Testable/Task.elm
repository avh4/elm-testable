module Testable.Task (Task, map, toMaybe, toResult) where

{-|
`Testable.Task` is a replacement for the core `Task` module.  You can use it
to create components that can be tested with `Testable.TestContext`.  You can
convert `Testable.Task` into a core `Task` with the `Testable` module.

# Basics
@docs Task

# Mapping
@docs map

# Errors
@docs toMaybe, toResult
-}

import Testable.Internal as Internal


{-| Represents asynchronous effects that may fail. It is useful for stuff like
HTTP.
For example, maybe we have a task with the type (`Task String User`). This means
that when we perform the task, it will either fail with a `String` message or
succeed with a `User`. So this could represent a task that is asking a server
for a certain user.
-}
type alias Task error success =
  Internal.Task error success


{-| Transform a task.

    map sqrt (succeed 9) == succeed 3
-}
map : (a -> b) -> Task x a -> Task x b
map f source =
  case source of
    Internal.HttpTask request mapResponse ->
      Internal.HttpTask request (mapResponse >> Result.map f)


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
      Internal.HttpTask request (mapResponse >> Result.toMaybe >> Ok)


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
      Internal.HttpTask request (mapResponse >> Ok)
