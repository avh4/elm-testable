var _user$project$Native_Test_Http = (function () { // eslint-disable-line no-unused-vars, camelcase
  var Just = _elm_lang$core$Maybe$Just;
  var Nothing = _elm_lang$core$Maybe$Nothing;
  var identity = _elm_lang$core$Basics$identity;

  // done : Task x1 a1 -> Task x0 a0
  var fromTask = F2(function(done, task) {
    switch(task.ctor) {
      case '_Task_andThen':
        // task.callback : a2 -> Task x1 a1
        return fromTask(function (a2) {
          return done(_elm_lang$core$Task$andThen(task.callback)(a2))
        })(task.task)

      case '_Task_onError':
        // task.callback : x2 -> Task x1 a1
        return fromTask(function (x2) {
          return done(_elm_lang$core$Task$onError(task.callback)(x2))
        })(task.task)

      case '_Task_succeed':
      case '_Task_fail':
      case 'MockTask':
        return Nothing

      case '_Task_nativeBinding':
        if (task.elmTestable.ctor == "Http_NativeHttp_toTask") {
          return Just({
            method: task.elmTestable.method,
            url: task.elmTestable.url,
            callback: function(response) {
              return done(task.elmTestable.callback(response));
            },
          });
        } else {
          return Nothing
        }

      default:
        throw new Error('Unknown task type: ' + task.ctor);
    }
  });

  return {
    fromTask: fromTask(identity),
  }
})()