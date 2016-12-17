if (_elm_lang$core$Native_Platform.initialize === undefined) {
  throw "ERROR: Native.TestContext was loaded before _elm_lang$core$Native_Platform";
}

_elm_lang$core$Native_Platform.initialize = function(init, update, subscriptions, renderer) {
  return {
    ctor: 'FakeApp',
    init: init,
    update: update
  }
}

var _user$project$Native_TestContext = (function() {

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
        throw 'Unknown internal Cmd type: ' + bag.type;
    }
  }


  function hasCmd(bag, expected) {
    switch (bag.type) {
      case 'leaf':
        if (bag.home === expected.home
          && bag.value === expected.value) {
            return true;
        } else {
          return false;
        }
        break;

      case 'node':
        var rest = bag.branches;
        while (rest.ctor !== '[]') {
          // assert(rest.ctor === '::');
          var next = rest._0;

          if (hasCmd(next, expected)) {
            return true;
          }

          rest = rest._1;
        }
        return false;
        break;

      default:
        throw 'Unknown internal Cmd type: ' + bag.type;
    }
  }


  function performTask(task) {
    switch (task.ctor) {
      case '_Task_andThen':
        var firstValue = performTask(task.task);
        var next = task.callback(firstValue);
        var finalValue = performTask(next);
        return finalValue;

      case '_Task_succeed':
        return task.value;

      default:
        throw "Unknown task type: " + task.ctor;
    }
  }


  function updateContext(msg, testContext) {
    var updateResult = testContext.update(msg)(testContext.model);
    // assert(updateResult.ctor == 'Tuple2');
    return {
      ctor: 'TestContextNativeValue',
      model: updateResult._0,
      update: testContext.update,
      pendingCmds: _elm_lang$core$Platform_Cmd$batch(
        _elm_lang$core$Native_List.fromArray([testContext.pendingCmds, updateResult._1])
      ),
      errors: []
    };
  }


  return {
    start: function(program) {
      var containerModule = {};
      var moduleName = "<TestContext fake module>"
      var p = program()(containerModule, moduleName);
      var embedRoot = {};
      var flags = undefined;
      var app = containerModule.embed(embedRoot, flags);

      // assert(app.init.ctor == 'Tuple2');

      var context = {
        ctor: 'TestContextNativeValue',
        model: app.init._0,
        update: app.update,
        pendingCmds: app.init._1,
        errors: []
      };

      forEachCmd(app.init._1, function(cmd) {
        if (cmd.home == 'Task' && cmd.value.ctor == 'Perform') {
          var msg = performTask(cmd.value._0);
          context = updateContext(msg, context);
        }
      });

      return context;
    },
    model: function(testContext) {
      if (testContext.errors.length > 0) {
        return { ctor: 'Err', _0: testContext.errors };
      } else {
        return { ctor: 'Ok', _0: testContext.model };
      }
    },
    update: F2(updateContext),
    pendingCmds: function(testContext) {
      return {};
    },
    hasPendingCmd: F2(function(expectedCmd, testContext) {
      if (expectedCmd.type !== 'leaf') {
        throw 'Unhandled case: expected Cmd is a Cmd.batch';
      }
      return hasCmd(testContext.pendingCmds, expectedCmd);
    })
  };
})();
