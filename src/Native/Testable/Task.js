
function setItUp (realImpl, elmTestableTask) {
  var realImpl_ = realImpl
  if (elmTestableTask.arity === 2) {
    return F2(function (a, b) {
      var real = realImpl_(a)(b)
      real.elmTestable = elmTestableTask(a)(b)
      return real
    })
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

_elm_lang$core$Time$now.elmTestable = {
  ctor: 'Core_Time_now',
  _0: function (v) {
    return { ctor: 'Success', _0: v }
  }
}

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

_elm_lang$http$Native_Http.toTask = F2(function (request, maybeProgress) { // eslint-disable-line no-global-assign
  // TODO: handle maybeProgress
  // TODO: handle request.{headers, body, withCredentials}
  // TODO: handle request.timeout ?
  var options = { method: request.method, url: request.url }
  var callback = function (response) {
    switch (request.expect.responseType) {
      case 'text':
        var result = request.expect.responseToResult(response)
        switch (result.ctor) {
          case 'Ok':
            return { ctor: 'Success', _0: result._0 }

          case 'Err':
            return { ctor: 'Failure', _0: result._0 }

          default:
            throw new Error('Unknown Result type: ' + result.ctor)
        }

      default:
        throw new Error('Unknown Http.Expect type: ' + request.expect.responseType)
    }
  }
  return { ctor: 'Http_NativeHttp_toTask', _0: options, _1: callback }
})

var _user$project$Native_Testable_Task = (function () { // eslint-disable-line no-unused-vars, camelcase
  function fromPlatformTask (task) {
    // TODO: at the top of this file, we override many native functions that
    // produce Platform.Tasks.  However, this could actually interfere with
    // the runtime of elm-test itself, which is the case if we try to override
    // _elm_lang$core$Time$now.
    //
    // So instead of overriding _elm_lang$core$Time$now, we just add our own
    // elmTestable field into the existing Platform.Task object.
    //
    // The TODO is to change all other overridden native tasks to insert
    // and elmTestable field instead of completely overriding the task.
    // Then this || fallback can go away.
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
      case 'Http_NativeHttp_toTask':
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
