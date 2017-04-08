module DefaultDict exposing (DefaultDict, empty, insert, update, get, toList)

import Dict exposing (Dict)


type DefaultDict key value
    = DD value (Dict key value)


empty : value -> DefaultDict key value
empty default =
    DD default Dict.empty


insert : comparable -> value -> DefaultDict comparable value -> DefaultDict comparable value
insert key value (DD default dict) =
    DD default (Dict.insert key value dict)


update : comparable -> (value -> value) -> DefaultDict comparable value -> DefaultDict comparable value
update key f (DD default dict) =
    DD default (Dict.update key (Maybe.withDefault default >> f >> Just) dict)


get : comparable -> DefaultDict comparable value -> value
get key (DD default dict) =
    Dict.get key dict
        |> Maybe.withDefault default


toList : DefaultDict comparable value -> List ( comparable, value )
toList (DD _ dict) =
    Dict.toList dict
