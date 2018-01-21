if (typeof _elm_lang$core$Time$now === 'undefined') { // eslint-disable-line camelcase
  throw new Error('Native.Test.Time was loaded before _elm_lang$core$Time: this shouldn\'t happen because Test.Time imports Time.  Please report this at https://github.com/avh4/elm-testable/issues')
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

_elm_lang$core$Time$now = setItUp( // eslint-disable-line no-global-assign, camelcase
  _elm_lang$core$Time$now,
  {
    ctor: 'Core_Time_now',
    _0: function (v) {
      return { ctor: 'Success', _0: v }
    }
  }
)

var _user$project$Native_Test_Time = (function () { // eslint-disable-line no-unused-vars, camelcase
  var Just = _elm_lang$core$Maybe$Just;
  var Nothing = _elm_lang$core$Maybe$Nothing;
  var Ok = _elm_lang$core$Result$Ok;
  var Err = _elm_lang$core$Result$Err;
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
        if (task.elmTestable && task.elmTestable.ctor == "Core_Time_now") {
          return Just(function(time) {
            return done(_elm_lang$core$Task$succeed(time));
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
