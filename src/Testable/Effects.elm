module Testable.Effects (Never, Effects, none, task, batch, map) where

import Effects as RealEffects
import Testable.Internal as Internal
import Testable.Task as Task exposing (Task)


type alias Never =
  RealEffects.Never


type alias Effects action =
  Internal.Effects action


none : Effects never
none =
  Internal.None


task : Task Never a -> Effects a
task wrapped =
  Internal.TaskEffect wrapped


batch : List (Effects action) -> Effects action
batch effectsList =
  Internal.Batch effectsList


map : (a -> b) -> Effects a -> Effects b
map f source =
  case source of
    Internal.None ->
      Internal.None

    Internal.TaskEffect wrapped ->
      Internal.TaskEffect (Task.map f wrapped)

    Internal.Batch list ->
      Internal.Batch (List.map (map f) list)
