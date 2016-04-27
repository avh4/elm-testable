module FakeDict (Dict, empty, insert, get, keys) where


type Dict key value
  = Dict (List ( key, value ))


empty : Dict key value
empty =
  Dict []


insert : key -> value -> Dict key value -> Dict key value
insert key value (Dict dict) =
  Dict (( key, value ) :: dict)


get : key -> Dict key value -> Maybe value
get expectedKey (Dict dict) =
  List.foldl
    (\( key, value ) prev ->
      case prev of
        Just found ->
          Just found

        _ ->
          if key == expectedKey then
            Just value
          else
            Nothing
    )
    Nothing
    dict


keys : Dict key value -> List key
keys (Dict dict) =
  dict |> List.map fst
