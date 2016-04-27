module Testable.Task (Task, map, toResult) where

import Testable.Internal as Internal


type alias Task error success =
  Internal.Task error success


map : (a -> b) -> Task x a -> Task x b
map f source =
  case source of
    Internal.HttpTask request mapResponse ->
      Internal.HttpTask request (mapResponse >> Result.map f)


toResult : Task x a -> Task never (Result x a)
toResult source =
  case source of
    Internal.HttpTask request mapResponse ->
      Internal.HttpTask request (mapResponse >> Ok)
