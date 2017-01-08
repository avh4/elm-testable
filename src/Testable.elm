module Testable exposing (cmd, task, init, update, view)

{-|

This module converts Testable things into real things.

# Basics
@docs cmd, task

# StartApp helpers
@docs init, update, view

-}

import Http
import Process
import Task
import Html
import Testable.Cmd
import Testable.Internal as Internal
import Testable.Task
import Testable.Html


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
            Task.perform identity (task testableTask)

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
        Internal.HttpTask settings taskOnError taskOnSuccess ->
            let
                request =
                    Http.request
                        { method = settings.method
                        , headers = settings.headers
                        , url = settings.url
                        , body = settings.body
                        , expect = Http.expectStringResponse Ok
                        , timeout = settings.timeout
                        , withCredentials = settings.withCredentials
                        }

                task =
                    Http.toTask request
            in
                task
                    |> Task.andThen (taskOnSuccess >> Task.succeed)
                    |> Task.onError (taskOnError >> Task.succeed)
                    |> Task.andThen (taskResult)

        Internal.ImmediateTask result ->
            taskResult result

        Internal.SleepTask milliseconds result ->
            Process.sleep milliseconds
                |> Task.andThen (\_ -> taskResult result)


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


{-| Converts a testable Html into a standard Html function
-}
view : Testable.Html.Html msg -> Html.Html msg
view =
    Testable.Html.toPlatformHtml
