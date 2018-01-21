module Test.Http exposing (fromCmd, fromTask, map)

import Http
import Native.Test.Http
import Task exposing (Task)


type alias Request outcome =
    { url : String
    , method : String
    , callback : Result Http.Error String -> outcome
    }


map : (a -> b) -> Request a -> Request b
map f request =
    { request | callback = request.callback >> f }


{-| Gives information about whether a Task would initiate an Http request.
This will return information about the request if the given Task was made with
`Http.toTask` (possibly also transformed using `map`, `andThen`, `onError`).
This will return `Nothing` if the given Task is any other kind of task.
-}
fromTask : Task x a -> Maybe (Request (Task x a))
fromTask =
    Native.Test.Http.fromTask


{-| Returns the Requests for every `Http.send` that would be initiated by the given Cmd.
-}
fromCmd : Cmd msg -> List (Request msg)
fromCmd =
    Native.Test.Http.fromCmd
