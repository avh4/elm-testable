module Testable.Html exposing (Html, text, div, input, button)

import Testable.Html.Internal exposing (Node(..))


type alias Html msg =
    Node msg


type alias Attribute msg =
    Testable.Html.Internal.Attribute msg


text : String -> Html msg
text =
    Text


div : List (Attribute msg) -> List (Node msg) -> Html msg
div =
    Node "div"


input : List (Attribute msg) -> List (Node msg) -> Html msg
input =
    Node "input"


button : List (Attribute msg) -> List (Node msg) -> Html msg
button =
    Node "button"
