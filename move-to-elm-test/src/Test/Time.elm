module Test.Time exposing (fromTask)

import Native.Test.Time
import Task exposing (Task)
import Time exposing (Time)


fromTask : Task x a -> Maybe (Time -> Task x a)
fromTask =
    Native.Test.Time.fromTask
