[![Build Status](https://travis-ci.org/avh4/elm-testable.svg?branch=master)](https://travis-ci.org/avh4/elm-testable)

# avh4/elm-testable

This package allows you to write components that follow the Elm Architecture in a way that is testable.
To allow this, elm-testable provides testable versions of the `Task`, `Effects`, and `Http` modules,
as well as `Testable.TestContext` to test testable components and `Testable` to integrate testable components with your Elm app.


## Example testable component

The only difference between a testable component and a standard component is the added `Testable.` in several imports.

Here is the [diff of converting `RandomGif.elm` into a testable component](https://github.com/avh4/elm-testable/commit/a3198fd44d6631a3204ec6559a3498863550f1dc#diff-f40b8d64db53cbac61d7ab1b4f16419b).


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
