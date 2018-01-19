module Test.Http exposing (fromTask)

import Http
import Native.Test.Http
import Task exposing (Task)


type alias Request x a =
    { url : String
    , method : String
    , callback : Result Http.Error String -> Task x a
    }


fromTask : Task x a -> Maybe (Request x a)
fromTask =
    Native.Test.Http.fromTask
