module Testable.Effects.Internal (..) where

import Http


type Effects action
  = None
  | HttpEffect Http.Request (Result Http.RawError Http.Response -> action)
  | Batch (List (Effects action))
