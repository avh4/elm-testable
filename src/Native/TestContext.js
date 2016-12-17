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
        throw new Error('Unknown internal Cmd type: ' + bag.type);
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
        throw new Error('Unknown internal Cmd type: ' + bag.type);
    }
  }


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


  function applyUpdateResult(updateResult, testContext) {
    // assert(updateResult.ctor == 'Tuple2');

    var newTasks = [];
    var newCmds = [];
    forEachCmd(updateResult._1, function(cmd) {
      if (cmd.home == 'Task' && cmd.value.ctor == 'Perform') {
        newTasks.push(cmd.value._0);
      } else {
        newCmds.push(cmd);
      }
    });

    var context = {
      ctor: 'TestContextNativeValue',
      model: updateResult._0,
      update: testContext.update,
      pendingCmds: testContext.pendingCmds.concat(newCmds),
      errors: []
    };

    newTasks.forEach(function(task) {
      var result = performTask(task);
      if (result.ctor === 'Ok') {
        context = updateContext(result._0, context);
      } else {
        console.log("Task failed: " + result);
      }
    });

    return context;
  }


  function updateContext(msg, testContext) {
    var updateResult = testContext.update(msg)(testContext.model);
    return applyUpdateResult(updateResult, testContext);
  }


  return {
    start: function(program) {
      var containerModule = {};
      var moduleName = "<TestContext fake module>"
      var p = program()(containerModule, moduleName);
      var embedRoot = {};
      var flags = undefined;
      var app = containerModule.embed(embedRoot, flags);

      var context = {
        ctor: 'TestContextNativeValue',
        model: undefined,
        update: app.update,
        pendingCmds: [],
        errors: []
      };

      return applyUpdateResult(app.init, context);
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
      return testContext.pendingCmds.some(function(cmd) {
        return cmd.home === expectedCmd.home
          && cmd.value === expectedCmd.value;
      })
    })
  };
})();
