module Testable exposing (cmd, task, init, update)

{-|

This module converts Testable things into real things.

# Basics
@docs cmd, task

# StartApp helpers
@docs init, update

-}

import Http
import Process
import Task
import Testable.Cmd
import Testable.Internal as Internal
import Testable.Task


{-| Converts a `Testable.Cmd` into a `Cmd`

    Testable.Cmd.none |> Testable.cmd
        == Cmd.none
-}
cmd : Testable.Cmd.Cmd msg -> Cmd msg
cmd testableEffects =
    case testableEffects of
        Internal.None ->
            Cmd.none

        Internal.TaskCmd testableTask ->
            Task.perform identity identity (task testableTask)

        Internal.Batch list ->
            Cmd.batch (List.map cmd list)

        Internal.WrappedCmd cmd ->
            cmd


{-| Converts a `Testable.Task` into an `Task`

    Testable.Task.succeed "A" |> Testable.task
        == Task.succeed "A"
-}
task : Testable.Task.Task error success -> Task.Task error success
task testableTask =
    case testableTask of
        Internal.HttpTask settings request mapResponse ->
            let
                httpSettings =
                    { settings
                        | onStart = Maybe.map task settings.onStart
                        , onProgress = Maybe.map ((<<) task) settings.onProgress
                    }
            in
                Http.send httpSettings request
                    |> Task.toResult
                    |> Task.map mapResponse
                    |> (flip Task.andThen) taskResult

        Internal.ImmediateTask result ->
            taskResult result

        Internal.SleepTask milliseconds result ->
            Process.sleep milliseconds
                |> (flip Task.andThen) (\_ -> taskResult result)


taskResult : Internal.TaskResult error success -> Task.Task error success
taskResult result =
    case result of
        Internal.Success msg ->
            Task.succeed msg

        Internal.Failure error ->
            Task.fail error

        Internal.Continue next ->
            task next


{-| Converts a testable StartApp-style init value into a standard StartApp init value
-}
init : ( model, Testable.Cmd.Cmd msg ) -> ( model, Cmd msg )
init ( model, testableEffects ) =
    ( model, cmd testableEffects )


{-| Converts a testable StartApp-style update function into a standard StartApp update function
-}
update : (msg -> model -> ( model, Testable.Cmd.Cmd msg )) -> (msg -> model -> ( model, Cmd msg ))
update fn msg model =
    fn msg model
        |> init
