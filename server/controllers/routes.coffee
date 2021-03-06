monitor           = require './monitor'
account           = require './account'
applications      = require './applications'
stackApplications = require './stack_application'
devices           = require './devices'
notifications     = require './notifications'
file              = require './file'
proxy             = require './proxy'

module.exports =

    'fileid':
        param: file.fetch

    'slug': param: applications.loadApplication

    'api/applications/getPermissions': post: applications.getPermissions
    'api/applications/getDescription': post: applications.getDescription
    'api/applications/getMetaData': post: applications.getMetaData

    'api/applications': get: applications.applications
    'api/applications/byid/:id':
        get: applications.read
        put: applications.updatestoppable
    'api/applications/install': post: applications.install
    'api/applications/:slug.png': get: applications.icon
    'api/applications/:slug.svg': get: applications.icon
    'api/applications/:slug/start': post: applications.start
    'api/applications/:slug/stop': post: applications.stop
    'api/applications/:slug/uninstall': delete: applications.uninstall
    'api/applications/:slug/update': put: applications.update
    'api/applications/update/all': put: applications.updateAll

    'api/applications/market': get: applications.fetchMarket

    'api/applications/stack': get: stackApplications.get
    'api/applications/update/stack': put: stackApplications.update
    'api/applications/reboot/stack': put: stackApplications.reboot


    'api/devices': get: devices.devices
    'api/devices/:id': delete: devices.remove

    'api/sys-data': get: monitor.sysData

    'api/users': get: account.users
    'api/user': post: account.updateAccount
    'api/instances': get: account.instances
    'api/instance': post: account.updateInstance
    'api/preference':
        get: account.getUserPreference
        post: account.setUserPreference
    'api/preference/:id':
        put: account.setUserPreference

    'api/notifications':
        get: notifications.all
        delete: notifications.deleteAll
    'api/notifications/:id':
        get: notifications.show
        delete: notifications.delete

    'notifications': post: notifications.create
    'notifications/:app/:ref':
        put: notifications.updateOrCreate
        delete: notifications.destroy

    'files/range/:skip/:limit':
        get: file.list
    'files/thumbs/:fileid':
        get: file.thumb
    'files/screens/:fileid':
        get: file.screen

    'api/proxy/':
        get: proxy.get
