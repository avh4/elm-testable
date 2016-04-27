module Testable (effects, task, init, update) where

import Effects
import Http
import Task
import Testable.Effects
import Testable.Internal as Internal
import Testable.Task


effects : Testable.Effects.Effects action -> Effects.Effects action
effects testableEffects =
  case testableEffects of
    Internal.None ->
      Effects.none

    Internal.TaskEffect testableTask ->
      Effects.task (task testableTask)

    Internal.Batch list ->
      Effects.batch (List.map effects list)


task : Testable.Task.Task error success -> Task.Task error success
task testableTask =
  case testableTask of
    Internal.HttpTask resuest mapResponse ->
      Http.send Http.defaultSettings resuest
        |> Task.toResult
        |> Task.map mapResponse
        |> (flip Task.andThen) Task.fromResult


init : ( model, Testable.Effects.Effects action ) -> ( model, Effects.Effects action )
init ( model, testableEffects ) =
  ( model, effects testableEffects )


update : (action -> model -> ( model, Testable.Effects.Effects action )) -> (action -> model -> ( model, Effects.Effects action ))
update fn action model =
  fn action model
    |> init
