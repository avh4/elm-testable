if (typeof _elm_lang$http$Native_Http.toTask === 'undefined') {
  throw new Error('Native.Test.Http was loaded before _elm_lang$http$Native_Http: this shouldn\'t happen because Test.Http imports Http.  Please report this at https://github.com/avh4/elm-testable/issues')
}

function setItUp (realImpl, elmTestableTask) {
  var realImpl_ = realImpl
  if (elmTestableTask.arity === 2) {
    return F2(function (a, b) {
      var real = realImpl_(a)(b)
      real.elmTestable = elmTestableTask(a)(b)
      return real
    })
  } else if (typeof realImpl !== 'function') {
    realImpl.elmTestable = elmTestableTask
    return realImpl
  } else if (elmTestableTask.arity === undefined) {
    return function (a) {
      var real = realImpl_(a)
      real.elmTestable = elmTestableTask(a)
      return real
    }
  } else {
    throw new Error('Unhandled arity: ' + elmTestableTask.arity)
  }
}

_elm_lang$http$Native_Http.toTask = setItUp(
  _elm_lang$http$Native_Http.toTask,
  F2(function (request, maybeProgress) {
    // TODO: handle maybeProgress
    // TODO: handle request.{headers, body, withCredentials}
    // TODO: handle request.timeout ?
    var callback = function (response) {
      switch (response.ctor) {
        case 'Ok':
          var fullResponse = {
            url: request.url,
            status: { code: 200, message: 'OK' },
            headers: _elm_lang$core$Dict$empty,
            body: response._0
          }
          switch (request.expect.responseType) {
            case 'text':
              var result = request.expect.responseToResult(fullResponse)
              switch (result.ctor) {
                case 'Ok':
                  return _elm_lang$core$Task$succeed(result._0)

                case 'Err':
                  return _elm_lang$core$Task$fail({ ctor: 'BadPayload', _0: result._0, _1: fullResponse })

                default:
                  throw new Error('Unknown Result type: ' + result.ctor)
              }

            default:
              throw new Error('Unknown Http.Expect type: ' + request.expect.responseType)
          }

        case 'Err':
          return _elm_lang$core$Task$fail(response._0)

        default:
          throw new Error('Unknown Result type: ' + response.ctor)
      }
    }
    return {
      ctor: 'Http_NativeHttp_toTask',
      method: request.method,
      url: request.url,
      callback: callback,
    }
  })
)

var _user$project$Native_Test_Http = (function () { // eslint-disable-line no-unused-vars, camelcase
  var Just = _elm_lang$core$Maybe$Just;
  var Nothing = _elm_lang$core$Maybe$Nothing;
  var identity = _elm_lang$core$Basics$identity;
  var List = {
    empty: { ctor: '[]' },
    concatMap: _elm_lang$core$List$concatMap,
    fromMaybe: function(maybe) {
      switch (maybe.ctor) {
        case 'Just': return List.singleton(maybe._0);
        case 'Nothing': return List.empty;
      }
    },
    singleton: _elm_lang$core$List$singleton,
  };

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
        if (task.elmTestable && task.elmTestable.ctor == "Http_NativeHttp_toTask") {
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

  // nextTaskToMsg : Task Never msg -> msg
  function nextTaskToMsg(nextTask) {
    // `nextTask` *should* be built from a `Task.succeed` and be `Task Never msg`
    var maybeResult = _user$project$Test_Task$resolvedTask(nextTask);
    switch (maybeResult.ctor) {
      case 'Just':
        var result = maybeResult._0;
        switch (result.ctor) {
          case 'Ok':
            return result._0;

          default:
            throw new Error('An Http Cmd was built from a task (which *should* be `Task Never msg`) that resolved to an error.  How is this possible?  Please report this at https://github.com/avh4/elm-testable/issues')
        }

      default:
        throw new Error('An Http Cmd was built from an unresolved task.  How is this possible?  Please report this at https://github.com/avh4/elm-testable/issues')
    }
  }

  var fromCmd = F2(function(done, cmd) {
    switch (cmd.type) {
      case 'leaf':
        switch (cmd.home) {
          case 'Task':
            switch (cmd.value.ctor) {
              case 'Perform':
                var task = cmd.value._0;
                // The task *should* be (Task Never msg), right??
                return List.fromMaybe(fromTask(function(nextTask) {
                  return done(nextTaskToMsg(nextTask));
                })(task));

              default:
                throw new Error('Unknown Task.MyCmd type: ' + cmd.value.ctor);
            }

          default:
            return List.empty;
        }

      case 'node':
        return List.concatMap(fromCmd(done))(cmd.branches);

      case 'map':
        return fromCmd(function(msg1) {
          return done(cmd.tagger(msg1));
        })(cmd.tree);

      default:
        throw new Error('Unknown Cmd type: ' + cmd.type);
    }
  });

  return {
    fromTask: fromTask(identity),
    fromCmd: fromCmd(identity),
  }
})()