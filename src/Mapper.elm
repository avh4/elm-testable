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


{-| WARNING: this will only work for values of the type that the Mapper is
expecting. You are responsible for making sure the types match. If you don't
do this correctly, you may get a runtime error or you might just get corrupted
data.
-}
apply : Mapper msg -> value -> msg
apply =
    Native.Mapper.apply


map : (a -> b) -> Mapper a -> Mapper b
map =
    Native.Mapper.map
