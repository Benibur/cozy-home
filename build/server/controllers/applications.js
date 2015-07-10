// Generated by CoffeeScript 1.9.3
var Application, Manifest, NotificationsHelper, async, autostop, baseIdController, cozydb, exec, fs, icons, localization, log, manager, markBroken, market, randomString, removeAppUpdateNotification, request, sendError, sendErrorSocket, slugify, startedApplications, updateApp;

request = require('request-json');

fs = require('fs');

slugify = require('cozy-slug');

exec = require('child_process').exec;

async = require('async');

cozydb = require('cozydb');

log = require('printit')({
  prefix: "applications"
});

Application = require('../models/application');

NotificationsHelper = require('cozy-notifications-helper');

localization = require('../lib/localization_manager');

manager = require('../lib/paas').get();

Manifest = require('../lib/manifest').Manifest;

market = require('../lib/market');

autostop = require('../lib/autostop');

icons = require('../lib/icon');

startedApplications = {};

removeAppUpdateNotification = function(app) {
  var message, messageKey, notificationSlug, notifier;
  notifier = new NotificationsHelper('home');
  messageKey = 'update available notification';
  message = localization.t(messageKey, {
    appName: app.name
  });
  notificationSlug = "home_update_notification_app_" + app.name;
  return notifier.destroy(notificationSlug, function(err) {
    if (err != null) {
      return log.error(err);
    }
  });
};

sendError = function(res, err, code) {
  if (code == null) {
    code = 500;
  }
  if (err == null) {
    err = {
      stack: null,
      message: "Server error occured"
    };
  }
  console.log("Sending error to client :");
  console.log(err.stack);
  return res.send(code, {
    error: true,
    success: false,
    message: err.message,
    stack: err.stack
  });
};

sendErrorSocket = function(err) {
  console.log("Sending error through socket");
  return console.log(err.stack);
};

markBroken = function(res, app, err) {
  var data;
  console.log("Marking app " + app.name + " as broken because");
  console.log(err.stack);
  data = {
    state: 'broken',
    password: null
  };
  if (err.result != null) {
    data.errormsg = err.message + ' :\n' + err.result;
  } else if (err.message != null) {
    data.errormsg = err.message + ' :\n' + err.stack;
  } else {
    data.errormsg = err;
  }
  data.errorcode = err.code;
  return app.updateAttributes(data, function(saveErr) {
    if (saveErr) {
      return log.error(saveErr);
    }
  });
};

randomString = function(length) {
  var string;
  string = "";
  while (string.length < length) {
    string = string + Math.random().toString(36).substr(2);
  }
  return string.substr(0, length);
};

updateApp = function(app, callback) {
  var access, data;
  data = {};
  access = {};
  return manager.updateApp(app, function(err, result) {
    var manifest;
    if (err != null) {
      return callback(err);
    }
    if (app.state !== "stopped") {
      data.state = "installed";
    }
    manifest = new Manifest();
    return manifest.download(app, (function(_this) {
      return function(err) {
        var iconInfos, infos;
        if (err != null) {
          return callback(err);
        } else {
          access.permissions = manifest.getPermissions();
          access.slug = app.slug;
          data.widget = manifest.getWidget();
          data.version = manifest.getVersion();
          data.iconPath = manifest.getIconPath();
          data.color = manifest.getColor();
          data.needsUpdate = false;
          try {
            infos = {
              git: app.git,
              name: app.name,
              icon: app.icon,
              iconPath: data.iconPath,
              slug: app.slug
            };
            iconInfos = icons.getIconInfos(infos);
          } catch (_error) {
            err = _error;
            console.log(err);
            iconInfos = null;
          }
          data.iconType = (iconInfos != null ? iconInfos.extension : void 0) || null;
          return app.updateAccess(access, function(err) {
            if (err != null) {
              return callback(err);
            }
            return app.updateAttributes(data, function(err) {
              removeAppUpdateNotification(app);
              return icons.save(app, iconInfos, function(err) {
                if (err) {
                  console.log(err.stack);
                } else {
                  console.info('icon attached');
                }
                return manager.resetProxy(callback);
              });
            });
          });
        }
      };
    })(this));
  });
};

baseIdController = new cozydb.SimpleController({
  model: Application,
  reqProp: 'application',
  reqParamID: 'id'
});

module.exports = {
  loadApplicationById: baseIdController.find,
  loadApplication: function(req, res, next, slug) {
    return Application.all({
      key: req.params.slug
    }, function(err, apps) {
      if (err) {
        return next(err);
      } else if (apps === null || apps.length === 0) {
        return res.send(404, {
          error: 'Application not found'
        });
      } else {
        req.application = apps[0];
        return next();
      }
    });
  },
  applications: function(req, res, next) {
    return Application.all(function(err, apps) {
      if (err) {
        return next(err);
      } else {
        return res.send({
          rows: apps
        });
      }
    });
  },
  getPermissions: function(req, res, next) {
    var manifest;
    manifest = new Manifest();
    return manifest.download(req.body, function(err) {
      var app;
      if (err) {
        next(err);
      }
      app = {
        permissions: manifest.getPermissions()
      };
      return res.send({
        success: true,
        app: app
      });
    });
  },
  getDescription: function(req, res, next) {
    var manifest;
    manifest = new Manifest();
    return manifest.download(req.body, function(err) {
      var app;
      if (err) {
        next(err);
      }
      app = {
        description: manifest.getDescription()
      };
      return res.send({
        success: true,
        app: app
      });
    });
  },
  getMetaData: function(req, res, next) {
    var manifest;
    manifest = new Manifest();
    return manifest.download(req.body, function(err) {
      var metaData;
      if (err) {
        next(err);
      }
      metaData = manifest.getMetaData();
      return res.send({
        success: true,
        app: metaData
      }, 200);
    });
  },
  read: function(req, res, next) {
    return Application.find(req.params.id, function(err, app) {
      if (err) {
        return sendError(res, err);
      } else if (app === null) {
        return sendError(res, new Error('Application not found'), 404);
      } else {
        return res.send(app);
      }
    });
  },
  icon: function(req, res, next) {
    var ref, ref1, ref2, ref3, stream;
    if ((ref = req.application) != null ? (ref1 = ref._attachments) != null ? ref1['icon.svg'] : void 0 : void 0) {
      stream = req.application.getFile('icon.svg', (function() {}));
      stream.pipefilter = function(res, dest) {
        return dest.set('Content-Type', 'image/svg+xml');
      };
      return stream.pipe(res);
    } else if ((ref2 = req.application) != null ? (ref3 = ref2._attachments) != null ? ref3['icon.png'] : void 0 : void 0) {
      res.type('png');
      stream = req.application.getFile('icon.png', (function() {}));
      return stream.pipe(res);
    } else {
      res.type('png');
      return fs.createReadStream('./client/app/assets/img/stopped.png').pipe(res);
    }
  },
  updateData: function(req, res, next) {
    var Stoppable, app, changes;
    app = req.application;
    console.log(app);
    console.log(req.body);
    if ((req.body.isStoppable != null) && req.body.isStoppable !== app.isStoppable) {
      Stoppable = req.body.isStoppable;
      Stoppable = Stoppable != null ? Stoppable : app.isStoppable;
      changes = {
        homeposition: req.body.homeposition || app.homeposition,
        isStoppable: Stoppable
      };
      return app.updateAttributes(changes, function(err, app) {
        autostop.restartTimeout(app.name);
        if (err) {
          return sendError(res, err);
        }
        return res.send(app);
      });
    } else if ((req.body.favorite != null) && req.body.favorite !== app.favorite) {
      changes = {
        favorite: req.body.favorite
      };
      return app.updateAttributes(changes, function(err, app) {
        if (err) {
          return next(err);
        }
        return res.send(app);
      });
    } else {
      return res.send(app);
    }
  },
  install: function(req, res, next) {
    var access;
    req.body.slug = slugify(req.body.name);
    req.body.state = "installing";
    access = {
      password: randomString(32)
    };
    return Application.all({
      key: req.body.slug
    }, function(err, apps) {
      var manifest;
      if (err) {
        return sendError(res, err);
      }
      if (apps.length > 0 || req.body.slug === "proxy" || req.body.slug === "home" || req.body.slug === "data-system") {
        err = new Error("already similarly named app");
        return sendError(res, err, 400);
      }
      manifest = new Manifest();
      return manifest.download(req.body, function(err) {
        if (err) {
          return sendError(res, err);
        }
        access.permissions = manifest.getPermissions();
        access.slug = req.body.slug;
        req.body.widget = manifest.getWidget();
        req.body.version = manifest.getVersion();
        req.body.color = manifest.getColor();
        return Application.create(req.body, function(err, appli) {
          if (err) {
            return sendError(res, err);
          }
          access.app = appli.id;
          return Application.createAccess(access, (function(_this) {
            return function(err, app) {
              var infos;
              if (err) {
                return sendError(res, err);
              }
              res.send({
                success: true,
                app: appli
              }, 201);
              infos = JSON.stringify(appli);
              console.info("attempt to install app " + infos);
              appli.password = access.password;
              return manager.installApp(appli, function(err, result) {
                var iconInfos, msg, updatedData;
                if (err) {
                  markBroken(res, appli, err);
                  sendErrorSocket(err);
                  return;
                }
                if (result.drone != null) {
                  updatedData = {
                    state: 'installed',
                    port: result.drone.port
                  };
                  msg = "install succeeded on port " + appli.port;
                  console.info(msg);
                  appli.iconPath = manifest.getIconPath();
                  appli.color = manifest.getColor();
                  try {
                    iconInfos = icons.getIconInfos(appli);
                  } catch (_error) {
                    err = _error;
                    console.log(err);
                    iconInfos = null;
                  }
                  appli.iconType = (iconInfos != null ? iconInfos.extension : void 0) || null;
                  return appli.updateAttributes(updatedData, function(err) {
                    if (err != null) {
                      return sendErrorSocket(err);
                    }
                    return icons.save(appli, iconInfos, function(err) {
                      if (err != null) {
                        console.log(err.stack);
                      } else {
                        console.info('icon attached');
                      }
                      console.info('saved port in db', appli.port);
                      return manager.resetProxy(function(err) {
                        if (err != null) {
                          return sendErrorSocket(err);
                        }
                        return console.info('proxy reset', appli.port);
                      });
                    });
                  });
                } else {
                  err = new Error("Controller has no " + ("informations about " + appli.name));
                  if (err) {
                    return sendErrorSocket(err);
                  }
                }
              });
            };
          })(this));
        });
      });
    });
  },
  uninstall: function(req, res, next) {
    var removeMetadata;
    req.body.slug = req.params.slug;
    removeMetadata = function(result) {
      return req.application.destroyAccess(function(err) {
        if (err) {
          return sendError(res, err);
        }
        return req.application.destroy(function(err) {
          if (err) {
            return sendError(res, err);
          }
          manager.resetProxy(function(err) {
            if (err) {
              return sendError(res, err);
            }
          });
          return res.send({
            success: true,
            msg: 'Application successfuly uninstalled'
          });
        });
      });
    };
    return manager.uninstallApp(req.application, function(err, result) {
      if (err) {
        return manager.uninstallApp(req.application, function(err, result) {
          return removeMetadata(result);
        });
      } else {
        return removeMetadata(result);
      }
    });
  },
  update: function(req, res, next) {
    return updateApp(req.application, function(err) {
      if (err != null) {
        return markBroken(res, req.application, err);
      }
      return res.send({
        success: true,
        msg: 'Application succesfuly updated'
      });
    });
  },
  updateAll: function(req, res, next) {
    var broken, error, updateApps;
    error = {};
    broken = function(app, err, cb) {
      var data;
      console.log("Marking app " + app.name + " as broken because");
      console.log(err.stack);
      data = {
        state: 'broken',
        password: null
      };
      if (err.result != null) {
        data.errormsg = err.message + ' :\n' + err.result;
      } else {
        data.errormsg = err.message + ' :\n' + err.stack;
      }
      return app.updateAttributes(data, function(saveErr) {
        if (saveErr != null) {
          console.log(saveErr);
        }
        return cb();
      });
    };
    updateApps = function(app, callback) {
      if ((app.needsUpdate != null) && app.needsUpdate) {
        switch (app.state) {
          case "installed":
          case "stopped":
            console.log("Update " + app.name + " (" + app.state + ")");
            return updateApp(app, function(err) {
              if (err != null) {
                error[app.name] = err;
                return broken(app, err, callback);
              } else {
                return callback();
              }
            });
          default:
            return callback();
        }
      } else {
        return callback();
      }
    };
    return Application.all((function(_this) {
      return function(err, apps) {
        return async.forEachSeries(apps, updateApps, function() {
          if (Object.keys(error).length > 0) {
            return sendError(res, {
              message: error
            });
          } else {
            return res.send({
              success: true,
              msg: 'Application succesfuly updated'
            });
          }
        });
      };
    })(this));
  },
  start: function(req, res, next) {
    var data;
    setTimeout(function() {
      if (startedApplications[req.application.id] != null) {
        delete startedApplications[req.application.id];
        return markBroken(res, req.application, {
          stack: "Installation timeout",
          message: "Installation timeout"
        });
      }
    }, 45 * 1000);
    if (startedApplications[req.application.id] == null) {
      startedApplications[req.application.id] = true;
      req.application.password = randomString(32);
      data = {
        password: req.application.password
      };
      return req.application.updateAccess(data, function(err) {
        return manager.start(req.application, function(err, result) {
          if (err && err !== "Not enough Memory") {
            delete startedApplications[req.application.id];
            return markBroken(res, req.application, err);
          } else if (err) {
            delete startedApplications[req.application.id];
            data = {
              errormsg: err,
              state: 'stopped'
            };
            return req.application.updateAttributes(data, function(saveErr) {
              if (saveErr) {
                return sendError(res, saveErr);
              }
              return res.send({
                app: req.application,
                error: true,
                success: false,
                message: err.message,
                stack: err.stack
              }, 500);
            });
          } else {
            data = {
              state: 'installed',
              port: result.drone.port
            };
            return req.application.updateAttributes(data, function(err) {
              if (err) {
                delete startedApplications[req.application.id];
                return markBroken(res, req.application, err);
              }
              return manager.resetProxy(function(err) {
                delete startedApplications[req.application.id];
                if (err) {
                  return markBroken(res, req.application, err);
                } else {
                  return res.send({
                    success: true,
                    msg: 'Application running',
                    app: req.application
                  });
                }
              });
            });
          }
        });
      });
    } else {
      return res.send({
        error: true,
        msg: 'Application is already starting',
        app: req.application
      });
    }
  },
  stop: function(req, res, next) {
    return manager.stop(req.application, function(err, result) {
      var data;
      if (err) {
        return markBroken(res, req.application, err);
      }
      data = {
        state: 'stopped',
        port: 0
      };
      return req.application.updateAttributes(data, function(err) {
        if (err) {
          return sendError(res, err);
        }
        return manager.resetProxy(function(err) {
          if (err) {
            return markBroken(res, req.application, err);
          }
          return res.send({
            success: true,
            msg: 'Application stopped',
            app: req.application
          });
        });
      });
    });
  },
  fetchMarket: function(req, res, next) {
    return market.download(function(err, data) {
      if (err != null) {
        return res.send({
          error: true,
          success: false,
          message: err
        }, 500);
      } else {
        return res.send(200, data);
      }
    });
  }
};
