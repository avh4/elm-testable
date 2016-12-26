module Testable.Internal exposing (..)

import Time exposing (Time)
import Platform.Cmd
import Http


type Cmd msg
    = None
    | TaskCmd (Task msg msg)
    | Batch (List (Cmd msg))
    | WrappedCmd (Platform.Cmd.Cmd msg)


type alias Settings =
    { method : String
    , headers : List Http.Header
    , url : String
    , body : Http.Body
    , timeout : Maybe Time
    , withCredentials : Bool
    }


type Request success
    = HttpRequest Settings (Result Http.Error (Http.Response String) -> TaskResult Http.Error success)


type Task error success
    = HttpTask Settings (Result Http.Error (Http.Response String) -> TaskResult error success)
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
