module Testable.Cmd exposing (Cmd, none, batch, map, wrap)

{-|
`Testable.Cmd` is a replacement for the core `Cmd` module.  You can use it
to create components that can be tested with `Testable.TestContext`.  You can
convert `Testable.Cmd` into a core `Cmd` with the `Testable` module.

@docs Cmd, map, batch, none, wrap
-}

import Testable.Internal as Internal
import Testable.Task as Task exposing (Task)
import Platform.Cmd


{-| -}
type alias Cmd msg =
    Internal.Cmd msg


{-| -}
none : Cmd never
none =
    Internal.None


{-| -}
batch : List (Cmd msg) -> Cmd msg
batch effectsList =
    Internal.Batch effectsList


{-| -}
map : (a -> b) -> Cmd a -> Cmd b
map f source =
    case source of
        Internal.None ->
            Internal.None

        Internal.TaskCmd wrapped ->
            wrapped
                |> Task.map f
                |> Internal.TaskCmd

        Internal.Batch list ->
            Internal.Batch (List.map (map f) list)

        Internal.WrappedCmd wrapped ->
            wrapped
                |> Platform.Cmd.map f
                |> Internal.WrappedCmd


{-| -}
wrap : Platform.Cmd.Cmd msg -> Cmd msg
wrap cmd =
    Internal.WrappedCmd cmd
