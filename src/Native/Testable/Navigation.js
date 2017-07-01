if (typeof _elm_lang$navigation$Native_Navigation === 'undefined') { // eslint-disable-line camelcase
  throw new Error('Native.Testable.Navigation was loaded before _elm_lang$navigation$Native_Navigation: this shouldn\'t happen because Testable.Navigation imports Navigation. Please report this at https://github.com/avh4/elm-testable/issues')
}

_elm_lang$navigation$Native_Navigation.getLocation = function () {
  return _xavh4$elm_testable$Testable_Navigation$getLocation("https://elm.testable/");
}

_elm_lang$navigation$Native_Navigation.pushState = function () {
  throw new Error('elm-testable not implemented: _elm_lang$navigation$Native_Navigation.pushState')
}
_elm_lang$navigation$Navigation$pushState = _elm_lang$navigation$Native_Navigation.pushState


_elm_lang$navigation$Native_Navigation.replaceState = setItUp(
  _elm_lang$navigation$Native_Navigation.replaceState,
  function (url) {
    return {
      ctor: 'Navigation_NativeNavigation_replaceState',
      _0: url,
      _1: function (url) { return { ctor: 'Success', _0: url } }
    }
  }
);
_elm_lang$navigation$Navigation$replaceState = _elm_lang$navigation$Native_Navigation.replaceState


_elm_lang$navigation$Native_Navigation.pushState = function () {
  throw new Error('elm-testable not implemented: _elm_lang$navigation$Native_Navigation.pushState')
}
_elm_lang$navigation$Navigation$pushState = _elm_lang$navigation$Native_Navigation.pushState


_elm_lang$navigation$Native_Navigation.go = function () {
  throw new Error('elm-testable not implemented: _elm_lang$navigation$Native_Navigation.go')
}
_elm_lang$navigation$Navigation$go = _elm_lang$navigation$Native_Navigation.go


_elm_lang$navigation$Native_Navigation.reloadPage = function () {
  throw new Error('elm-testable not implemented: _elm_lang$navigation$Native_Navigation.reloadPage')
}
_elm_lang$navigation$Navigation$reloadPage = _elm_lang$navigation$Native_Navigation.reloadPage


_elm_lang$navigation$Native_Navigation.setLocation = function () {
  throw new Error('elm-testable not implemented: _elm_lang$navigation$Native_Navigation.setLocation')
}
_elm_lang$navigation$Navigation$setLocation = _elm_lang$navigation$Native_Navigation.setLocation


_elm_lang$navigation$Native_Navigation.isInternetExplorer11 = function () {
  return false
}


if (typeof _elm_lang$dom$Native_Dom === 'undefined') { // eslint-disable-line camelcase
  throw new Error('Native.Testable.Navigation was loaded before _elm_lang$dom$Native_Dom: this shouldn\'t happen because Testable.Navigation imports Dom. Please report this at https://github.com/avh4/elm-testable/issues')
}
_elm_lang$dom$Native_Dom.onWindow = setItUp(
  _elm_lang$dom$Native_Dom.onWindow,
  F3(function (eventName, decoder, toTask) {
    return { ctor: 'IgnoredTask' }
  })
)
_elm_lang$dom$Dom_LowLevel$onWindow = _elm_lang$dom$Native_Dom.onWindow;
_elm_lang$dom$Dom_LowLevel$onDocument = _elm_lang$dom$Native_Dom.onDocument;

_elm_lang$navigation$Navigation$spawnPopWatcher = setItUp(
  _elm_lang$navigation$Navigation$spawnPopWatcher,
  function () {
    return { ctor: 'IgnoredTask' }
    // TODO
  }
)
