module Testable.TestContext (..) where

import ElmTest as Test exposing (Assertion)
import FakeSet as Set exposing (Set)


type alias Component action model =
  { init : EffectsContext action -> ( model, Effects action )
  , update : EffectsContext action -> action -> model -> ( model, Effects action )
  }


type alias EffectsContext action =
  { http :
      { get : String -> Effects action
      }
      -- TODO: batch
  , none : Effects action
  }


type alias TestContext action model =
  { state : model
  , component : Component action model
  , effects : EffectsLog
  , errors : List String
  }


type alias EffectsLog =
  { http : Set HttpRequest }


emptyEffectsLog =
  { http = Set.empty }


type Effects action
  = Effects
      { record : EffectsLog -> EffectsLog
      }


type HttpRequest
  = HttpGet String


effectsContext =
  { http =
      { get =
          \url ->
            Effects
              { record =
                  \log ->
                    { log | http = log.http |> Set.insert (HttpGet url) }
              }
      }
  , none = Effects { record = identity }
  }


startForTest : Component action model -> TestContext action model
startForTest component =
  let
    ( initialState, initialEffects ) =
      component.init effectsContext
  in
    { component = component
    , state = initialState
    , effects =
        (\(Effects { record }) log -> record log) initialEffects emptyEffectsLog
    , errors = []
    }


update : action -> TestContext action model -> TestContext action model
update action context =
  let
    ( newModel, newEffects ) =
      context.component.update effectsContext action context.state
  in
    { context
      | state =
          newModel
          -- , effects =
          --     context.effects
          --       |> Set.insert newEffects
    }


assertHttpRequest : String -> TestContext action model -> Assertion
assertHttpRequest expected { effects } =
  if Set.member (HttpGet expected) effects.http then
    Test.pass
  else
    Test.fail
      ("Expected an HTTP request to have been made:"
        ++ "\n    Expected: "
        ++ toString expected
        ++ "\n    Actual: "
        ++ toString effects.http
      )



-- assertEffect : Effects action -> TestContext action model -> Assertion
-- assertEffect expected { effects } =
--   case Set.member expected effects of
--     True ->
--       Test.pass
--
--     False ->
--       Test.fail
--         ("Expected an Effect to be requested:"
--           ++ "\n    Expected: "
--           ++ toString expected
--           ++ "\n    Actual: "
--           ++ toString effects
--         )
--
--
-- stubEffect : Effects action -> action -> TestContext action model -> TestContext action model
-- stubEffect request response context =
--   case Set.member request context.effects of
--     True ->
--       let
--         ( newModel, newEffects ) =
--           context.component.update response context.state
--       in
--         { context
--           | state = newModel
--           , effects =
--               context.effects
--                 |> Set.remove request
--                 |> Set.insert newEffects
--         }
--
--     False ->
--       { context | errors = ("stubbed response was not made: " ++ toString request) :: context.errors }


currentModel : TestContext action model -> Result (List String) model
currentModel context =
  case context.errors of
    [] ->
      Ok context.state

    errors ->
      Err errors
