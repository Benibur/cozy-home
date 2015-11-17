// Generated by CoffeeScript 1.8.0
var Client, apps, comparator, del, download, exec, fs, getApps, isDownloading, log, request, url;

request = require('request-json');

Client = request.JsonClient;

log = require('printit')({
  prefix: 'market'
});

exec = require('child_process').exec;

fs = require('fs');

del = require('del');

url = require('url');

apps = {};

isDownloading = false;

comparator = function(a, b) {
  if (a.comment === 'official application' && b.comment !== 'official application') {
    return -1;
  } else if (a.comment !== 'official application' && b.comment === 'official application') {
    return 1;
  } else if (a.name > b.name) {
    return 1;
  } else if (a.name < b.name) {
    return -1;
  } else {
    return 0;
  }
};

download = module.exports.download = function(callback) {
  var client, commit, data, oldMarket, urlRegistry, version;
  isDownloading = true;
  if (process.env.MARKET != null) {
    urlRegistry = url.parse(process.env.MARKET);
  } else {
    urlRegistry = url.parse("https://registry.cozycloud.cc/cozy-registry.json");
  }
  version = 0;
  commit = 0;
  if (fs.existsSync('./market.json')) {
    data = fs.readFileSync('./market.json', 'utf8');
    try {
      oldMarket = JSON.parse(data);
      version = oldMarket.version;
      commit = oldMarket.commit;
    } catch (_error) {}
  }
  client = new Client("" + urlRegistry.protocol + "//" + urlRegistry.host);
  switch (process.env.NODE_ENV) {
    case 'production':
      client.headers['user-agent'] = 'cozy';
      break;
    case 'test':
      client.headers['user-agent'] = 'cozy-test';
      break;
    default:
      client.headers['user-agent'] = 'cozy-dev';
  }
  return client.get("" + urlRegistry.pathname + "?version=" + version + "&commit=" + commit, function(err, res, body) {
    if (!err && (body.apps_list != null) && Object.keys(body.apps_list).length > 0) {
      apps = body.apps_list;
      fs.writeFileSync('./market.json', JSON.stringify(body));
    } else if (oldMarket != null) {
      apps = oldMarket.apps_list;
    } else {
      apps = {};
    }
    return callback(err, apps);
  });
};

getApps = module.exports.getApps = function(cb) {
  var data, market;
  if (Object.keys(apps).length > 0) {
    return cb(null, apps);
  } else if (fs.existsSync('./market.json')) {
    data = fs.readFileSync('./market.json', 'utf8');
    market = JSON.parse(data);
    return cb(null, market.apps_list);
  } else {
    if (isDownloading) {
      return setTimeout(function() {
        return getApps(cb);
      }, 1000);
    } else {
      return download(cb);
    }
  }
};

module.exports.getApp = function(app) {
  if (apps[app] != null) {
    return [null, apps[app]];
  } else {
    return ['not found', null];
  }
};
