module Test.Task exposing (resolvedTask)

import Native.Test.Task
import Task


resolvedTask : Task.Task x a -> Maybe (Result x a)
resolvedTask =
    Native.Test.Task.resolvedTask
