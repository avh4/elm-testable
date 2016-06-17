module Testable.Internal exposing (..)

import Http
import Time exposing (Time)


type Cmd msg
    = None
    | TaskCmd (Task msg msg)
    | Batch (List (Cmd msg))


type Task error success
    = HttpTask Http.Settings Http.Request (Result Http.RawError Http.Response -> TaskResult error success)
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
