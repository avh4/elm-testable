module Testable (effects, task, init, update) where

{-|

This module converts Testable things into real things.

# Basics
@docs effects, task

# StartApp helpers
@docs init, update

-}

import Effects
import Http
import Task
import Testable.Effects
import Testable.Internal as Internal
import Testable.Task


{-| Converts a `Testable.Effects` into an `Effects`

    Testable.Effects.none |> Testable.effects
        == Effects.none
-}
effects : Testable.Effects.Effects action -> Effects.Effects action
effects testableEffects =
  case testableEffects of
    Internal.None ->
      Effects.none

    Internal.TaskEffect testableTask ->
      Effects.task (task testableTask)

    Internal.Batch list ->
      Effects.batch (List.map effects list)


{-| Converts a `Testable.Task` into an `Task`

    Testable.Task.succeed "A" |> Testable.task
        == Task.succeed "A"
-}
task : Testable.Task.Task error success -> Task.Task error success
task testableTask =
  case testableTask of
    Internal.HttpTask request mapResponse ->
      Http.send Http.defaultSettings request
        |> Task.toResult
        |> Task.map mapResponse
        |> (flip Task.andThen) taskResult

    Internal.ImmediateTask result ->
      taskResult result


taskResult : Internal.TaskResult error success -> Task.Task error success
taskResult result =
  case result of
    Internal.Success action ->
      Task.succeed action

    Internal.Failure error ->
      Task.fail error

    Internal.Continue next ->
      task next


{-| Converts a testable StartApp-style init value into a standard StartApp init value
-}
init : ( model, Testable.Effects.Effects action ) -> ( model, Effects.Effects action )
init ( model, testableEffects ) =
  ( model, effects testableEffects )


{-| Converts a testable StartApp-style update function into a standard StartApp update function
-}
update : (action -> model -> ( model, Testable.Effects.Effects action )) -> (action -> model -> ( model, Effects.Effects action ))
update fn action model =
  fn action model
    |> init
