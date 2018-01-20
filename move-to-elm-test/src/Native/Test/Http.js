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

  return {
    fromTask: fromTask(identity),
  }
})()