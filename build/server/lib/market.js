// Generated by CoffeeScript 1.8.0
var apps, del, exec, fs, logger, request;

request = require('request-json');

logger = require('printit')({
  prefix: 'market'
});

exec = require('child_process').exec;

fs = require('fs');

del = require('del');

apps = [];

module.exports.download = function(callback) {
  var branch, command, url;
  if (apps.length > 0) {
    return callback(null, apps);
  } else {
    if (process.env.MARKET != null) {
      url = "https://gitlab.cozycloud.cc/zoe/cozy-registry.git";
      branch = process.env.MARKET;
    } else {
      url = "https://github.com/cozy-labs/cozy-registry.git";
      branch = "master";
    }
    command = ("git clone " + url + " market && ") + "cd market && " + ("git checkout " + branch + " && ") + "git submodule update --init --recursive";
    return del('./market', function(err) {
      return exec(command, {}, function(err, stdout, stderr) {
        return fs.readdir('./market/apps', function(err, files) {
          var file, _i, _len;
          for (_i = 0, _len = files.length; _i < _len; _i++) {
            file = files[_i];
            try {
              apps.push(require("../../../market/apps/" + file));
            } catch (_error) {
              apps.push(require("../../market/apps/" + file));
            }
          }
          return callback(err, apps);
        });
      });
    });
  }
};
