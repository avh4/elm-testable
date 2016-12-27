## Note:

This is a fork from [avh4's elm-testable](https://github.com/avh4/elm-testable), which is getting rewritten in
Native code. This fork will keep being elm only.

There are still some pending functionalities, like spawning tasks.

# rogeriochaves/elm-testable

This package allows you to write components that follow the Elm Architecture in a way that is testable.
To allow this, elm-testable provides testable versions of the `Task`, `Effects`, `Http` and `Process` modules,
as well as `Testable.TestContext` to test testable components and `Testable` to integrate testable components with your Elm app.


## Example testable component

The only difference between a testable component and a standard component is the added `Testable.` in several imports.  (With the exception of `Cmd`, which conflicts with the default import of `Platform.Cmd`)

Here is the diff of converting `RandomGif.elm` into a testable component:

```diff
diff --git a/examples/RandomGif.elm b/examples/RandomGif.elm
index 8f7d14b..d8e1db5 100644
--- a/examples/RandomGif.elm
+++ b/examples/RandomGif.elm
@@ -1,20 +1,22 @@
-module Main exposing (..)
+module RandomGif exposing (..)

 --- From example 5 of the Elm Architecture Tutorial https://github.com/evancz/elm-architecture-tutorial/blob/master/examples/05-http.elm

 import Html exposing (..)
 import Html.Attributes exposing (..)
 import Html.Events exposing (..)
-import Http
+import Testable.Http as Http
 import Json.Decode as Decode
+import Testable
+import Testable.Cmd


 main : Program Never Model Msg
 main =
     Html.program
-        { init = init "cats"
+        { init = Testable.init (init "cats")
         , view = view
-        , update = update
+        , update = Testable.update update
         , subscriptions = subscriptions
         }

@@ -29,7 +31,7 @@ type alias Model =
     }


-init : String -> ( Model, Cmd Msg )
+init : String -> ( Model, Testable.Cmd.Cmd Msg )
 init topic =
     ( Model topic "waiting.gif"
     , getRandomGif topic
@@ -45,17 +47,17 @@ type Msg
     | NewGif (Result Http.Error String)


-update : Msg -> Model -> ( Model, Cmd Msg )
+update : Msg -> Model -> ( Model, Testable.Cmd.Cmd Msg )
 update msg model =
     case msg of
         MorePlease ->
             ( model, getRandomGif model.topic )

         NewGif (Ok newUrl) ->
-            ( Model model.topic newUrl, Cmd.none )
+            ( Model model.topic newUrl, Testable.Cmd.none )

         NewGif (Err _) ->
-            ( model, Cmd.none )
+            ( model, Testable.Cmd.none )



@@ -85,7 +87,7 @@ subscriptions model =
 -- HTTP


-getRandomGif : String -> Cmd Msg
+getRandomGif : String -> Testable.Cmd.Cmd Msg
 getRandomGif topic =
     let
         url =
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

Here are [complete tests for the RandomGif example](https://github.com/rogeriochaves/elm-testable/blob/master/examples/tests/RandomGifTests.elm).

## Testing Ports

You can also test that an outgoing port was called, by wrapping your ports with `Testable.Cmd.wrap`, like this:

```diff
diff --git a/examples/Spelling.elm b/examples/Spelling.elm
index e999eeb..e1ebbb5 100644
--- a/examples/Spelling.elm
+++ b/examples/Spelling.elm
@@ -5,14 +5,16 @@ port module Spelling exposing (..)
 import Html exposing (..)
 import Html.Events exposing (..)
 import String
+import Testable.Cmd
+import Testable


 main : Program Never Model Msg
 main =
     Html.program
-        { init = init
+        { init = Testable.init init
+        , update = Testable.update update
         , view = view
-        , update = update
         , subscriptions = subscriptions
         }

@@ -27,9 +29,9 @@ type alias Model =
     }


-init : ( Model, Cmd Msg )
+init : ( Model, Testable.Cmd.Cmd Msg )
 init =
-    ( Model "" [], Cmd.none )
+    ( Model "" [], Testable.Cmd.none )



@@ -45,17 +47,17 @@ type Msg
 port check : String -> Cmd msg


-update : Msg -> Model -> ( Model, Cmd Msg )
-update msg model =
-    case msg of
+update : Msg -> Model -> ( Model, Testable.Cmd.Cmd Msg )
+update msg model =
+    case msg of
         Change newWord ->
-            ( Model newWord [], Cmd.none )
+            ( Model newWord [], Testable.Cmd.none )

         Check ->
-            ( model, check model.word )
+            ( model, Testable.Cmd.wrap <| check model.word )

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
            |> assertCalled (Spelling.check "cats")
            |> test "call suggestions check port when requested"
        ]
```

Here are [complete tests for the Spelling example](https://github.com/rogeriochaves/elm-testable/blob/master/examples/tests/SpellingTests.elm).

There is also an example for [testing WebSockets](https://github.com/rogeriochaves/elm-testable/blob/master/examples/tests/WebSocketsTests.elm).

## Example integration with `Main`

To convert your testable `view` and `update` functions into functions that work with `Html.program`, use the `Testable` module:

```elm
main : Program Never Model Msg
main =
    Html.program
        { init = Testable.init MyComponent.init
        , update = Testable.update MyComponent.update
        , view = MyComponent.view
        , subscriptions = MyComponent.subscriptions
        }
```
