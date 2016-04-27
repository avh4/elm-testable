module Testable.Effects (Never, Effects, none, task, batch, map) where

{-|
`Testable.Effects` is a replacement for the core `Effects` module.  You can use it
to create components that can be tested with `Testable.TestContext`.  You can
convert `Testable.Effects` into a core `Effects` with the `Testable` module.

# Basic Effects
@docs Effects, none, task

# Combining Effects
@docs map, batch

# Running Effects
@docs Never
-}

import Effects as RealEffects
import Testable.Internal as Internal
import Testable.Task as Task exposing (Task)


-- Basic Effects


{-| Represents some kind of effect. Right now this library supports tasks for
arbitrary effects and clock ticks for animations.
-}
type alias Effects action =
  Internal.Effects action


{-| The simplest effect of them all: don’t do anything! This is useful when
some branches of your update function request effects and others do not.

Example 5 in [elm-architecture-tutorial](https://github.com/evancz/elm-architecture-tutorial/)
has a nice example of this with further explanation in the tutorial itself.
-}
none : Effects never
none =
  Internal.None


{-| Turn a `Task` into an `Effects` that results in an `a` value.

Normally a `Task` has a error type and a success type. In this case the error
type is `Never` meaning that you must provide a task that never fails. Lots of
tasks can fail (like HTTP requests), so you will want to use `Task.toMaybe`
and `Task.toResult` to move potential errors into the success type so they can
be handled explicitly.

Example 5 in [elm-architecture-tutorial](https://github.com/evancz/elm-architecture-tutorial/)
has a nice example of this with further explanation in the tutorial itself.
-}
task : Task Never a -> Effects a
task wrapped =
  Internal.TaskEffect wrapped



-- Combining Effects


{-| Create a batch of effects. The following example requests two tasks: one
for the user’s picture and one for their age. You could put a bunch more stuff
in that batch if you wanted!

    init : String -> (Model, Effects Action)
    init userID =
        ( { id = userID
          , picture = Nothing
          , age = Nothing
          }
        , batch [ getPicture userID, getAge userID ]
        )

    -- getPicture : String -> Effects Action
    -- getAge : String -> Effects Action

Example 6 in [elm-architecture-tutorial](https://github.com/evancz/elm-architecture-tutorial/)
has a nice example of this with further explanation in the tutorial itself.
-}
batch : List (Effects action) -> Effects action
batch effectsList =
  Internal.Batch effectsList


{-| Transform the return type of a bunch of `Effects`. This is primarily useful
for adding tags to route `Actions` to the right place in The Elm Architecture.

Example 6 in [elm-architecture-tutorial](https://github.com/evancz/elm-architecture-tutorial/)
has a nice example of this with further explanation in the tutorial itself.
-}
map : (a -> b) -> Effects a -> Effects b
map f source =
  case source of
    Internal.None ->
      Internal.None

    Internal.TaskEffect wrapped ->
      Internal.TaskEffect (Task.map f wrapped)

    Internal.Batch list ->
      Internal.Batch (List.map (map f) list)



-- Running Effects


{-| A type that is "uninhabited". There are no values of type `Never`, so if
something has this type, it is a guarantee that it can never happen. It is
useful for demanding that a `Task` can never fail.
-}
type alias Never =
  RealEffects.Never
