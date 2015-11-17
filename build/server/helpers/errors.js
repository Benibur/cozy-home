// Generated by CoffeeScript 1.8.0
module.exports.NotFound = function(what) {
  var err;
  err = new Error(what + ': Not Found');
  err.status = 404;
  return err;
};

module.exports.NotAllowed = function() {
  var err;
  err = new Error('Not allowed');
  err.status = 401;
  return err;
};

module.exports.BadUsage = function() {
  var err;
  err = new Error('Bad Usage');
  err.status = 400;
  return err;
};
