module Testable.TestContext exposing (Component, TestContext, startForTest, update, currentModel, assertCurrentModel, assertHttpRequest, assertNoPendingHttpRequests, resolveHttpRequest, advanceTime)

{-| A `TestContext` allows you to manage the lifecycle of an Elm component that
uses `Testable.Effects`.  Using `TestContext`, you can write tests that exercise
the entire lifecycle of your component.

@docs Component, TestContext, startForTest, update

# Inspecting
@docs currentModel, assertCurrentModel, assertHttpRequest, assertNoPendingHttpRequests

# Simulating Effects
@docs resolveHttpRequest, advanceTime
-}

import ElmTest as Test exposing (Assertion)
import String
import Testable.Cmd
import Testable.EffectsLog as EffectsLog exposing (EffectsLog)
import Testable.Http as Http
import Time exposing (Time)


{-| A component that can be used to create a `TestContext`
-}
type alias Component action model =
  { init : ( model, Testable.Cmd.Cmd action )
  , update : action -> model -> ( model, Testable.Cmd.Cmd action )
  }


{-| The representation of the current state of a testable component, including
a representaiton of any pending Effects.
-}
type TestContext action model
  = TestContext
      { component : Component action model
      , state :
          Result
            (List String)
            { model : model
            , effectsLog : EffectsLog action
            }
      }


{-| Create a `TestContext` for the given Component
-}
startForTest : Component action model -> TestContext action model
startForTest component =
  let
    ( initialState, initialEffects ) =
      component.init
  in
    TestContext
      { component = component
      , state =
          Ok
            { model = initialState
            , effectsLog = EffectsLog.empty
            }
      }
      |> applyEffects initialEffects


{-| Apply an action to the component in a given TestContext
-}
update : action -> TestContext action model -> TestContext action model
update action (TestContext context) =
  case context.state of
    Ok state ->
      let
        ( newModel, newEffects ) =
          context.component.update action state.model
      in
        TestContext
          { context
            | state = Ok { state | model = newModel }
          }
          |> applyEffects newEffects

    Err errors ->
      TestContext
        { context
          | state = Err (("update " ++ toString action ++ " applied to an TestContext with previous errors") :: errors)
        }


applyEffects : Testable.Cmd.Cmd action -> TestContext action model -> TestContext action model
applyEffects newEffects (TestContext context) =
  case context.state of
    Err errors ->
      TestContext context

    Ok { model, effectsLog } ->
      case EffectsLog.insert newEffects effectsLog of
        ( newEffectsLog, immediateActions ) ->
          List.foldl
            update
            (TestContext
              { context
                | state =
                    Ok
                      { model = model
                      , effectsLog = newEffectsLog
                      }
              }
            )
            immediateActions


{-| Assert that a given Http.Request has been made by the componet under test
-}
assertHttpRequest : Http.Request -> TestContext action model -> Assertion
assertHttpRequest request (TestContext context) =
  case context.state of
    Err errors ->
      Test.fail
        ("Expected an HTTP request to have been made:"
          ++ "\n    Expected: "
          ++ toString request
          ++ "\n    Actual:"
          ++ "\n      TextContext had previous errors:"
          ++ String.join "\n        " ("" :: errors)
        )

    Ok { model, effectsLog } ->
      if EffectsLog.containsHttpAction request effectsLog then
        Test.pass
      else
        Test.fail
          ("Expected an HTTP request to have been made:"
            ++ "\n    Expected: "
            ++ toString request
            ++ "\n    Actual: "
            ++ toString effectsLog
          )


{-| Simulate an HTTP response
-}
resolveHttpRequest : Http.Request -> Result Http.RawError Http.Response -> TestContext action model -> TestContext action model
resolveHttpRequest request response (TestContext context) =
  case context.state of
    Err errors ->
      TestContext
        { context
          | state = Err (("resolveHttpRequest " ++ toString request ++ " applied to an TestContext with previous errors") :: errors)
        }

    Ok { model, effectsLog } ->
      case
        EffectsLog.httpAction request response effectsLog
          |> Result.fromMaybe ("No pending HTTP request: " ++ toString request)
      of
        Ok ( newLog, actions ) ->
          List.foldl
            update
            (TestContext { context | state = Ok { model = model, effectsLog = newLog } })
            actions

        Err message ->
          TestContext { context | state = Err [ message ] }


{-| Ensure that there are no pending HTTP requests
-}
assertNoPendingHttpRequests : TestContext action model -> Assertion
assertNoPendingHttpRequests (TestContext context) =
  case context.state of
    Err errors ->
      Test.fail
        ("Expected no pending HTTP requests, but TextContext had previous errors:"
          ++ String.join "\n    " ("" :: errors)
        )

    Ok { effectsLog } ->
      Test.assertEqual [] (EffectsLog.httpRequests effectsLog)


{-| Simulate the passing of time
-}
advanceTime : Time -> TestContext action model -> TestContext action model
advanceTime milliseconds (TestContext context) =
  case context.state of
    Err errors ->
      TestContext
        { context
          | state = Err (("advanceTime " ++ toString milliseconds ++ " applied to an TestContext with previous errors") :: errors)
        }

    Ok { model, effectsLog } ->
      case
        EffectsLog.sleepAction milliseconds effectsLog
      of
        ( newLog, actions ) ->
          List.foldl
            update
            (TestContext { context | state = Ok { model = model, effectsLog = newLog } })
            actions


{-| Get the current state of the component under test
-}
currentModel : TestContext action model -> Result (List String) model
currentModel (TestContext context) =
  context.state |> Result.map .model


{-| A convenient way to assert about the current state of the component under test
-}
assertCurrentModel : model -> TestContext action model -> Assertion
assertCurrentModel expectedModel context =
  context
    |> currentModel
    |> Test.assertEqual (Ok expectedModel)
