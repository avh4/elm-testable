module Mapper exposing (Mapper, apply, map)

import Native.Mapper


type Mapper msg
    = Mapper_Native_


apply : Mapper msg -> value -> Result String msg
apply =
    Native.Mapper.apply


map : (a -> b) -> Mapper a -> Mapper b
map =
    Native.Mapper.map
