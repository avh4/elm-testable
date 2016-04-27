module Testable.Effects (Effects(..), none, batch, http, map) where


type Effects action
  = None
  | HttpGet String (String -> action)
  | Batch (List (Effects action))


none : Effects never
none =
  None


batch : List (Effects action) -> Effects action
batch effectsList =
  Batch effectsList


http : String -> Effects String
http url =
  HttpGet url identity


map : (a -> b) -> Effects a -> Effects b
map f source =
  case source of
    None ->
      None

    HttpGet url mapResponse ->
      HttpGet url (mapResponse >> f)

    Batch list ->
      Batch (List.map (map f) list)
