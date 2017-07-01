if (typeof _elm_lang$navigation$Native_Navigation === 'undefined') { // eslint-disable-line camelcase
  throw new Error('Native.Testable.Navigation was loaded before _elm_lang$navigation$Native_Navigation: this shouldn\'t happen because Testable.Navigation imports Navigation. Please report this at https://github.com/avh4/elm-testable/issues')
}

var href = "https://elm.testable/";

_elm_lang$navigation$Native_Navigation.getLocation = function () {
  var parser = href.match(/(.*?:)\/\/(.*?):?(\d+)?(\/.*?|$)(\?.*?|$)(#.*|$)/);
  var protocol = parser[1];
  var host = parser[2];
  var port = parser[3] || '';
  var path = parser[4] || '/';
  var search = parser[5] || '';
  var hash = parser[6] || '';

  return {
    href: href,
    host: host,
    hostname: host,
    protocol: protocol,
    origin: protocol + "//" + host,
    port_: port,
    pathname: path,
    search: search,
    hash: hash,
    username: undefined,
    password: undefined
  }
}

_elm_lang$navigation$Native_Navigation.pushState = function () {
  throw new Error('elm-testable not implemented: _elm_lang$navigation$Native_Navigation.pushState')
}
_elm_lang$navigation$Navigation$pushState = _elm_lang$navigation$Native_Navigation.pushState

_elm_lang$navigation$Native_Navigation.replaceState = setItUp(
  _elm_lang$navigation$Native_Navigation.replaceState,
  function (url) {
    var currentLocation = _elm_lang$navigation$Native_Navigation.getLocation();
    if (url.match(/^\//)) {
      href = currentLocation.origin + url;
    } else if (url.match(/^\?/)) {
      href = currentLocation.origin + currentLocation.pathname + url;
    } else if (url.match(/^#/)) {
      href = currentLocation.origin + currentLocation.pathname + currentLocation.search + url;
    } else if (url.match(/^[a-z]+:\/\//i)) {
      href = url;
    } else {
      href = currentLocation.origin + currentLocation.pathname.replace(/\/[^\/]*$/, "/" + url);
    }

    return { ctor: 'Success', _0: _elm_lang$navigation$Native_Navigation.getLocation() }
  }
)
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
