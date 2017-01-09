module Testable.Html.Events exposing (on, onClick, onInput)

import Testable.Html.Internal exposing (Attribute(..))
import Json.Decode as Json


on : String -> Json.Decoder msg -> Attribute msg
on =
    On


onClick : msg -> Attribute msg
onClick msg =
    on "click" (Json.succeed msg)


onInput : (String -> msg) -> Attribute msg
onInput tagger =
    on "input" (Json.map tagger targetValue)


targetValue : Json.Decoder String
targetValue =
    Json.at [ "target", "value" ] Json.string
