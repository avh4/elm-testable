var _user$project$Native_Testable_EffectManager = // eslint-disable-line no-unused-vars, camelcase
 (function () {
   var effectManagers

   function snapshotEffectManagers () {
     effectManagers = {}
     Object.keys(_elm_lang$core$Native_Platform.effectManagers).forEach(function (home) {
       // We handle Task effects within elm-testable; so don't expose the Task effect manager
       if (home === 'Task') return

       var effectManager = _elm_lang$core$Native_Platform.effectManagers[home]
       if (effectManager.isForeign) return // This is a port, which we handle elsewhere

       var router = { elmTestable: { self: home } }
       effectManagers[home] = {
         pkg: effectManager.pkg,
         init: effectManager.init,
         onSelfMsg: effectManager.onSelfMsg(router),
         onEffects: F3(function (cmds, subs, state) {
           switch (effectManager.tag) {
             case 'sub':
               return effectManager.onEffects(router)(subs)(state)

             case 'cmd':
               // TODO: not tested
               return effectManager.onEffects(router)(cmds)(state)

             case 'fx':
               return effectManager.onEffects(router)(cmds)(subs)(state)

             default:
               throw new Error('Unknown effect manager tag: ' + effectManager.tag)
           }
         })
       }
     })
   }

   return {
     extractEffectManager: function (home) {
       if (!effectManagers) snapshotEffectManagers()
       var effectManager = effectManagers[home]
       if (!effectManager) return { ctor: 'Nothing' }
       return {
         ctor: 'Just',
         _0: effectManager
       }
     },
     extractEffectManagers: function (_) {
       if (!effectManagers) snapshotEffectManagers()
       return _elm_lang$core$Native_List.fromArray(
         Object.keys(effectManagers).map(function (home) {
           return {
             ctor: '_Tuple2',
             _0: home,
             _1: effectManagers[home]
           }
         })
       )
     },
     unwrapAppMsg: function (msg) {
       return msg
     }
   }
 })()
