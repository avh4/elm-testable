## Note:

elm-testable does not support Elm 0.18.  A new package is currently in development that will allow testing of Cmds, Tasks, and Subs without the need for elm-testable's wrappers.  More details will be posted to elm-discuss when it is available.  (See the [rewrite-native branch](https://github.com/avh4/elm-testable/tree/rewrite-native).)

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

## Testing Ports

You can also test that an outgoing port was called, by wrapping your ports using `Testable.Ports.wrap`, like this:

```diff
diff --git b/examples/Spelling.elm a/examples/Spelling.elm
index 4ff685f..62e2154 100644
--- b/examples/Spelling.elm
+++ a/examples/Spelling.elm
@@ -5,6 +5,8 @@ port module Spelling exposing (..)
 import Html exposing (..)
 import Html.Events exposing (..)
 import String
+import Testable.Cmd
+import Testable.Port as Port


 -- MODEL
@@ -16,9 +18,9 @@ type alias Model =
     }


-init : ( Model, Cmd Msg )
+init : ( Model, Testable.Cmd.Cmd Msg )
 init =
-    ( Model "" [], Cmd.none )
+    ( Model "" [], Testable.Cmd.none )



@@ -34,17 +36,17 @@ type Msg
 port check : String -> Cmd msg


-update : Msg -> Model -> ( Model, Cmd Msg )
+update : Msg -> Model -> ( Model, Testable.Cmd.Cmd Msg )
 update action model =
     case action of
         Change newWord ->
-            ( Model newWord [], Cmd.none )
+            ( Model newWord [], Testable.Cmd.none )

         Check ->
-            ( model, check model.word )
+            ( model, Port.wrap <| check model.word )

         Suggest newSuggestions ->
-            ( Model model.word newSuggestions, Cmd.none )
+            ( Model model.word newSuggestions, Testable.Cmd.none )

```

And testing it like this:

```elm
module SpellingTests exposing (..)

import ElmTest exposing (..)
import Testable.TestContext exposing (..)
import Spelling


spellingComponent : Testable.TestContext.Component Spelling.Msg Spelling.Model
spellingComponent =
    { init = Spelling.init
    , update = Spelling.update
    }


all : Test
all =
    suite "Spelling"
        [ spellingComponent
            |> startForTest
            |> update (Spelling.Change "cats")
            |> update Spelling.Check
            |> assertPortCalled (Spelling.check "cats")
            |> test "call suggestions check port when requested"
        ]
```

Here are [complete tests for the Spelling example](https://github.com/avh4/elm-testable/blob/master/examples/tests/SpellingTests.elm).

## Example integration with `Main`

To convert your testable `view` and `update` functions into functions that work with `StartApp`, use the `Testable` module:

```elm
main : Program Never
main =
    Html.App.program
        { init = Testable.init MyComponent.init
        , update = Testable.update MyComponent.update
        , view = MyComponent.view
        , subscriptions = MyComponent.subscriptions
        }
```
