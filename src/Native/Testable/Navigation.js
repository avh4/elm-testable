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

var mapNavigation = function(ctor) {
  return function (data) {
      return {
        ctor: 'Navigation_NativeNavigation',
        _0: {
          ctor: ctor,
          _0: data
        },
        _1: function (data) { return { ctor: 'Success', _0: data } }
      }
  }
}

_elm_lang$navigation$Navigation$pushState = setItUp(
  _elm_lang$navigation$Navigation$pushState,
  mapNavigation('New')
)

_elm_lang$navigation$Navigation$replaceState = setItUp(
  _elm_lang$navigation$Navigation$replaceState,
  mapNavigation('Modify')
)

_elm_lang$navigation$Navigation$go = setItUp(
  _elm_lang$navigation$Navigation$go,
  mapNavigation('Jump')
)

_elm_lang$navigation$Navigation$setLocation = setItUp(
  _elm_lang$navigation$Navigation$setLocation,
  mapNavigation('Visit')
)

_elm_lang$navigation$Navigation$reloadPage = setItUp(
  _elm_lang$navigation$Navigation$reloadPage,
  function () { return { ctor: 'IgnoredTask' } }
)

_elm_lang$navigation$Navigation$spawnPopWatcher = setItUp(
  _elm_lang$navigation$Navigation$spawnPopWatcher,
  function () { return { ctor: 'IgnoredTask' } }
)

_elm_lang$navigation$Native_Navigation.isInternetExplorer11 = function () {
  return false
}

if (typeof _elm_lang$dom$Dom_LowLevel$onWindow === 'undefined') { // eslint-disable-line camelcase
  throw new Error('Native.Testable.Navigation was loaded before _elm_lang$dom$Dom_LowLevel$onWindow: this shouldn\'t happen because Testable.Navigation imports Dom. Please report this at https://github.com/avh4/elm-testable/issues')
}

_elm_lang$dom$Dom_LowLevel$onWindow = setItUp(
  _elm_lang$dom$Dom_LowLevel$onWindow,
  F3(function (eventName, decoder, toTask) {
    return { ctor: 'IgnoredTask' }
  })
)

var rewireNavigation = function (realImplName, realImpl) {
  return setItUp2(
    realImplName,
    realImpl,
    F2(function (locationToMessage, stuff) {
      var program = realImpl(locationToMessage)(stuff).elmTestable;

      return {
        init: program.init,
        update: program.update,
        subscriptions: program.subscriptions,
        view: program.view,
        locationToMessage: { ctor: 'Just', _0: locationToMessage }
      }
    })
  );
}

_elm_lang$navigation$Navigation$program = rewireNavigation(
  '_elm_lang$navigation$Navigation$program',
  _elm_lang$navigation$Navigation$program
);

_elm_lang$navigation$Navigation$programWithFlags = rewireNavigation(
  '_elm_lang$navigation$Navigation$programWithFlags',
  _elm_lang$navigation$Navigation$programWithFlags
);
