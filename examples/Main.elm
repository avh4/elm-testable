module Main exposing (..)

import Html.App
import RandomGif exposing (init, update, view)
import Task


-- import Testable


main =
  Html.App.program
    { init = init "dc6zaTOxFJmzC" "funny cats"
    , update = update
    , view = view
    , subscriptions = always Sub.none
    }
