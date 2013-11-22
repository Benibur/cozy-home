// Generated by CoffeeScript 1.6.3
var Application, ControllerClient, client, fs, getAuthController, haibuClient, request, resetProxy, resetRoutes, updateApps, updateRoutes;

fs = require('fs');

request = require('request-json');

Application = require('../models/application');

ControllerClient = require("cozy-clients").ControllerClient;

client = request.newClient('http://localhost:9104/');

getAuthController = function() {
  var err, token;
  if (process.env.NODE_ENV === 'production') {
    try {
      token = fs.readFileSync('/etc/cozy/controller.token', 'utf8');
      token = token.split('\n')[0];
      return token;
    } catch (_error) {
      err = _error;
      console.log(err.message);
      console.log(err.stack);
      return null;
    }
  } else {
    return "";
  }
};

haibuClient = new ControllerClient({
  token: getAuthController()
});

updateRoutes = function(occurence) {
  var _this = this;
  if (occurence < 10) {
    resetRoutes();
    return setTimeout(function() {
      return updateRoutes(occurence + 1);
    }, 30000);
  } else if (occurence < 15) {
    resetRoutes();
    return setTimeout(function() {
      return updateRoutes(occurence + 1);
    }, 60000);
  }
};

resetRoutes = function() {
  return Application.all(function(err, installedApps) {
    var appDict, installedApp, _i, _len;
    appDict = {};
    if (installedApps !== void 0) {
      for (_i = 0, _len = installedApps.length; _i < _len; _i++) {
        installedApp = installedApps[_i];
        if (installedApp.name !== "") {
          appDict[installedApp.slug] = installedApp;
        } else {
          installedApp.destroy();
        }
      }
    }
    return haibuClient.running(function(err, res, apps) {
      return updateApps(apps, appDict, resetProxy);
    });
  });
};

updateApps = function(apps, appDict, callback) {
  var app, installedApp;
  if ((apps != null) && apps.length > 0) {
    app = apps.pop();
    installedApp = appDict[app.name];
    if ((installedApp != null) && installedApp.port !== app.port) {
      return installedApp.updateAttributes({
        port: app.port
      }, function(err) {
        return updateApps(apps, appDict, callback);
      });
    } else {
      return updateApps(apps, appDict, callback);
    }
  } else {
    return callback();
  }
};

resetProxy = function() {
  return client.get('routes/reset/', function(err, res, body) {
    if ((res != null) && res.statusCode === 200) {
      return console.info('Proxy successfuly reseted.');
    } else {
      return console.info('Something went wrong while reseting proxy.');
    }
  });
};

module.exports = function() {
  return updateRoutes(0);
};
