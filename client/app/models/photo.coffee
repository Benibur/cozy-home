client = require('../lib/client')

# A photo
# maintains attributes src / thumbsrc depending of the state of the model
module.exports = class Photo extends Backbone.Model

    defaults: ->
        thumbsrc: 'img/loading.gif'
        src: ''
        orientation: 1

    url: ->
        super + app.urlKey

    # build img src attributes from id.
    parse: (attrs) ->
        if not attrs.id then attrs
        else _.extend attrs,
            thumbsrc: "photos/thumbs/#{attrs.id}.jpg" + app.urlKey
            src: "photos/#{attrs.id}.jpg" + app.urlKey
            orientation: attrs.orientation

    # Return screen size photo src built from id.
    getPrevSrc: ->
        "photos/#{@get 'id'}.jpg"

Photo.listFromFiles = (skip, limit, callback)->
    client.get "files/range/#{skip}/#{limit}", callback

Photo.getPhotoArray = (callback)->
    callback( [
                    nPhotos : 3 , month   : "201504"
                ,
                    nPhotos : 30 , month   : "201503"
                ,
                    nPhotos : 10 , month   : "201502"
                ,
                    nPhotos : 5 , month   : "201501"
                ,
                    nPhotos : 20 , month   : "201412"
                ,
                    nPhotos : 500 , month   : "201411"
                ,
                    nPhotos : 100 , month   : "201410"
                ,
                    nPhotos : 30 , month   : "201409"
                ,
                    nPhotos : 30 , month   : "201408"
                ,
                    nPhotos : 400 , month   : "201407"
                ,
                    nPhotos : 1200 , month   : "201406"
                ,
                    nPhotos : 30 , month   : "201405"
                ,
                    nPhotos : 300 , month   : "201404"
                ,
                    nPhotos : 100 , month   : "201403"
                ,
                    nPhotos : 600 , month   : "201402"
                ,
                    nPhotos : 300 , month   : "201401"
                ,
                    nPhotos : 300 , month   : "201312"
                ,
                    nPhotos : 300 , month   : "201311"
                ,
                    nPhotos : 300 , month   : "201310"
                ,
                    nPhotos : 300 , month   : "201309"
                ,
                    nPhotos : 300 , month   : "201308"
                ,
                    nPhotos : 300 , month   : "201307"
                ,
                    nPhotos : 300 , month   : "201306"
                ,
                    nPhotos : 300 , month   : "201305"
                ,
                    nPhotos : 300 , month   : "201304"
                ,
                    nPhotos : 300 , month   : "201303"
                ,
                    nPhotos : 300 , month   : "201302"
                ,
                    nPhotos : 300 , month   : "201301"
                ,
                    nPhotos : 300 , month   : "201212"
                ,
                    nPhotos : 300 , month   : "201211"
                ,
                    nPhotos : 300 , month   : "201210"
                ,
                    nPhotos : 300 , month   : "201209"
                ,
                    nPhotos : 300 , month   : "201208"
                ,
                    nPhotos : 300 , month   : "201207"
                ,
                    nPhotos : 300 , month   : "201206"
                ,
                    nPhotos : 300 , month   : "201205"
                ,
                    nPhotos : 300 , month   : "201204"
                ,
                    nPhotos : 300 , month   : "201203"
                ,
                    nPhotos : 30 , month   : "201202"
                ,
                    nPhotos : 30 , month   : "201201"
              ]
            )

Photo.makeFromFile = (fileid, attr, callback) ->
    client.post "files/#{fileid}/toPhoto", attr, callback