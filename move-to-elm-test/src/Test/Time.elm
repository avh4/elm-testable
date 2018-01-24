module Test.Time exposing (fromTask)

import Native.Test.Time
import Task exposing (Task)
import Time exposing (Time)


{-| Gives information about whether a Task is a `Time.now` task
(possibly also transformed using `map`, `andThen`, `onError`).
This will return `Just` with the callback function for such a task
and will return `Nothing` if the given Task is any other kind of task.
-}
fromTask : Task x a -> Maybe (Time -> Task x a)
fromTask =
    Native.Test.Time.fromTask
