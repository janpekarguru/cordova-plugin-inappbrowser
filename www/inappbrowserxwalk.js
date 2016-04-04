/*global cordova, module*/

var xwalks = new Array();
var callbacks = new Array();

function InAppBrowserXwalk(index) {
  this.index = index;
}

InAppBrowserXwalk.prototype = {
  close: function () {
    cordova.exec(null, null, "InAppBrowserXwalk", "close", [this.index]);
  },
  load: function(url) {
    cordova.exec(null, null, "InAppBrowserXwalk", "load", [this.index, url]);
  },
  show: function () {
    cordova.exec(null, null, "InAppBrowserXwalk", "show", [this.index]);
  },
  hide: function () {
    cordova.exec(null, null, "InAppBrowserXwalk", "hide", [this.index]);
  },
  setSize: function (width, height) {
    cordova.exec(null, null, "InAppBrowserXwalk", "setSize", [this.index, width, height]);
  },
  setPosition: function (left, top) {
    cordova.exec(null, null, "InAppBrowserXwalk", "setPosition", [this.index, left, top]);
  },
  executeScript: function(code) {
    cordova.exec(null, null, "InAppBrowserXwalk", "injectJS", [this.index, code]);
  },
  insertScript: function(path) {
    var code = "var script = document.createElement('script'); script.type = 'text/javascript';script.src = '" + path + "'; document.getElementsByTagName('head')[0].appendChild(script);";
    cordova.exec(null, null, "InAppBrowserXwalk", "injectJS", [this.index, code]);
  },
  insertCSS: function(styles) {
    var code = "var link = document.createElement('link'); link.type='text/css'; link.innerHTML = '" + styles + "'; document.getElementsByTagName('head')[0].appendChild(link);";
    cordova.exec(null, null, "InAppBrowserXwalk", "injectJS", [this.index, code]);
  },
  insertCSSFile: function(path) {
    var code = "var link = document.createElement('link'); link.rel='stylesheet'; link.type='text/css'; link.href = '" + path + "';document.getElementsByTagName('head')[0].appendChild(link);";
    cordova.exec(null, null, "InAppBrowserXwalk", "injectJS", [this.index, code]);
  },
  hasHistory: function () {
    exec(callback, callback, "InAppBrowserXwalk", "hasHistory", [this.index]);
  },
  goBack: function () {
    exec(null, null, "InAppBrowserXwalk", "goBack", [this.index]);
  },
  getScreenshot: function(quality) {
    if (quality == null) quality = 75;
    cordova.exec(null, null, "InAppBrowserXwalk", "getScreenshot", [this.index, quality]);
  }
}

var callback = function(event) {
  if (event.type !== undefined && callbacks[event.type] !== undefined) {
    callbacks[event.type](event);
  }
}

module.exports = {
  open: function (index, url, options) {
    if (index < 0 || index > 6) return null;
    cordova.exec(callback, null, "InAppBrowserXwalk", "open", [index, url, options]);
    return new InAppBrowserXwalk(index);
  },
  addEventListener: function (eventname, func) {
    callbacks[eventname] = func;
  },
  removeEventListener: function (eventname) {
    callbacks[eventname] = undefined;
  }
};
