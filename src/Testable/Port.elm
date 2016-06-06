module Testable.Port exposing (wrap)

{-|
`Testable.Port` helps you wrap outgoing.  You can use it
to create ports that can be tested with `Testable.TestContext`.  You can
convert wrapped ports into a core `Cmd` with the `Testable` module.

@docs wrap
-}

import Testable.Internal as Internal
import Platform.Cmd


{-| -}
type alias Cmd msg =
    Internal.Cmd msg


{-| -}
wrap : Platform.Cmd.Cmd msg -> Cmd msg
wrap cmd =
    Internal.PortCmd cmd
