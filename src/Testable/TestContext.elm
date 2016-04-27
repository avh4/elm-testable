module Testable.TestContext (..) where

import ElmTest as Test exposing (Assertion)
import Testable.Effects as Effects exposing (Effects)
import Testable.EffectsLog as EffectsLog exposing (EffectsLog)


type alias Component action model =
  { init : ( model, Effects action )
  , update : action -> model -> ( model, Effects action )
  }


type alias TestContext action model =
  { state : model
  , component : Component action model
  , effects : EffectsLog action
  , errors : List String
  }


startForTest : Component action model -> TestContext action model
startForTest component =
  let
    ( initialState, initialEffects ) =
      component.init
  in
    { component = component
    , state = initialState
    , effects =
        EffectsLog.empty
          |> EffectsLog.insert initialEffects
    , errors = []
    }


update : action -> TestContext action model -> TestContext action model
update action context =
  let
    ( newModel, newEffects ) =
      context.component.update action context.state
  in
    { context
      | state =
          newModel
          -- , effects =
          --     context.effects
          --       |> Set.insert newEffects
    }


assertHttpRequest : String -> TestContext action model -> Assertion
assertHttpRequest request testContext =
  case EffectsLog.httpAction request "" testContext.effects of
    Just _ ->
      Test.pass

    Nothing ->
      Test.fail
        ("Expected an HTTP request to have been made:"
          ++ "\n    Expected: "
          ++ toString request
          ++ "\n    Actual: "
          ++ toString testContext.effects
        )


stubHttpRequest : String -> String -> TestContext action model -> TestContext action model
stubHttpRequest request response context =
  case
    EffectsLog.httpAction request response context.effects
      |> Result.fromMaybe ("No pending HTTP request: " ++ request)
  of
    Ok ( effects, action ) ->
      { context
        | state = context.component.update action context.state |> fst
        , effects = EffectsLog.remove effects context.effects
      }

    Err message ->
      { context | errors = (message :: context.errors) }


currentModel : TestContext action model -> Result (List String) model
currentModel context =
  case context.errors of
    [] ->
      Ok context.state

    errors ->
      Err errors
