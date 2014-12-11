// Generated by CoffeeScript 1.6.3
(function() {
  var CozySocketListener, global,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  CozySocketListener = (function() {
    CozySocketListener.prototype.models = {};

    CozySocketListener.prototype.events = [];

    CozySocketListener.prototype.shouldFetchCreated = function(id) {
      return true;
    };

    CozySocketListener.prototype.onRemoteCreate = function(model) {};

    CozySocketListener.prototype.onRemoteUpdate = function(model, collection) {};

    CozySocketListener.prototype.onRemoteDelete = function(model, collection) {};

    function CozySocketListener() {
      this.processStack = __bind(this.processStack, this);
      this.callbackFactory = __bind(this.callbackFactory, this);
      this.resume = __bind(this.resume, this);
      this.pause = __bind(this.pause, this);
      var err;
      try {
        this.connect();
      } catch (_error) {
        err = _error;
        console.log("Error while connecting to socket.io");
        console.log(err.stack);
      }
      this.collections = [];
      this.singlemodels = new Backbone.Collection();
      this.stack = [];
      this.ignore = [];
      this.paused = 0;
    }

    CozySocketListener.prototype.connect = function() {
      var event, pathToSocketIO, socket, url, _i, _len, _ref, _results;
      url = window.location.origin;
      path = window.location.pathname.substring(1);

      var appName = 'files';
      if(path.indexOf(appName) != -1) {
        // if production
        path = 'public/' + appName + '/'
      }
      else {
        // if home
        path = ''
      }

      pathToSocketIO = "" + path + "socket.io";
      socket = io.connect(url, {
        resource: pathToSocketIO
      });
      _ref = this.events;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        event = _ref[_i];
        _results.push(socket.on(event, this.callbackFactory(event)));
      }
      return _results;
    };

    CozySocketListener.prototype.watch = function(collection) {
      if (this.collections.length === 0) {
        this.collection = collection;
      }
      this.collections.push(collection);
      collection.socketListener = this;
      return this.watchOne(collection);
    };

    CozySocketListener.prototype.stopWatching = function(toRemove) {
      var collection, i, _i, _len, _ref;
      _ref = this.collections;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        collection = _ref[i];
        if (collection === toRemove) {
          return this.collections.splice(i, 1);
        }
      }
    };

    CozySocketListener.prototype.watchOne = function(model) {
      this.singlemodels.add(model);
      model.on('request', this.pause);
      model.on('sync', this.resume);
      model.on('destroy', this.resume);
      return model.on('error', this.resume);
    };

    CozySocketListener.prototype.pause = function(model, xhr, options) {
      var doctype, operation;
      if (options.ignoreMySocketNotification) {
        operation = model.isNew() ? 'create' : 'update';
        doctype = this.getDoctypeOf(model);
        if (doctype == null) {
          return;
        }
        this.ignore.push({
          doctype: doctype,
          operation: operation,
          model: model
        });
        return this.paused = this.paused + 1;
      }
    };

    CozySocketListener.prototype.resume = function(model, resp, options) {
      if (options.ignoreMySocketNotification) {
        this.paused = this.paused - 1;
        if (this.paused <= 0) {
          this.processStack();
          return this.paused = 0;
        }
      }
    };

    CozySocketListener.prototype.getDoctypeOf = function(model) {
      var Model, key, _ref;
      _ref = this.models;
      for (key in _ref) {
        Model = _ref[key];
        if (model instanceof Model) {
          return key;
        }
      }
    };

    CozySocketListener.prototype.cleanStack = function() {
      var ignoreEvent, ignoreIndex, removed, stackEvent, stackIndex, _results;
      ignoreIndex = 0;
      _results = [];
      while (ignoreIndex < this.ignore.length) {
        removed = false;
        stackIndex = 0;
        ignoreEvent = this.ignore[ignoreIndex];
        while (stackIndex < this.stack.length) {
          stackEvent = this.stack[stackIndex];
          if (stackEvent.operation === ignoreEvent.operation && stackEvent.id === ignoreEvent.model.id) {
            this.stack.splice(stackIndex, 1);
            removed = true;
            break;
          } else {
            stackIndex++;
          }
        }
        if (removed) {
          _results.push(this.ignore.splice(ignoreIndex, 1));
        } else {
          _results.push(ignoreIndex++);
        }
      }
      return _results;
    };

    CozySocketListener.prototype.callbackFactory = function(event) {
      var _this = this;
      return function(id) {
        var doctype, fullevent, operation, _ref;
        _ref = event.split('.'), doctype = _ref[0], operation = _ref[1];
        fullevent = {
          id: id,
          doctype: doctype,
          operation: operation
        };
        _this.stack.push(fullevent);
        if (_this.paused === 0) {
          return _this.processStack();
        }
      };
    };

    CozySocketListener.prototype.processStack = function() {
      var _results;
      this.cleanStack();
      _results = [];
      while (this.stack.length > 0) {
        _results.push(this.process(this.stack.shift()));
      }
      return _results;
    };

    CozySocketListener.prototype.process = function(event) {
      var doctype, id, model, operation,
        _this = this;
      doctype = event.doctype, operation = event.operation, id = event.id;
      switch (operation) {
        case 'create':
          if (!this.shouldFetchCreated(id)) {
            return;
          }
          model = new this.models[doctype]({
            id: id
          });
          return model.fetch({
            success: function(fetched) {
              return _this.onRemoteCreate(fetched);
            }
          });
        case 'update':
          if (model = this.singlemodels.get(id)) {
            model.fetch({
              success: function(fetched) {
                if (fetched.changedAttributes()) {
                  return _this.onRemoteUpdate(fetched, null);
                }
              }
            });
          }
          return this.collections.forEach(function(collection) {
            if (!(model = collection.get(id))) {
              return;
            }
            return model.fetch({
              success: function(fetched) {
                if (fetched.changedAttributes()) {
                  return _this.onRemoteUpdate(fetched, collection);
                }
              }
            });
          });
        case 'delete':
          if (model = this.singlemodels.get(id)) {
            this.onRemoteDelete(model, this.singlemodels);
          }
          return this.collections.forEach(function(collection) {
            if (!(model = collection.get(id))) {
              return;
            }
            return _this.onRemoteDelete(model, collection);
          });
      }
    };

    return CozySocketListener;

  })();

  global = (typeof module !== "undefined" && module !== null ? module.exports : void 0) || window;

  global.CozySocketListener = CozySocketListener;

}).call(this);
