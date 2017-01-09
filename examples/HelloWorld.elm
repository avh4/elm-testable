module HelloWorld exposing (..)

import Testable.Html exposing (..)
import Testable exposing (..)
import Html


main : Html.Html msg
main =
    Testable.view (always view) ()


view : Testable.Html.Html msg
view =
    text "Hello World!"
