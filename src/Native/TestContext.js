if (_elm_lang$core$Native_Platform.initialize === undefined) {
  throw "ERROR: Native.TestContext was loaded before _elm_lang$core$Native_Platform";
}

_elm_lang$core$Native_Platform.initialize = function(init, update, subscriptions, renderer) {
  return {
    init: init,
    update: update
  }
}

var _user$project$Native_TestContext = (function() {

  // forEachCmd : Cmd msg -> (LeafCmd -> IO ()) -> IO ()
  function forEachCmd(bag, f) {
    switch (bag.type) {
      case 'leaf':
        f(bag);
        break;

      case 'node':
        var rest = bag.branches;
        while (rest.ctor !== '[]') {
          // assert(rest.ctor === '::');
          forEachCmd(rest._0, f);
          rest = rest._1;
        }
        break;

      default:
        throw new Error('Unknown internal Cmd type: ' + bag.type);
    }
  }


  // performTask : Task x a -> Result x a
  function performTask(task) {
    switch (task.ctor) {
      case '_Task_succeed':
        return { ctor: 'Ok', _0: task.value };

      case '_Task_fail':
        return { ctor: 'Err', _0: task.value };

      case '_Task_andThen':
        var firstValue = performTask(task.task);
        if (firstValue.ctor === 'Ok') {
          var next = task.callback(firstValue._0);
          var finalValue = performTask(next);
          return finalValue;
        } else {
          return firstValue;
        }

      case '_Task_onError':
        var firstValue = performTask(task.task);
        if (firstValue.ctor === 'Err') {
          var next = task.callback(firstValue._0);
          var finalValue = performTask(next);
          return finalValue;
        } else {
          return firstValue;
        }

      default:
        throw new Error("Unknown task type: " + task.ctor);
    }
  }


  return {
    extractProgram: F2(function(moduleName, program) {
      var containerModule = {};
      var p = program()(containerModule, moduleName);
      var embedRoot = {};
      var flags = undefined;

      // This gets the return value from the modified
      // _elm_lang$core$Native_Platform.initialize above
      var app = containerModule.embed(embedRoot, flags);

      return app;
    }),
    extractCmds: function(cmd) {
      var cmds = [];
      forEachCmd(cmd, function(c) {
        if (cmd.home == 'Task' && cmd.value.ctor == 'Perform') {
          cmds.push({ ctor: 'Task', _0: cmd.value._0 });
        } else {
          cmds.push({ ctor: 'Port', _0: cmd.home, _1: cmd.value });
        }
      });
      return _elm_lang$core$Native_List.fromArray(cmds);
    },
    performTask: performTask
  };
})();
