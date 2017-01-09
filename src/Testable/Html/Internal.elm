module Testable.Html.Internal exposing (..)

import Html as PlatformHtml
import Html.Events as PlatformEvents
import Json.Decode as Json


type Node msg
    = Node String (List (Attribute msg)) (List (Node msg))
    | Text String


type Attribute msg
    = On String (Json.Decoder msg)


toPlatformHtml : Node msg -> PlatformHtml.Html msg
toPlatformHtml node =
    case node of
        Node type_ attributes children ->
            PlatformHtml.node type_ (List.map toPlatformAttribute attributes) (List.map toPlatformHtml children)

        Text value ->
            PlatformHtml.text value


toPlatformAttribute : Attribute msg -> PlatformHtml.Attribute msg
toPlatformAttribute attribute =
    case attribute of
        On event decoder ->
            PlatformEvents.on event decoder


nodeText : Node msg -> String
nodeText node =
    case node of
        Node _ _ children ->
            children
                |> List.map (nodeText)
                |> String.join ""

        Text nodeText ->
            nodeText
