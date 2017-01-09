module Testable.Html.Selector exposing (..)


type Selector
    = Tag String


tag : String -> Selector
tag =
    Tag
