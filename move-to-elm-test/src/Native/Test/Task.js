var _user$project$Native_Test_Task = (function () { // eslint-disable-line no-unused-vars, camelcase
    var Just = _elm_lang$core$Maybe$Just;
    var Nothing = _elm_lang$core$Maybe$Nothing;
    var Ok = _elm_lang$core$Result$Ok;
    var Err = _elm_lang$core$Result$Err;
    var Maybe = {
        andThen: _elm_lang$core$Maybe$andThen,
    };
    var Result = {
        andThen: _elm_lang$core$Result$andThen,
        onError: F2(function(f, result) {
            switch (result.ctor) {
                case 'Err':
                    return f(result._0);

                case 'Ok':
                    return result;
            }
        }),
    };

    function resolvedTask(task) {
        switch (task.ctor) {
            case '_Task_succeed':
                return Just(Ok(task.value))

            case '_Task_fail':
                return Just(Err(task.value))

            case '_Task_andThen':
                return Maybe.andThen(
                    Result.andThen(function (a) {
                        return resolvedTask(task.callback(a));
                    })
                )(resolvedTask(task.task));

            case '_Task_onError':
                return Maybe.andThen(
                    Result.onError(function (x) {
                        return resolvedTask(task.callback(x))
                    })
                )(resolvedTask(task.task));

            case '_Task_nativeBinding':
                return Nothing;

            default:
                throw new Error('Unknown task type: ' + task.ctor);
        }
    }

    return {
        resolvedTask: resolvedTask,
    }
})()
