if (typeof _elm_lang$navigation$Native_Navigation === 'undefined') { // eslint-disable-line camelcase
  throw new Error('Native.Testable.Navigation was loaded before _elm_lang$navigation$Native_Navigation: this shouldn\'t happen because Testable.Navigation imports Navigation. Please report this at https://github.com/avh4/elm-testable/issues')
}

var original_getLocation = _elm_lang$navigation$Native_Navigation.getLocation;
_elm_lang$navigation$Native_Navigation.getLocation = function () {
  if (typeof document !== 'undefined' && typeof document.location !== 'undefined') {
    return original_getLocation()
  }

  return {
    href: 'https://elm.testable/',
    host: 'elm.testable',
    hostname: 'elm.testable',
    protocol: 'https:',
    origin: 'https://elm.testable',
    port_: '',
    pathname: '/',
    search: '',
    hash: '',
    username: '',
    password: ''
  }
}

_elm_lang$navigation$Native_Navigation.pushState = setItUp(
  _elm_lang$navigation$Native_Navigation.pushState,
  function (url) {
    return {
      ctor: 'Navigation_NativeNavigation',
      _0: {
        ctor: 'New',
        _0: url
      },
      _1: function (url) { return { ctor: 'Success', _0: url } }
    }
  }
)
_elm_lang$navigation$Navigation$pushState = _elm_lang$navigation$Native_Navigation.pushState


_elm_lang$navigation$Native_Navigation.replaceState = setItUp(
  _elm_lang$navigation$Native_Navigation.replaceState,
  function (url) {
    return {
      ctor: 'Navigation_NativeNavigation',
      _0: {
        ctor: 'Modify',
        _0: url
      },
      _1: function (url) { return { ctor: 'Success', _0: url } }
    }
  }
)
_elm_lang$navigation$Navigation$replaceState = _elm_lang$navigation$Native_Navigation.replaceState


_elm_lang$navigation$Native_Navigation.go = setItUp(
  _elm_lang$navigation$Native_Navigation.go,
  function (amount) {
    return {
      ctor: 'Navigation_NativeNavigation',
      _0: {
        ctor: 'Jump',
        _0: amount
      },
      _1: function (amount) { return { ctor: 'Success', _0: amount } }
    }
  }
)
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
_elm_lang$dom$Dom_LowLevel$onWindow = _elm_lang$dom$Native_Dom.onWindow
_elm_lang$dom$Dom_LowLevel$onDocument = _elm_lang$dom$Native_Dom.onDocument

_elm_lang$navigation$Navigation$spawnPopWatcher = setItUp(
  _elm_lang$navigation$Navigation$spawnPopWatcher,
  function () {
    return { ctor: 'IgnoredTask' }
    // TODO
  }
)

var originalNavigationProgram = _elm_lang$navigation$Navigation$program;
_elm_lang$navigation$Navigation$program = setItUp2(
  '_elm_lang$navigation$Navigation$program',
  _elm_lang$navigation$Navigation$program,
  F2(function (locationToMessage, stuff) {
    var original = originalNavigationProgram(locationToMessage)(stuff).elmTestable;

    return {
      init: original.init,
      update: original.update,
      subscriptions: original.subscriptions,
      view: original.view,
      locationToMessage: { ctor: 'Just', _0: locationToMessage }
    }
  })
)
