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
  return {
    start: function(program) {
      var containerModule = {};
      var moduleName = "<TestContext fake module>"
      var p = program()(containerModule, moduleName);
      var embedRoot = {};
      var flags = undefined;
      var app = containerModule.embed(embedRoot, flags);

      // assert(app.init.ctor == 'Tuple2');

      return {
        ctor: 'TestContextNativeValue',
        model: app.init._0,
        update: app.update,
        pendingCmds: app.init._1,
        errors: []
      };
    },
    model: function(testContext) {
      if (testContext.errors.length > 0) {
        return { ctor: 'Err', _0: testContext.errors };
      } else {
        return { ctor: 'Ok', _0: testContext.model };
      }
    },
    update: F2(function(msg, testContext) {
      var updateResult = testContext.update(msg)(testContext.model);
      // assert(updateResult.ctor == 'Tuple2');
      return {
        ctor: 'TestContextNativeValue',
        model: updateResult._0,
        update: testContext.update,
        pendingCmds: testContext.pendingCmds,
        errors: []
      };
    }),
    pendingCmds: function(testContext) {
      return {};
    },
    hasPendingCmd: F2(function(expectedCmd, testContext) {
      if (expectedCmd.type !== 'leaf') {
        throw 'Unhandled case: expected Cmd is a Cmd.batch';
      }
      if (testContext.pendingCmds.type === 'leaf') {
        if (testContext.pendingCmds.home === expectedCmd.home
          && testContext.pendingCmds.value === expectedCmd.value) {
            return true;
        } else {
          return false;
        }
      } else {
        throw 'Unhandled case: pending cmds is a Cmd.batch';
      }
    })
  };
})();
