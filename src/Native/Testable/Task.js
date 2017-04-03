if (typeof _elm_lang$core$Process$sleep === 'undefined') { // eslint-disable-line camelcase
  throw new Error('Native.Testable.Task was loaded before _elm_lang$core$Process: this shouldn\'t happen because Testable.Task imports Process.  Please report this at https://github.com/avh4/elm-testable/issues')
}

_elm_lang$core$Process$sleep = function (delay) { // eslint-disable-line no-global-assign, no-native-reassign, camelcase
  var result = { ctor: 'Success', _0: _elm_lang$core$Native_Utils.Tuple0 }
  return { ctor: 'SleepTask', _0: delay, _1: result }
}

if (typeof _elm_lang$core$Process$spawn === 'undefined') { // eslint-disable-line camelcase
  throw new Error('Native.Testable.Task was loaded before _elm_lang$core$Process: this shouldn\'t happen because Testable.Task imports Process.  Please report this at https://github.com/avh4/elm-testable/issues')
}

_elm_lang$core$Process$spawn = function (task) { // eslint-disable-line no-global-assign, no-native-reassign, camelcase
  var processId = -1 // TODO: create unique process ids
  var result = { ctor: 'Success', _0: processId }
  var t1 = _elm_lang$core$Task$andThen(function (x) { return { ctor: 'NeverTask' } })(task)
  var t2 = _elm_lang$core$Task$onError(function (x) { return { ctor: 'NeverTask' } })(t1)
  return { ctor: 'SpawnedTask', _0: t2, _1: result }
}

if (typeof _elm_lang$core$Time$now === 'undefined') { // eslint-disable-line camelcase
  throw new Error('Native.Testable.Task was loaded before _elm_lang$core$Time: this shouldn\'t happen because Testable.Task imports Time.  Please report this at https://github.com/avh4/elm-testable/issues')
}

_elm_lang$core$Time$now.elmTestable = {
  ctor: 'NowTask',
  _0: function (v) {
    return { ctor: 'Success', _0: v }
  }
}

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
  return { ctor: 'HttpTask', _0: options, _1: callback }
})

var _user$project$Native_Testable_Task = (function () { // eslint-disable-line no-unused-vars, camelcase
  function andThen (f, task) {
    switch (task.ctor) {
      case 'Success':
        var next = f(task._0)
        return fromPlatformTask(next)

      case 'Failure':
        return task

      case 'MockTask':
        return {
          ctor: 'MockTask',
          _0: task._0,
          _1: function (v) { return andThen(f, task._1(v)) }
        }

      case 'SleepTask':
        return {
          ctor: task.ctor,
          _0: task._0,
          _1: andThen(f, task._1)
        }

      case 'HttpTask':
        return {
          ctor: 'HttpTask',
          _0: task._0,
          _1: function (v) { return andThen(f, task._1(v)) }
        }

      case 'SpawnedTask':
        return {
          ctor: task.ctor,
          _0: task._0,
          _1: andThen(f, task._1)
        }

      case 'NeverTask':
        return task

      case 'NowTask':
        return {
          ctor: 'NowTask',
          _0: function (v) { return andThen(f, task._0(v)) }
        }

      default:
        throw new Error('Unknown Testable.Task value: ' + task.ctor)
    }
  }

  function onError (f, task) {
    switch (task.ctor) {
      case 'Success':
        return task

      case 'Failure':
        var next = f(task._0)
        return fromPlatformTask(next)

      case 'MockTask':
        return {
          ctor: 'MockTask',
          _0: task._0,
          _1: function (v) { return onError(f, task._1(v)) }
        }

      case 'SleepTask':
        return {
          ctor: task.ctor,
          _0: task._0,
          _1: onError(f, task._1)
        }

      case 'HttpTask':
        return {
          ctor: 'HttpTask',
          _0: task._0,
          _1: function (v) { return onError(f, task._1(v)) }
        }

      case 'SpawnedTask':
        return {
          ctor: task.ctor,
          _0: task._0,
          _1: onError(f, task._1)
        }

      case 'NeverTask':
        return task

      case 'NowTask':
        return task

      default:
        throw new Error('Unknown Testable.Task value: ' + task.ctor)
    }
  }

  function fromPlatformTask (task_) {
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
    var task = task_.elmTestable || task_

    switch (task.ctor) {
      case '_Task_succeed':
        return { ctor: 'Success', _0: task.value }

      case '_Task_fail':
        return { ctor: 'Failure', _0: task.value }

      case '_Task_andThen':
        var next = fromPlatformTask(task.task)
        return andThen(task.callback, next)

      case '_Task_onError':
        var next_ = fromPlatformTask(task.task)
        return onError(task.callback, next_)

      case 'MockTask':
      case 'SleepTask':
      case 'HttpTask':
      case 'SpawnedTask':
      case 'NeverTask':
      case 'NowTask':
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
