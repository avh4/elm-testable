module Mapper exposing (Mapper, apply, map)

{-| INTERNAL DOCUMENTATION: DO NOT EXPOSE THIS MODULE!

This is a module that uses native code to let you hide a type from Elm.
When using the module, you must make sure that you call `apply` with a value
of the correc type that the Mapper is expecting.

For example, instead of

    type alias MyType a b =
        { f : a -> b }

using Mapper can hide the `a` type

    type alias MyType b =
        { f : Mapper b }

NOTE: There is no exposed function that allows you to create Mappers.
You can only create Mappers directly in native code.
To create one, simply create a function that takes a single parameter
and returns `msg`.

-}

import Native.Mapper


type Mapper msg
    = Mapper_Native_


{-| Returns Err if the native code can somehow determine that `value` is not the
correct type that the Mapper is expecting.
(But do not rely on this--you are responsible for making sure the types match.)
-}
apply : Mapper msg -> value -> Result String msg
apply =
    Native.Mapper.apply


map : (a -> b) -> Mapper a -> Mapper b
map =
    Native.Mapper.map
