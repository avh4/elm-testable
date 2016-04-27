module Testable.EffectsLog (EffectsLog, Entry, empty, insert, remove, httpAction) where

import Testable.Effects exposing (Never)
import Testable.Internal as Internal exposing (Effects)
import Testable.Http as Http


type Entry action
  = HttpEntry Http.Request (Result Http.RawError Http.Response -> action)


matches : Entry action -> Entry action -> Bool
matches a b =
  let
    toComparable entry =
      case entry of
        HttpEntry url _ ->
          url
  in
    toComparable a == toComparable b


type EffectsLog action
  = EffectsLog (List (Entry action))


empty : EffectsLog action
empty =
  EffectsLog []


unsafeFromResult : Result Never a -> a
unsafeFromResult result =
  case result of
    Ok a ->
      a

    Err never ->
      Debug.crash ("Never had a value: " ++ toString never)


insert : Effects action -> EffectsLog action -> EffectsLog action
insert effects (EffectsLog log) =
  case effects of
    Internal.None ->
      EffectsLog log

    Internal.TaskEffect (Internal.HttpTask request mapResponse) ->
      EffectsLog (HttpEntry request (mapResponse >> unsafeFromResult) :: log)

    Internal.Batch list ->
      List.foldl insert (EffectsLog log) list


remove : Entry action -> EffectsLog action -> EffectsLog action
remove entry (EffectsLog log) =
  let
    step checked remaining =
      case remaining of
        [] ->
          List.reverse checked

        next :: rest ->
          if matches next entry then
            (List.reverse checked ++ rest)
          else
            step (next :: checked) rest
  in
    EffectsLog (step [] log)


httpAction : Http.Request -> Result Http.RawError Http.Response -> EffectsLog action -> Maybe ( Entry action, action )
httpAction expectedRequest response (EffectsLog log) =
  List.filterMap
    (\effects ->
      case effects of
        HttpEntry request mapResponse ->
          if request == expectedRequest then
            Just ( effects, mapResponse response )
          else
            Nothing
    )
    log
    |> List.head
