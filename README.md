[![Build Status](https://travis-ci.org/avh4/elm-testable.svg?branch=master)](https://travis-ci.org/avh4/elm-testable)

# avh4/elm-testable

This package allows you to write components that follow the Elm Architecture in a way that is testable.
To allow this, elm-testable provides testable versions of the `Task`, `Effects`, and `Http` modules,
as well as `Testable.TestContext` to test testable components and `Testable` to integrate testable components with your Elm app.


## Example testable component

The only difference between a testable component and a standard component is the added `Testable.` in several imports.  (With the exception of `Cmd`, which conflicts with the default import of `Platform.Cmd` in Elm 0.17.)

Here is the diff of converting `RandomGif.elm` into a testable component:

```diff
diff --git b/examples/RandomGif.elm a/examples/RandomGif.elm
@@ -6,8 +6,9 @@ import Html exposing (..)
 import Json.Decode as Json
-import Http
-import Task
+import Testable.Cmd
+import Testable.Http as Http
+import Testable.Task as Task
 
 @ -20,7 +21,7 @@ type alias Model =

-init : String -> String -> ( Model, Cmd Msg )
+init : String -> String -> ( Model, Testable.Cmd.Cmd Msg )
 init apiKey topic =
@@ -36,7 +37,7 @@ type Msg
 
-update : Msg -> Model -> ( Model, Cmd Msg )
+update : Msg -> Model -> ( Model, Testable.Cmd.Cmd Msg )
 update msg model =
@@ -44,7 +45,7 @@ update msg model =
             ( Model model.apiKey model.topic (Maybe.withDefault model.gifUrl maybeUrl)
-            , Cmd.none
+            , Testable.Cmd.none
             )
@@ -89,7 +90,7 @@ imgStyle url =
 
-getRandomGif : String -> String -> Cmd Msg
+getRandomGif : String -> String -> Testable.Cmd.Cmd Msg
 getRandomGif apiKey topic =
     Http.get decodeUrl (randomUrl apiKey topic)
         |> Task.perform (always Nothing >> NewGif)
diff --git b/examples/Main.elm a/examples/Main.elm
@@ -3,12 +3,13 @@ module Main exposing (..)
 import Task
+import Testable
 
 main =
     Html.App.program
-        { init = init "__API_KEY__" "funny cats"
-        , update = update
+        { init = Testable.init <| init "__API_KEY__" "funny cats"
+        , update = Testable.update update
         , view = view
```


## Example tests

Here is an example of the types of tests you can write for testable components:

```elm
import ElmTest exposing (..)
import Testable.TestContext exposing (..)
import Testable.Effects as Effects
import Testable.Http as Http


myComponent =
    { init = MyComponent.init
    , update = MyComponent.update
    }


all : Test
all =
    suite "MyComponent"
        [ myComponent
            |> startForTest
            |> currentModel
            |> assertEqual (Ok expectedModelValue)
            |> test "sets initial state"
        , myComponent
            |> startForTest
            |> assertHttpRequest (Http.getRequest "https://example.com/myResource")
            |> test "makes initial HTTP request"
        , myComponent
            |> startForTest
            |> resolveHttpRequest (Http.getRequest "https://example.com/myResource")
                (Http.ok """{"data":"example JSON response"}""")
            |> assertEqual (Ok expectedModelValue)
            |> test "updated the model on HTTP success"
        , myComponent
            |> startForTest
            |> update (MyComponent.LoadDetails 1234)
            |> assertHttpRequest (Http.getRequest "https://example.com/myResource/1234")
            |> test "pressing the button makes a new HTTP request"
        ]
```

Here are [complete tests for the RandomGif example](https://github.com/avh4/elm-testable/blob/master/examples/tests/RandomGifTests.elm).


## Example integration with `StartApp`

To convert your testable `view` and `update` functions into functions that work with `StartApp`, use the `Testable` module:

```elm
app =
    StartApp.start
        { init = Testable.init MyComponent.init
        , update = Testable.update MyComponent.update
        , view = view
        , inputs = []
        }
```
