var _user$project$Native_Mapper = (function () {
  return {
    apply: F2(function (mapper, value) {
      // potentially return Err of we can determine that value doesn't match the type of mapper's argument
      return { ctor: 'Ok', _0: mapper(value) }
    }),
    map: F2(function (f, mapper) {
      throw 'TODO: Mapper.js#map' // TODO
    })
  }
})()
