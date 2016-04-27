module Main (..) where

import Effects exposing (Never)
import RandomGif exposing (init, update, view)
import StartApp
import Task
import Testable


app =
  StartApp.start
    { init = Testable.init <| init "dc6zaTOxFJmzC" "funny cats"
    , update = Testable.update update
    , view = view
    , inputs = []
    }


main =
  app.html


port tasks : Signal (Task.Task Never ())
port tasks =
  app.tasks
