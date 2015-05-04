File  = require '../models/file'
onThumbCreation = require('../../init').onThumbCreation
fs = require('fs')

###*
 * Get given file, returns 404 if photo is not found.
###
module.exports.fetch = (req, res, next, id) ->
    id = id.substring 0, id.length - 4 if id.indexOf('.jpg') > 0
    File.find id, (err, file) =>
        return res.error 500, 'An error occured', err if err
        return res.error 404, 'File not found' if not file

        req.file = file
        next()

###*
 * Returns a list of n photo (from newest to oldest )
 * skip : the number of the first photo of the view not to be returned
 * limit : the max number of photo to return
###
module.exports.photoRange = (req, res, next) ->
    if req.params.skip?
        skip = parseInt(req.params.skip)
    else
        skip = 0
    if req.params.limit?
        limit = parseInt(req.params.limit)
    else
        limit = 100

    [onCreation, percent] = onThumbCreation()

    if onCreation
        res.send "percent": percent

    else

        dates = {}
        options =
            limit      : limit
            skip       : skip
            descending : true
        File.imageByDate options, (err, photos) =>
            if err
                return res.error 500, 'An error occured', err
            else
                if photos.length == limit
                    hasNext = true
                else
                    hasNext = false
                res.send {files: photos, firstRank: skip}, 200

###*
 * Gets an array that gives the number of photo for each month, from the most
 * recent month to the oldest
 * [{nPhotos:`number`, month:'YYYYMM'}, ...]
###
module.exports.photoMonthDistribution = (req, res, next) ->
    File.imageByMonth {group : true , group_level : 2 , reduce: true }, (error, distribution_raw) ->
        distribution = []
        for k in [distribution_raw.length-1..0]
            month = distribution_raw[k]
            yearStr   = month.key[0] + ''
            monthStr  = month.key[1] + ''
            if monthStr.length == 1
                monthStr = '0' + monthStr
            distribution.push(nPhotos:month.value, month:yearStr+monthStr)
        res.send(distribution, 200)

###*
 * Returns thumb for given file.
###
module.exports.photoThumb = (req, res, next) ->
    which = if req.file.binary.thumb then 'thumb' else 'file'

    stream = req.file.getBinary which, (err) ->
        if err
            console.log err
            next(err)
            stream.on 'data', () ->
            stream.on 'end', () ->
            stream.resume()
            return

    req.on 'close', () ->
        console.log "reQ.on close"
        stream.abort()

    res.on 'close', () ->
        console.log "reS.on close"
        stream.abort()


    stream.pipe res


# module.exports.photoThumb = (req, res, next) ->
#     which = if req.file.binary.thumb then 'thumb' else 'file'
#     readableStream = fs.createReadStream('/mnt/documents/Dev/code/cozy-vm-2/cozy-home/test/photo-set/photo/200701/photo-200701-0.gif')

#     req.on 'close', () ->
#         console.log "reQ.on close"
#         stream.abort()

#     res.on 'close', () ->
#         console.log "reS.on close"
#         stream.abort()

#     readableStream.pipe res




###*
 * Returns thumb for given file.
###
module.exports.photoThumbFast = (req, res, next) ->

    stream = new File(id:req.param.id).getBinary 'thumb', (err) ->
        return next err if err

    req.on 'close', () ->
        stream.abort()

    stream.pipe res


###*
 * Returns screen for given file.
###
module.exports.photoScreen = (req, res, next) ->
    which = if req.file.binary.screen then 'screen' else 'file'
    stream = req.file.getBinary which, (err) ->
        return next err if err
    stream.pipe res