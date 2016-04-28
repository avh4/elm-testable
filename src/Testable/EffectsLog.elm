module Testable.EffectsLog (EffectsLog, empty, insert, httpAction, sleepAction) where

import FakeDict as Dict exposing (Dict)
import PairingHeap exposing (PairingHeap)
import Testable.Effects as Effects exposing (Never)
import Testable.Internal as Internal exposing (Effects, TaskResult(..))
import Testable.Http as Http
import Time exposing (Time)


type EffectsResult action
  = Finished action
  | MoreEffects (Effects action)


type EffectsLog action
  = EffectsLog
      { http :
          -- TODO: should be multidict
          Dict Http.Request (Result Http.RawError Http.Response -> EffectsResult action)
      , now : Time
      , sleep : PairingHeap Time (EffectsResult action)
      }


empty : EffectsLog action
empty =
  EffectsLog
    { http = Dict.empty
    , now = 0
    , sleep = PairingHeap.empty
    }


unsafeFromResult : TaskResult Never a -> EffectsResult a
unsafeFromResult result =
  case result of
    Success a ->
      Finished a

    Failure never ->
      Debug.crash ("Never had a value: " ++ toString never)

    Continue next ->
      MoreEffects (Effects.task next)


{-| Returns the new EffectsLog and any actions that should be applied immediately
-}
insert : Effects action -> EffectsLog action -> ( EffectsLog action, List action )
insert effects (EffectsLog log) =
  case effects of
    Internal.None ->
      ( EffectsLog log, [] )

    Internal.TaskEffect (Internal.HttpTask request mapResponse) ->
      ( EffectsLog
          { log | http = Dict.insert request (mapResponse >> unsafeFromResult) log.http }
      , []
      )

    Internal.TaskEffect (Internal.ImmediateTask result) ->
      case unsafeFromResult result of
        Finished action ->
          ( EffectsLog log, [ action ] )

        MoreEffects next ->
          EffectsLog log
            |> insert next

    Internal.TaskEffect (Internal.SleepTask milliseconds result) ->
      if milliseconds <= 0 then
        insert (Internal.TaskEffect (Internal.ImmediateTask result)) (EffectsLog log)
      else
        ( EffectsLog
            { log | sleep = PairingHeap.insert ( log.now + milliseconds, unsafeFromResult result ) log.sleep }
        , []
        )

    Internal.Batch list ->
      let
        step effect ( log', immediates ) =
          case insert effect log' of
            ( log'', immediates' ) ->
              ( log'', immediates ++ immediates' )
      in
        List.foldl step ( EffectsLog log, [] ) list


httpAction : Http.Request -> Result Http.RawError Http.Response -> EffectsLog action -> Maybe ( EffectsLog action, List action )
httpAction expectedRequest response (EffectsLog log) =
  case Dict.get expectedRequest log.http of
    Nothing ->
      Nothing

    Just mapResponse ->
      case mapResponse response of
        Finished action ->
          Just
            ( EffectsLog { log | http = Dict.remove expectedRequest log.http }
            , [ action ]
            )

        MoreEffects next ->
          EffectsLog log
            |> insert next
            |> Just


sleepAction : Time -> EffectsLog action -> ( EffectsLog action, List action )
sleepAction milliseconds (EffectsLog log) =
  case PairingHeap.findMin log.sleep of
    Nothing ->
      ( EffectsLog { log | now = log.now + milliseconds }
      , []
      )

    Just ( time, result ) ->
      if time <= log.now + milliseconds then
        case result of
          Finished action ->
            -- TODO: recurse
            ( EffectsLog
                { log
                  | sleep = PairingHeap.deleteMin log.sleep
                  , now = log.now + milliseconds
                }
            , [ action ]
            )

          MoreEffects next ->
            -- TODO: recurse
            EffectsLog
              { log
                | sleep = PairingHeap.deleteMin log.sleep
                , now = log.now + milliseconds
              }
              |> insert next
      else
        ( EffectsLog { log | now = log.now + milliseconds }
        , []
        )
