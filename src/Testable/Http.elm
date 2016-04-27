module Testable.Http (getString, empty, Request, getRequest) where

import Http
import Testable.Effects as Effects exposing (Effects)
import Testable.Effects.Internal as Internal


getString : String -> Effects String
getString url =
  Internal.HttpEffect
    { verb = "GET"
    , headers = []
    , url = url
    , body = Http.empty
    }
    identity



-- Body Values


empty : Http.Body
empty =
  Http.empty



-- Arbitrary Requests


type alias Request =
  Http.Request


getRequest : String -> Request
getRequest url =
  { verb = "GET"
  , headers = []
  , url = url
  , body = Http.empty
  }
