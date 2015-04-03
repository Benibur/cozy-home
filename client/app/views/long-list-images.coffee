Photo    = require '../models/photo'


module.exports = class LongList

####################
## PUBLIC SECTION ##
#
    constructor: (@viewPort$) ->
        ####
        # init state
        @state =
            selected    : {} # selected.photoID = thumb = {id,name,thumbEl}
            selected_n  : 0  # number of photos selected
            skip        : 0  # rank of the oldest downloaded thumb
            percent     : 0  # % of thumbnails computation avancement (if any)
        ####
        # get elements (name ends with '$')
        @thumbs$  = document.createElement('div')
        @viewPort$.appendChild(@thumbs$)
        ####
        # controlers
        @buffer   = @_initBuffer()
        ####
        # bind events
        @thumbs$.addEventListener( 'click'   , @_validateClick    )

        ####
        # init buffer

        @_adaptBuffer()


        getSelectedID : () ->
            for k, val of @state.selected
                if typeof(val)=='object'
                    return k
            return null


        keyHandler : (e)->
            ####
            # console.log 'ObjectPickerImage.keyHandler', e.which
            # switch e.which
            #     when 27 # escape key
            #         e.stopPropagation()
            #         @objectPicker.onNo()
            #     when 13 # return key
            #         e.stopPropagation()
            #         @objectPicker.onYes()
            #     when 39 # right key
            #         e.stopPropagation()
            #         e.preventDefault()
            #         @_selectNextThumb()
            #     when 37 # left key
            #         e.stopPropagation()
            #         e.preventDefault()
            #         @_selectPreviousThumb()
            #     when 38 # up key
            #         e.stopPropagation()
            #         e.preventDefault()
            #         @_selectThumbUp()
            #     when 40 # down key
            #         e.stopPropagation()
            #         e.preventDefault()
            #         @_selectThumbDown()
            #     else
            #         return false
            return @longList.keyHandler(e)


#####################
## PRIVATE SECTION ##
#
    _initBuffer : ()->
        img = document.createElement('img')
        @thumbs$.appendChild(img)
        return  first :
                    prev : img
                    next : img
                last :
                    prev : img
                    next : img


    _adaptBuffer : (safeZone) ->
        safeZone = _computeSafeZone()


    _computeSafeZone: () ->

        return {firstRk, lastRk}
