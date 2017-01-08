module Testable.Html exposing (Html, text)

import Testable.Html.Internal exposing (Node(..))


type alias Html msg =
    Node msg


text : String -> Html msg
text =
    Text
