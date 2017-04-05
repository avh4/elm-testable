var _user$project$Native_Testable_EffectManager = // eslint-disable-line no-unused-vars, camelcase
 (function () {
   return {
     extractEffectManager: function (home) {
       var effectManager = _elm_lang$core$Native_Platform.effectManagers[home]
       if (!effectManager) return { ctor: 'Nothing' }
       // TODO: subMap, cmdMap
       var router = { elmTestable: { self: home } }
       return {
         ctor: 'Just',
         _0: {
           pkg: effectManager.pkg,
           init: effectManager.init,
           onSelfMsg: F2(function (msg, state) {
             // TODO: this could be curried
             return effectManager.onSelfMsg(router)(msg)(state)
           }),
           onEffects: F3(function (cmds, subs, state) {
             switch (effectManager.tag) {
               case 'sub':
                 return effectManager.onEffects(router)(subs)(state)

               case 'cmd':
                 // TODO: not tested
                 return effectManager.onEffects(router)(cmds)(state)

               case 'fx':
                 // TODO: not tested
                 return effectManager.onEffects(router)(cmds)(subs)(state)

               default:
                 throw new Error('Unknown effect manager tag: ' + effectManager.tag)
             }
           })
         }
       }
     },
     unwrapAppMsg: function (msg) {
       return msg
     }
   }
 })()
