var _user$project$Native_Test_Task = (function () { // eslint-disable-line no-unused-vars, camelcase
    var Just = _elm_lang$core$Maybe$Just;
    var Nothing = _elm_lang$core$Maybe$Nothing;
    var Ok = _elm_lang$core$Result$Ok;
    var Err = _elm_lang$core$Result$Err;

    function resolvedTask(task) {
        switch (task.ctor) {
            case '_Task_succeed':
                return Just(Ok(task.value))

            case '_Task_fail':
                return Just(Err(task.value))

            case '_Task_andThen':
                var inner = resolvedTask(task.task);
                switch (inner.ctor) {
                    case 'Nothing':
                        return Nothing;

                    case 'Just':
                        switch (inner._0.ctor) {
                            case 'Ok': return resolvedTask(task.callback(inner._0._0));
                            case 'Err': return inner;
                        }
                }

            case '_Task_onError':
                var inner = resolvedTask(task.task);
                switch (inner.ctor) {
                    case 'Nothing':
                        return Nothing;

                    case 'Just':
                        switch (inner._0.ctor) {
                            case 'Ok': return inner;
                            case 'Err': return resolvedTask(task.callback(inner._0._0));
                        }
                }

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
