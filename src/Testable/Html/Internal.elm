module Testable.Html.Internal exposing (..)

import Html as PlatformHtml
import Html.Events as PlatformEvents
import Json.Decode as Json
import Testable.Html.Selector exposing (Selector(..))


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


nodeMatchesSelector : Node msg -> Selector -> Bool
nodeMatchesSelector node selector =
    case node of
        Node type_ attributes children ->
            case selector of
                Tag expectedType ->
                    type_ == expectedType

        Text _ ->
            False


isJust : Maybe a -> Bool
isJust maybe =
    case maybe of
        Just _ ->
            True

        Nothing ->
            False


findNode : List Selector -> Node msg -> Maybe (Node msg)
findNode query node =
    case node of
        Node type_ attributes children ->
            let
                nodeMatches =
                    List.map (nodeMatchesSelector node) query
                        |> (::) True
                        |> List.all identity
            in
                if nodeMatches then
                    Just node
                else
                    List.map (findNode query) children
                        |> List.filter isJust
                        |> List.head
                        |> Maybe.withDefault Nothing

        Text _ ->
            if List.isEmpty query then
                Just node
            else
                Nothing
