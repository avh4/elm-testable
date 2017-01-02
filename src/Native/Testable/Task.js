if (typeof _elm_lang$core$Process$sleep === 'undefined') {
  throw new Error('Native.Testable.Task was loaded before _elm_lang$core$Process: this shouldn\'t happen because Testable.Task imports Process.  Please report this at https://github.com/avh4/elm-testable/issues')
}

_elm_lang$core$Process$sleep = function (delay) {
  var result = { ctor: 'Success', _0: _elm_lang$core$Native_Utils.Tuple0 }
  return { ctor: 'SleepTask', _0: delay, _1: result }
}

if (typeof _elm_lang$http$Native_Http.toTask === 'undefined') {
  throw new Error('Native.TestContext was loaded before _elm_lang$http$Native_Http: this shouldn\'t happen because Testable.Task imports Http.  Please report this at https://github.com/avh4/elm-testable/issues')
}

_elm_lang$http$Native_Http.toTask = F2(function (request, maybeProgress) {
  // TODO: handle maybeProgress
  // TODO: handle request.{headers, body, withCredentials}
  // TODO: handle request.timeout ?
  var options = { method: request.method, url: request.url }
  var callback = function (response) {
    throw new Error('TODO: decode value out of ' + response + ' with Expect in ' + request)
  }
  return { ctor: 'HttpTask', _0: options, _1: callback }
})

var _user$project$Native_Testable_Task = (function () {
  function andThen (f, task) {
    switch (task.ctor) {
      case 'Success':
        var next = f(task._0)
        return fromPlatformTask(next)

      case 'Failure':
        return task

      case 'SleepTask':
        return {
          ctor: 'SleepTask',
          _0: task._0,
          _1: andThen(f, task._1)
        }

      case 'HttpTask':
        return {
          ctor: 'HttpTask',
          _0: task._0,
          _1: function (v) { return andThen(f, task._1(v)) }
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

      case 'SleepTask':
        return {
          ctor: 'SleepTask',
          _0: task._0,
          _1: onError(f, task._1)
        }

      case 'HttpTask':
        return {
          ctor: 'HttpTask',
          _0: task._0,
          _1: function (v) { return onError(f, task._1(v)) }
        }

      default:
        throw new Error('Unknown Testable.Task value: ' + task.ctor)
    }
  }

  function fromPlatformTask (task) {
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

      case 'SleepTask':
      case 'HttpTask':
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
