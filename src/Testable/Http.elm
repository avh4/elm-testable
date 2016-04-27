module Testable.Http (getString, post, Error, empty, string, Request, getRequest, Response, RawError, ok) where

import Dict
import Http
import Json.Decode as Decode exposing (Decoder)
import Testable.Effects as Effects exposing (Effects)
import Testable.Effects.Internal as Internal


rawErrorError : RawError -> Error
rawErrorError rawError =
  case rawError of
    Http.RawTimeout ->
      Http.Timeout

    Http.RawNetworkError ->
      Http.NetworkError


getString : String -> Effects (Result Error String)
getString url =
  let
    decodeResponse response =
      case response.value of
        Http.Text responseBody ->
          Ok responseBody

        Http.Blob _ ->
          Err <| Http.UnexpectedPayload "Not Implemented: Decoding of Http.Blob response body"
  in
    Internal.HttpEffect
      { verb = "GET"
      , headers = []
      , url = url
      , body = Http.empty
      }
      (Result.formatError rawErrorError
        >> (flip Result.andThen) decodeResponse
      )


post : Decoder value -> String -> Body -> Effects (Result Error value)
post decoder url requestBody =
  let
    decodeResponse response =
      case response.value of
        Http.Text responseBody ->
          Decode.decodeString decoder responseBody
            |> Result.formatError Http.UnexpectedPayload

        Http.Blob _ ->
          Err <| Http.UnexpectedPayload "Not Implemented: Decoding of Http.Blob response body"
  in
    Internal.HttpEffect
      { verb = "POST"
      , headers = []
      , url = url
      , body = requestBody
      }
      (Result.formatError rawErrorError
        >> (flip Result.andThen) decodeResponse
      )


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



-- Responses


type alias Response =
  Http.Response


type alias RawError =
  Http.RawError


ok : String -> Result RawError Response
ok responseBody =
  Ok
    { status = 200
    , statusText = "OK"
    , headers = Dict.empty
    , url = "<< Not Implemented >>"
    , value = Http.Text responseBody
    }
