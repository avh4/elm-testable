module Testable.Html.Internal exposing (..)

import Html as PlatformHtml


type Node msg
    = Text String


toPlatformHtml : Node msg -> PlatformHtml.Html msg
toPlatformHtml node =
    case node of
        Text value ->
            PlatformHtml.text value
