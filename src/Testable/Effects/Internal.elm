module Testable.Effects.Internal (..) where

import Http


type Effects action
  = None
  | HttpEffect Http.Request (String -> action)
  | Batch (List (Effects action))
