function setItUp (realImpl, elmTestableTask) {
  var realImpl_ = realImpl
  if (elmTestableTask.arity === 2) {
    return F2(function (a, b) {
      var real = realImpl_(a)(b)
      real.elmTestable = elmTestableTask(a)(b)
      return real
    })
  } else if (elmTestableTask.arity === 3) {
    return F3(function (a, b, c) {
      var real = realImpl_(a)(b)(c)
      real.elmTestable = elmTestableTask(a)(b)(c)
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

if (typeof _elm_lang$core$Process$sleep === 'undefined') { // eslint-disable-line camelcase
  throw new Error('Native.Testable.Task was loaded before _elm_lang$core$Process: this shouldn\'t happen because Testable.Task imports Process.  Please report this at https://github.com/avh4/elm-testable/issues')
}

_elm_lang$core$Native_Scheduler.sleep = setItUp(
  _elm_lang$core$Native_Scheduler.sleep,
  function (delay) {
    return {
      ctor: 'Core_NativeScheduler_sleep',
      _0: delay,
      _1: function () { return { ctor: 'Success', _0: _elm_lang$core$Native_Utils.Tuple0 } }
    }
  }
)
_elm_lang$core$Process$sleep = _elm_lang$core$Native_Scheduler.sleep // eslint-disable-line no-global-assign, camelcase

if (typeof _elm_lang$core$Process$spawn === 'undefined') { // eslint-disable-line camelcase
  throw new Error('Native.Testable.Task was loaded before _elm_lang$core$Process: this shouldn\'t happen because Testable.Task imports Process.  Please report this at https://github.com/avh4/elm-testable/issues')
}

if (typeof _elm_lang$core$Native_Scheduler.spawn === 'undefined') { // eslint-disable-line camelcase
  throw new Error('Native.Testable.Task was loaded before _elm_lang$core$Native_Scheduler: this shouldn\'t happen because Testable.Task imports Task.  Please report this at https://github.com/avh4/elm-testable/issues')
}

_elm_lang$core$Native_Scheduler.spawn = setItUp(
  _elm_lang$core$Native_Scheduler.spawn,
  function (task) {
    var t1 = _elm_lang$core$Task$andThen(function (x) { return { ctor: 'IgnoredTask' } })(task)
    var t2 = _elm_lang$core$Task$onError(function (x) { return { ctor: 'IgnoredTask' } })(t1)
    return {
      ctor: 'Core_NativeScheduler_spawn',
      _0: _user$project$Native_Testable_Task.fromPlatformTask(t2),
      _1: function (processId) { return { ctor: 'Success', _0: processId } }
    }
  }
)
_elm_lang$core$Process$spawn = _elm_lang$core$Native_Scheduler.spawn // eslint-disable-line no-global-assign, camelcase

_elm_lang$core$Native_Scheduler.kill = setItUp(
  _elm_lang$core$Native_Scheduler.kill,
  function (processId) {
    return {
      ctor: 'Core_NativeScheduler_kill',
      _0: processId,
      _1: { ctor: 'Success', _0: _elm_lang$core$Native_Utils.Tuple0 }
    }
  }
)
_elm_lang$core$Process$kill = _elm_lang$core$Native_Scheduler.kill // eslint-disable-line no-global-assign, camelcase

_elm_lang$core$Native_Platform.sendToSelf = setItUp(
  _elm_lang$core$Native_Platform.sendToSelf,
  F2(function (router, msg) {
    return {
      ctor: 'ToEffectManager',
      _0: router.elmTestable.self,
      _1: msg,
      _2: { ctor: 'Success', _0: _elm_lang$core$Native_Utils.Tuple0 }
    }
  })
)
_elm_lang$core$Platform$sendToSelf = _elm_lang$core$Native_Platform.sendToSelf // eslint-disable-line no-global-assign, camelcase

_elm_lang$core$Native_Platform.sendToApp = setItUp(
  _elm_lang$core$Native_Platform.sendToApp,
  F2(function (router, msg) {
    return {
      ctor: 'ToApp',
      _0: msg,
      _1: { ctor: 'Success', _0: _elm_lang$core$Native_Utils.Tuple0 }
    }
  })
)
_elm_lang$core$Platform$sendToApp = _elm_lang$core$Native_Platform.sendToApp // eslint-disable-line no-global-assign, camelcase

if (typeof _elm_lang$core$Time$now === 'undefined') { // eslint-disable-line camelcase
  throw new Error('Native.Testable.Task was loaded before _elm_lang$core$Time: this shouldn\'t happen because Testable.Task imports Time.  Please report this at https://github.com/avh4/elm-testable/issues')
}

_elm_lang$core$Time$now = setItUp( // eslint-disable-line no-global-assign, camelcase
  _elm_lang$core$Time$now,
  {
    ctor: 'Core_Time_now',
    _0: function (v) {
      return { ctor: 'Success', _0: v }
    }
  }
)

_elm_lang$core$Time$setInterval = setItUp( // eslint-disable-line no-global-assign, camelcase
  _elm_lang$core$Time$setInterval,
  F2(function (delay, task) {
    return {
      ctor: 'Core_Time_setInterval',
      _0: delay,
      _1: _user$project$Native_Testable_Task.fromPlatformTask(task)
    }
  })
)

if (typeof _elm_lang$http$Native_Http.toTask === 'undefined') {
  throw new Error('Native.TestContext was loaded before _elm_lang$http$Native_Http: this shouldn\'t happen because Testable.Task imports Http.  Please report this at https://github.com/avh4/elm-testable/issues')
}

_elm_lang$http$Native_Http.toTask = setItUp(
  _elm_lang$http$Native_Http.toTask,
  F2(function (request, maybeProgress) {
    // TODO: handle maybeProgress
    // TODO: handle request.{headers, body, withCredentials}
    // TODO: handle request.timeout ?
    var options = { method: request.method, url: request.url }
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
                  return { ctor: 'Success', _0: result._0 }

                case 'Err':
                  return {
                    ctor: 'Failure',
                    _0: { ctor: 'BadPayload', _0: result._0, _1: fullResponse }
                  }

                default:
                  throw new Error('Unknown Result type: ' + result.ctor)
              }

            default:
              throw new Error('Unknown Http.Expect type: ' + request.expect.responseType)
          }

        case 'Err':
          return { ctor: 'Failure', _0: response._0 }

        default:
          throw new Error('Unknown Result type: ' + response.ctor)
      }
    }
    return { ctor: 'Http_NativeHttp_toTask', _0: options, _1: callback }
  })
)

if (typeof _elm_lang$websocket$Native_WebSocket === 'undefined') {
  throw new Error('Native.Testable.Task was loaded before _elm_lang$websocket$Native_WebSocket: this shouldn\'t happen because Testable.Task imports WebSocket.  Please report this at https://github.com/avh4/elm-testable/issues')
}

_elm_lang$websocket$Native_WebSocket.open = setItUp(
  _elm_lang$websocket$Native_WebSocket.open,
  F2(function (url, settings) {
    return {
      ctor: 'WebSocket_NativeWebSocket_open',
      _0: url,
      _1: settings,
      _2: function (result) {
        switch (result.ctor) {
          case 'Ok':
            return { ctor: 'Success', _0: { ctor: '_elm_testable_WebSocket', _0: url } }

          case 'Err':
            return { ctor: 'Failure', _0: result._0 }

          default:
            throw new Error('Unknown Result type: ' + result.ctor)
        }
      }
    }
  })
)
_elm_lang$websocket$WebSocket_LowLevel$open = _elm_lang$websocket$Native_WebSocket.open // eslint-disable-line no-global-assign, camelcase

_elm_lang$websocket$Native_WebSocket.send = setItUp(
  _elm_lang$websocket$Native_WebSocket.send,
  F2(function (socket, string) {
    if (socket.ctor !== '_elm_testable_WebSocket') {
      throw new Error('Unexpected WebSocket value: ' + socket.ctor)
    }
    var url = socket._0
    return {
      ctor: 'WebSocket_NativeWebSocket_send',
      _0: url,
      _1: string,
      _2: function (result) {
        return { ctor: 'Success', _0: result }
      }
    }
  })
)
_elm_lang$websocket$WebSocket_LowLevel$send = _elm_lang$websocket$Native_WebSocket.send // eslint-disable-line no-global-assign, camelcase

var _user$project$Native_Testable_Task = (function () { // eslint-disable-line no-unused-vars, camelcase
  function fromPlatformTask (task) {
    if (task.elmTestable) return task.elmTestable

    switch (task.ctor) {
      case '_Task_succeed':
        return { ctor: 'Success', _0: task.value }

      case '_Task_fail':
        return { ctor: 'Failure', _0: task.value }

      case '_Task_andThen':
        var next = fromPlatformTask(task.task)
        return _user$project$Testable_Task$andThen(function (x) {
          return fromPlatformTask(task.callback(x))
        })(next)

      case '_Task_onError':
        var next_ = fromPlatformTask(task.task)
        return _user$project$Testable_Task$onError(function (x) {
          return fromPlatformTask(task.callback(x))
        })(next_)

      case 'MockTask':
      case 'IgnoredTask':
        return task

      case '_Task_nativeBinding':
        throw new Error(
          'Not Implemented Yet: ' +
          '_Task_nativeBinding was not intercepted for ' + task.callback + '\n' +
          'The function that creates the callback above will need to be overwritten ' +
          'like _elm_lang$core$Process$sleep and _elm_lang$http$Native_Http.toTask ' +
          'at the top of Native.Testable.Task.js'
        )

      default:
        throw new Error('Unknown task type: ' + task.ctor)
    }
  }

  return {
    fromPlatformTask: fromPlatformTask
  }
})()
