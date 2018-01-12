var _user$project$Native_Test_Http = (function () { // eslint-disable-line no-unused-vars, camelcase
    function fromTask(task) {
        if (task.elmTestable == null) {
            if (task.ctor == "_Task_andThen") {
                return fromTask(task.task)
            } else if (task.ctor == "_Task_onError") {
                return fromTask(task.task)
            } else {
                return { ctor: 'Nothing' }
            }
        } else if (task.elmTestable.ctor == "Http_NativeHttp_toTask") {
            return {
                ctor: "Just",
                _0: task.elmTestable._0
            }
        } else {
            return { ctor: 'Nothing' }
        }
    }

    return {
        fromTask: fromTask
    }
})()
