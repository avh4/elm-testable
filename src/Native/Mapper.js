var _xavh4$elm_testable$Native_Mapper = (function () { // eslint-disable-line no-unused-vars, camelcase
  return {
    apply: F2(function (mapper, value) {
      // potentially crash if we can determine that value doesn't match the type of mapper's argument
      return mapper(value)
    }),
    map: F2(function (f, mapper) {
      return function (x) { return f(mapper(x)) }
    })
  }
})()
