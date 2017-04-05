module Testable.EffectManager
    exposing
        ( EffectManager
        , SelfMsg
        , AppMsg
        , MySub
        , MyCmd
        , State
        , extractEffectManager
        , unwrapAppMsg
        )

import Native.Testable.EffectManager


type MyCmd
    = MyCmd_ -- The actual type depends on the effect manager, so this is hidden in a native object


type MySub
    = MySub_ -- The actual type depends on the effect manager, so this is hidden in a native object


type AppMsg
    = AppMsg_ -- The actual type depends on the effect manager, so this is hidden in a native object


type SelfMsg
    = SelfMsg_ -- The actual type depends on the effect manager, so this is hidden in a native object


type State
    = State_ -- The actual type depends on the effect manager, so this is hidden in a native object


type alias EffectManager =
    { pkg : String
    , init : Platform.Task Never State
    , onEffects : List MyCmd -> List MySub -> State -> Platform.Task Never State
    , onSelfMsg : SelfMsg -> State -> Platform.Task Never State
    }


extractEffectManager : String -> Maybe EffectManager
extractEffectManager home =
    Native.Testable.EffectManager.extractEffectManager home


unwrapAppMsg : AppMsg -> msg
unwrapAppMsg =
    Native.Testable.EffectManager.unwrapAppMsg
