module Testable.Process exposing (sleep)

{-|
# Processes
@docs sleep

## Future Plans

Right now, this library is pretty sparse. For example, there is no public API
for processes to communicate with each other. This is a really important
ability, but it is also something that is extraordinarily easy to get wrong!

I think the trend will be towards an Erlang style of concurrency, where every
process has an “event queue” that anyone can send messages to. I currently
think the API will be extended to be more like this:

    type Id exit msg

    spawn : Task exit a -> Task x (Id exit Never)

    kill : Id exit msg -> Task x ()

    send : Id exit msg -> msg -> Task x ()

A process `Id` will have two type variables to make sure all communication is
valid. The `exit` type describes the messages that are produced if the process
fails because of user code. So if processes are linked and trapping errors,
they will need to handle this. The `msg` type just describes what kind of
messages this process can be sent by strangers.

We shall see though! This is just a draft that does not cover nearly everything
it needs to, so the long-term vision for concurrency in Elm will be rolling out
slowly as I get more data and experience.

I ask that people bullish on compiling to node.js keep this in mind. I think we
can do better than the hopelessly bad concurrency model of node.js, and I hope
the Elm community will be supportive of being more ambitious, even if it takes
longer. That’s kind of what Elm is all about.
-}

import Testable.Internal as Internal
import Time exposing (Time)


{-| Block progress on the current process for a given amount of time. The
JavaScript equivalent of this is [`setTimeout`][setTimeout] which lets you
delay work until later.

[setTimeout]: https://developer.mozilla.org/en-US/docs/Web/API/WindowTimers/setTimeout
-}
sleep : Time -> Internal.Task x ()
sleep milliseconds =
    Internal.SleepTask milliseconds (Internal.Success ())
