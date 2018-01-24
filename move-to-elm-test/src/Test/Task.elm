module Test.Task exposing (resolvedTask)

import Native.Test.Task
import Task


{-| Gives information about whether a Task is a `Task.succeed` or `Task.fail`
(possibly also transformed using `map`, `andThen`, `onError`).
This will return `Just (Ok a)` if such a task resolves to succed,
`Just (Err x)` if such a task resolves to an error,
and `Nothing` if the given Task is any other kind of task.
-}
resolvedTask : Task.Task x a -> Maybe (Result x a)
resolvedTask =
    Native.Test.Task.resolvedTask
