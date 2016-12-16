module Main exposing (..)

import Html
import RandomGif exposing (init, update, view)


main : Program Never RandomGif.Model RandomGif.Msg
main =
    Html.program
        { init = init "dc6zaTOxFJmzC" "funny cats"
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }
