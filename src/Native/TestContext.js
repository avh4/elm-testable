if (typeof _elm_lang$core$Native_Platform.initialize === 'undefined') {
  throw new Error('Native.TestContext was loaded before _elm_lang$core$Native_Platform: this shouldn\'t happen because Platform is a default import in Elm 0.18.  Please report this at https://github.com/avh4/elm-testable/issues')
}

_elm_lang$core$Native_Platform.initialize = function (init, update, subscriptions, renderer) {
  return {
    init: init,
    update: update,
    subscriptions: subscriptions
  }
}

var _user$project$Native_TestContext = (function () { // eslint-disable-line no-unused-vars, camelcase
  // forEachLeaf : Tagger -> Cmd msg -> (Tagger -> LeafCmd -> IO ()) -> IO ()
  function forEachLeaf (tagger, bag, f) {
    switch (bag.type) {
      case 'leaf':
        f(tagger, bag)
        break

      case 'node':
        var rest = bag.branches
        while (rest.ctor !== '[]') {
          // assert(rest.ctor === '::');
          forEachLeaf(tagger, rest._0, f)
          rest = rest._1
        }
        break

      case 'map':
        var newTagger = function (x) {
          return tagger(bag.tagger(x))
        }
        forEachLeaf(newTagger, bag.tree, f)
        break

      default:
        throw new Error('Unknown internal bag node type: ' + bag.type)
    }
  }

  function identity (x) {
    return x
  }

  return {
    extractProgram: F2(function (moduleName, program) {
      var containerModule = {}
      var programInstance = program()(containerModule, moduleName) // eslint-disable-line no-unused-vars
      var embedRoot = {}
      var flags

      // This gets the return value from the modified
      // _elm_lang$core$Native_Platform.initialize above
      var app = containerModule.embed(embedRoot, flags)

      return app
    }),
    extractCmd: F2(function (tagger, cmd) {
      // NOTE: any new cases added here must use tagger or Cmd.map will be broken
      if (cmd.home === 'Task' && cmd.value.ctor === 'Perform') {
        var mappedTask = {
          ctor: '_Task_andThen',
          callback: function (x) {
            return { ctor: '_Task_succeed', value: tagger(x) }
          },
          task: cmd.value._0
        }
        return { ctor: 'Task', _0: mappedTask }
      } else if (/^[A-Z]/.test(cmd.home)) {
        // This is an effect manager
        return {
          ctor: 'EffectManagerCmd',
          _0: cmd.home,
          _1: _elm_lang$core$Native_Platform.effectManagers[cmd.home].cmdMap(tagger)(cmd.value)
        }
      } else {
        // We can safely ignore tagger because port Cmds can never actually produce messages
        return { ctor: 'PortCmd', _0: cmd.home, _1: cmd.value }
      }
    }),
    extractSub: F2(function (tagger, sub) {
      if (/^[A-Z]/.test(sub.home)) {
        // This is an effect manager
        return {
          ctor: 'EffectManagerSub',
          _0: sub.home,
          _1: _elm_lang$core$Native_Platform.effectManagers[sub.home].subMap(tagger)(sub.value)
        }
      } else {
        // This is a port
        var mapper = function (x) {
          return tagger(sub.value(x))
        }
        return { ctor: 'PortSub', _0: sub.home, _1: mapper }
      }
    }),
    extractBag: F4(function (extract, reduce, init, bag) {
      var acc = init
      forEachLeaf(identity, bag, function (tagger, s) {
        acc = reduce(extract(tagger)(s))(acc)
      })
      return acc
    }),
    extractSubPortName: function (subPort) {
      var fakeMapper = function () {}
      var sub = subPort(fakeMapper)
      // assert(sub.type === 'leaf');
      return sub.home
    },
    mockTask: function (tag) {
      return {
        ctor: 'MockTask',
        _0: tag,
        _1: function (result) {
          switch (result.ctor) {
            case 'Ok':
              return { ctor: 'Success', _0: result._0 }
            case 'Err':
              return { ctor: 'Failure', _0: result._0 }
            default:
              throw new Error("mockTask was resolved with a value that isn't a Result.  This shouldn't be possible if TestContext.elm is using native calls correctly.  Please report this at https://github.com/avh4/elm-testable/issues")
          }
        }
      }
    }
  }
})()
