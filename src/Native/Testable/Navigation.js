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

var nativeNavigationRewire = function(args) {
  _elm_lang$navigation$Native_Navigation[args.original] = setItUp(
    _elm_lang$navigation$Native_Navigation[args.original],
    function (data) {
      return {
        ctor: 'Navigation_NativeNavigation',
        _0: {
          ctor: args.mapCtor,
          _0: data
        },
        _1: function (data) { return { ctor: 'Success', _0: data } }
      }
    }
  )

  return _elm_lang$navigation$Native_Navigation[args.original];
}

_elm_lang$navigation$Navigation$pushState = nativeNavigationRewire({
  original: 'pushState',
  mapCtor: 'New'
});

_elm_lang$navigation$Navigation$replaceState = nativeNavigationRewire({
  original: 'replaceState',
  mapCtor: 'Modify'
})

_elm_lang$navigation$Navigation$go = nativeNavigationRewire({
  original: 'go',
  mapCtor: 'Jump'
})

_elm_lang$navigation$Native_Navigation.reloadPage = function () {
  throw new Error('elm-testable not implemented: _elm_lang$navigation$Native_Navigation.reloadPage')
}
_elm_lang$navigation$Navigation$reloadPage = _elm_lang$navigation$Native_Navigation.reloadPage

_elm_lang$navigation$Navigation$setLocation = nativeNavigationRewire({
  original: 'setLocation',
  mapCtor: 'Visit'
})

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

_elm_lang$navigation$Navigation$spawnPopWatcher = setItUp(
  _elm_lang$navigation$Navigation$spawnPopWatcher,
  function () {
    return { ctor: 'IgnoredTask' }
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

var originalNavigationProgramWithFlags = _elm_lang$navigation$Navigation$program;
_elm_lang$navigation$Navigation$programWithFlags = setItUp2(
  '_elm_lang$navigation$Navigation$programWithFlags',
  _elm_lang$navigation$Navigation$programWithFlags,
  F2(function (locationToMessage, stuff) {
    var original = originalNavigationProgramWithFlags(locationToMessage)(stuff).elmTestable;

    return {
      init: original.init,
      update: original.update,
      subscriptions: original.subscriptions,
      view: original.view,
      locationToMessage: { ctor: 'Just', _0: locationToMessage }
    }
  })
)
