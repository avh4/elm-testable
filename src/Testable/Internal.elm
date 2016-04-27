module Testable.Internal (..) where

import Http
import Effects exposing (Never)


type Effects action
  = None
  | TaskEffect (Task Never action)
  | Batch (List (Effects action))


type Task error success
  = HttpTask Http.Request (Result Http.RawError Http.Response -> Result error success)
