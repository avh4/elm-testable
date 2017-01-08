module Testable.Html exposing (Html, text, toPlatformHtml)

import Html as PlatformHtml


type alias Html msg =
    Node msg


type Node msg
    = Text String


text : String -> Html msg
text =
    Text


toPlatformHtml : Html msg -> PlatformHtml.Html msg
toPlatformHtml node =
    case node of
        Text value ->
            PlatformHtml.text value
