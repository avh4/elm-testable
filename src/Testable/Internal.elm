module Testable.Internal (..) where

import Http
import Effects exposing (Never)
import Time exposing (Time)


type Effects action
  = None
  | TaskEffect (Task Never action)
  | Batch (List (Effects action))


type Task error success
  = HttpTask Http.Request (Result Http.RawError Http.Response -> TaskResult error success)
  | ImmediateTask (TaskResult error success)
  | SleepTask Time (TaskResult error success)


type TaskResult error success
  = Success success
  | Failure error
  | Continue (Task error success)


resultFromResult : Result x a -> TaskResult x a
resultFromResult result =
  case result of
    Ok value ->
      Success value

    Err error ->
      Failure error
