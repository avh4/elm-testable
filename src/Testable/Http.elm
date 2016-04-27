module Testable.Http (getString, post, empty, string, Request, getRequest) where

import Http
import Json.Decode as Decode exposing (Decoder)
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


post : Decoder value -> String -> Body -> Effects (Result Error value)
post decoder url requestBody =
  let
    decodeResponse responseBody =
      Decode.decodeString decoder responseBody
        |> Result.formatError Http.UnexpectedPayload
  in
    Internal.HttpEffect
      { verb = "POST"
      , headers = []
      , url = url
      , body = requestBody
      }
      decodeResponse


type alias Error =
  Http.Error



-- Body Values


type alias Body =
  Http.Body


empty : Body
empty =
  Http.empty


string : String -> Body
string =
  Http.string



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
