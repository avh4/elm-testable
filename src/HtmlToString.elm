module HtmlToString exposing (..) -- where

import Html exposing (Html)

import String
import Dict exposing (Dict)
import Json.Decode
import Helpers exposing (..)
import InternalTypes exposing (..)


emptyFacts : Facts
emptyFacts =
    { styles = Dict.empty
    , events = Nothing
    , attributes = Nothing
    , attributeNamespace = Nothing
    , stringOthers = Dict.empty
    , boolOthers = Dict.empty
    }


{-| Convert a generic Html msg to a given NodeType. If we fail to parse,
fall back on a NoOp node type.
-}
nodeTypeFromHtml : Html msg -> NodeType
nodeTypeFromHtml =
    stringify
        >> Json.Decode.decodeString decodeNodeType
        >> Result.withDefault NoOp

{-| Convert a node record to a string. This basically takes the tag name, then
    pulls all the facts into tag declaration, then goes through the children and
    nests them undert hsi one
-}
nodeRecordToString : NodeRecord -> String
nodeRecordToString {tag, children, facts} =
    let
        openTag : List (Maybe String) -> String
        openTag extras =
            let
                trimmedExtras =
                    List.filterMap (\x -> x) extras
                        |> List.map String.trim
                        |> List.filter ((/=) "")

                filling =
                    case trimmedExtras of
                        [] -> ""
                        more ->
                            " " ++ (String.join " " more)
            in
                "<" ++ tag ++ filling ++ ">"

        closeTag =
            "</" ++ tag ++ ">"

        childrenStrings =
            List.map nodeTypeToString children
                |> String.join ""

        styles =
            case Dict.toList facts.styles of
                [] -> Nothing
                styles ->
                    styles
                        |> List.map (\(key, value) -> key ++ ":" ++ value)
                        |> String.join ""
                        |> (\styleString -> "style=\"" ++ styleString ++ "\"")
                        |> Just

        classes =
            Dict.get "className" facts.stringOthers
                |> Maybe.map (\name -> "class=\"" ++ name ++ "\"")

        stringOthers =
            Dict.filter (\k v -> k /= "className") facts.stringOthers
                |> Dict.toList
                |> List.map (\(k, v) -> k ++ "=\"" ++ v ++ "\"")
                |> String.join " "
                |> Just

        boolOthers =
            Dict.toList facts.boolOthers
                |> List.map (\(k, v) -> k ++ "=" ++ (String.toLower <| toString v))
                |> String.join " "
                |> Just

    in
        String.join ""
            [ openTag [ classes, styles, stringOthers, boolOthers ]
            , childrenStrings
            , closeTag
            ]

{-| Convert a given html node to a string based on the type
-}
nodeTypeToString : NodeType -> String
nodeTypeToString nodeType =
    case nodeType of
        TextTag {text} ->
            text
        NodeEntry record ->
            nodeRecordToString record
        NoOp ->
            ""

{-| Take a Html element, convert it to a string
Useful for tests
-}
htmlToString : Html msg -> String
htmlToString =
    nodeTypeFromHtml >> nodeTypeToString


first : (a -> Maybe b) -> List a -> Maybe b
first fn list =
    case list of
        [] ->
            Nothing

        next :: rest ->
            case fn next of
                Just result ->
                    Just result

                Nothing ->
                    first fn rest


matches : String -> NodeType -> Bool
matches selector node =
    case node of
        NodeEntry node' ->
            selector == node'.tag

        TextTag _ ->
            False

        NoOp ->
            False


triggerEvent : String -> Json.Decode.Value -> NodeType -> Result String msg
triggerEvent =
    Native.Helpers.triggerEvent


findOne : String -> NodeType -> Result String NodeType
findOne selector node =
    if matches selector node then
        Ok node
    else
        case node of
            NodeEntry node' ->
                first (findOne selector >> Result.toMaybe) node'.children
                    |> Result.fromMaybe ("No matches found for " ++ selector)

            TextTag _ ->
                Err ("No matches found for " ++ selector)

            NoOp ->
                Err ("No matches found for " ++ selector)
