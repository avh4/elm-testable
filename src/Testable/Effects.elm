module Testable.Effects (Effects, none, batch, map) where

import Testable.Effects.Internal as Internal


type alias Effects action =
  Internal.Effects action


none : Effects never
none =
  Internal.None


batch : List (Effects action) -> Effects action
batch effectsList =
  Internal.Batch effectsList


map : (a -> b) -> Effects a -> Effects b
map f source =
  case source of
    Internal.None ->
      Internal.None

    Internal.HttpEffect request mapResponse ->
      Internal.HttpEffect request (mapResponse >> f)

    Internal.Batch list ->
      Internal.Batch (List.map (map f) list)
