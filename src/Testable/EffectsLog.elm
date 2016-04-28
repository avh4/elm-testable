module Testable.EffectsLog (EffectsLog, empty, insert, httpAction) where

import FakeDict as Dict exposing (Dict)
import Testable.Effects as Effects exposing (Never)
import Testable.Internal as Internal exposing (Effects, TaskResult(..))
import Testable.Http as Http


type EffectsResult action
  = Finished action
  | MoreEffects (Effects action)


type EffectsLog action
  = EffectsLog
      { http :
          -- TODO: should be multidict
          Dict Http.Request (Result Http.RawError Http.Response -> EffectsResult action)
      }


empty : EffectsLog action
empty =
  EffectsLog
    { http = Dict.empty
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

    Internal.TaskEffect (Internal.ImmediateTask (Ok result)) ->
      ( EffectsLog log, [ result ] )

    Internal.TaskEffect (Internal.ImmediateTask (Err _)) ->
      Debug.crash "A TaskEffect produced an error, but the task should have had type (Task Never action) -- please report this to https://github.com/avh4/elm-testable/issues"

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
        Finished value ->
          Just
            ( EffectsLog { log | http = Dict.remove expectedRequest log.http }
            , [ value ]
            )

        MoreEffects next ->
          EffectsLog log
            |> insert next
            |> Just
