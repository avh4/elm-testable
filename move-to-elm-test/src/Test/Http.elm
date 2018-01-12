module Test.Http exposing (fromTask)

import Http
import Native.Test.Http
import Task


type alias Request =
    { url : String
    , method : String
    }


fromTask : Task.Task x a -> Maybe Request
fromTask =
    Native.Test.Http.fromTask
