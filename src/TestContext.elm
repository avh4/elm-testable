module TestContext
    exposing
        ( TestContext
        , start
        , model
        , update
        )

import Native.TestContext


type TestContext model msg
    = TestContextNativeValue


type Error
    = NothingYet__


start : Program flags model msg -> TestContext model msg
start =
    Native.TestContext.start


model : TestContext model msg -> Result (List Error) model
model =
    Native.TestContext.model


update : msg -> TestContext model msg -> TestContext model msg
update =
    Native.TestContext.update
