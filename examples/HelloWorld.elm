module HelloWorld exposing (..)

import Testable.Html exposing (..)
import Testable exposing (..)
import Html


main : Html.Html msg
main =
    Testable.view view


view : Testable.Html.Html msg
view =
    text "Hello World!"
