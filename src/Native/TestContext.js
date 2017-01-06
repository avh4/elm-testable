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

var _user$project$Native_TestContext = (function () {
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
      var programInstance = program()(containerModule, moduleName)
      var embedRoot = {}
      var flags

      // This gets the return value from the modified
      // _elm_lang$core$Native_Platform.initialize above
      var app = containerModule.embed(embedRoot, flags)

      return app
    }),
    extractCmds: function (root) {
      var cmds = []
      forEachLeaf(identity, root, function (tagger, cmd) {
        // NOTE: any new cases added here must use tagger or Cmd.map will be broken
        if (cmd.home == 'Task' && cmd.value.ctor == 'Perform') {
          var mappedTask = {
            ctor: '_Task_andThen',
            callback: function (x) {
              return { ctor: '_Task_succeed', value: tagger(x) }
            },
            task: cmd.value._0
          }
          cmds.push({ ctor: 'Task', _0: mappedTask })
        } else {
          // We can safely ignore tagger because port Cmds can never actually produce messages
          cmds.push({ ctor: 'Port', _0: cmd.home, _1: cmd.value })
        }
      })
      return _elm_lang$core$Native_List.fromArray(cmds)
    },
    extractSubs: function (sub) {
      var subs = []
      forEachLeaf(identity, sub, function (tagger, s) {
        // NOTE: if new kinds of Subs are handled here, they must use tagger or Sub.map will be broken
        var mapper = function (x) {
          return tagger(s.value(x))
        }
        subs.push({ ctor: 'PortSub', _0: s.home, _1: mapper })
      })
      return _elm_lang$core$Native_List.fromArray(subs)
    },
    extractSubPortName: function (subPort) {
      var fakeMapper = function () {}
      var sub = subPort(fakeMapper)
      // assert(sub.type === 'leaf');
      return sub.home
    },
    applyMapper: F2(function (mapper, value) {
      return { ctor: 'Ok', _0: mapper(value) }
    }),
    mockTask: function (tag) {
      return { ctor: 'MockTask', _0: tag }
    }
  }
})()
