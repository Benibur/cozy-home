Photo    = require '../models/photo'


module.exports = class LongList

################################################################################
# -- USAGE --
#
#   longList = new LongList(viewPortElement)
#
#   doActions() ...
#
#   when the viewPortElement is attached in the DOM:
#   longList.init()
#
# -- SEMANTIC / CONVENTIONS --
#
# 1/ a variable name ending with a '$' is a reference to a node in the DOM
#
# 2/ months
#   [ {nPhotos:45, "201503"}, ... ]
# array of all the months having a photo.
# months.length = number of months having a photo
# months[n] = {nPhotos:45, "201503"}
#
# 3/ LongList.nPhotos
#   Total number of images in the long list.
#
# 4/ rank
#   all images are indexed by their rank being their position in the ordered
#   list of images.
#   The most recent image rank is 0, the oldest rank is nPhoto - 1
#
# 5/ inMonthRank
#   The rank of the image in the chronological list of images of the same month
#
# 6/ buffer
#      first   : {thumb}   # top most thumb
#      firstRk : {integer} # rank of the first image of the buffer
#      last    : {thumb}   # bottom most thumb
#      lastRk  : {integer} # rank of the last image of the buffer
#      # the following data are the coordonates of the thumb that would be just
#      # after the last of the buffer.
#      nextLastRk      : {integer}
#      nextLastCol     : {integer}
#      nextLastY       : {integer}
#      nextLastMonthRk : {integer}
#   Lists all the created thumbs, keep a reference on the first (top
#   most) and the last (bottom most) cells. The data structure of the buffer
#   is a doubled linked list.
#   each element of the list is an object
#
# 7/ thumb
#      prev : {thumb}   # previous thumb in the buffer ()
#      next :
#      el   : {thumb$}  # element in the dom of the thumb
#      rank : {integer} # rank of the corresponding image
#   Element of the buffer, keeps a reference (el) to the thumb element inserted
#   in the DOM.
#
# 8/ safeZone
#
################################################################################

################################################################################
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
        # set position
        @viewPort$.style.position = 'relative'
        @thumbs$.style.position   = 'absolute'
        ####
        # controlers
        @buffer   = @_initBuffer()
        ####
        # adapt buffer to the initial geometry when we receive the array of
        # photos
        Photo.getPhotoArray (res) =>
            @months  = res
            if @isInited
                ####
                # create DOM_controler
                @DOM_controler = @_DOM_controlerInit()
            else
                @isPhotoArrayLoaded = true
            return true


    init : () =>
        ####################### XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
        # REMOVE FOR PRODUCTION
        window.longList = this
        @activated = true
        ####################### XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

        if @isPhotoArrayLoaded
            ####
            # create DOM_controler
            @DOM_controler = @_DOM_controlerInit()
        else
            @isInited = true
        return true


    getSelectedID : () =>
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


################################################################################
## PRIVATE SECTION ##

    _initBuffer : ()->
        thumb$ = document.createElement('div')
        @thumbs$.appendChild(thumb$)
        thumb$.setAttribute('class', 'long-list-thumb')
        @nThumbs = 1
        thumb =
            prev : null
            next : null
            el   : thumb$
            rank : null
        thumb.prev = thumb
        thumb.next = thumb

        return {
                first   : thumb
                firstRk : - 1
                last    : thumb
                lastRk  : - 1
                nextLastRk      : null
                nextLastCol     : null
                nextLastY       : null
                nextLastMonthRk : null
            }



    ####################### XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    # REMOVE FOR PRODUCTION
    _activate:(doActivate) ->
        @activated = doActivate

    _print:() ->
        @_DOM_controler.print()

    ####################### XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


    _DOM_controlerInit: () ->

        print = () ->
            console.log 'safeZone_startPt', safeZone_startPt
            console.log 'safeZone_endPt', safeZone_startPt
            console.log 'nThumbsPerRow', nThumbsPerRow
            console.log 'nThumbsInSafeZone', nThumbsInSafeZone
            console.log 'nRowsInSafeZoneMargin', nRowsInSafeZoneMargin


        #######################
        # global variables
        buffer                = @buffer
        nThumbsPerRow         = 0
        nRowsInSafeZoneMargin = 0
        monthHeaderHeight     = 0
        nThumbsInSafeZone     = 0
        viewPortDim           = null
        safeZone_startPt      = {}
        safeZone_endPt        = {}
        months                = @months


        _scrollHandler = (e) =>
            ####################### XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
            # REMOVE FOR PRODUCTION
            if !@activated
                @noScrollScheduled = true
                return true
            ####################### XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

            if @noScrollScheduled
                setTimeout(_adaptBuffer,350)
                @noScrollScheduled = false


        _clickHandler= (e) =>
            e.target.classList.toggle('selectedThumb')


        _resizeHandler= ()=>
            viewPortDim   = @viewPort$.getBoundingClientRect()
            nThumbsPerRow = Math.floor(viewPortDim.width / @thumbWidth)
            # always at least 10 rows of thumbs in the buffer
            nRowsInViewPort         = Math.ceil(viewPortDim.height /@thumbHeight)
            nRowsInSafeZoneMargin   = Math.round(1.5 * nRowsInViewPort)
            nThumbsInSafeZoneMargin = nRowsInSafeZoneMargin * nThumbsPerRow
            # height reserved between two months
            monthHeaderHeight = 40
            nThumbsInViewPort = nRowsInViewPort * nThumbsPerRow
            nThumbsInSafeZone = nThumbsInSafeZoneMargin * 2 + nThumbsInViewPort

            nextY   = 0
            nPhotos = 0
            for month in @months
                month.nRows        = Math.ceil(month.nPhotos / nThumbsPerRow)
                month.height       = month.nRows * @thumbHeight + monthHeaderHeight
                month.y            = nextY
                month.yBottom      = nextY + month.height
                month.firstPhotoRk = nPhotos
                month.lastPhotoRk  = nPhotos + month.nPhotos - 1
                nextY   += month.height
                nPhotos += month.nPhotos
            @nPhotos = nPhotos
            @thumbs$.style.setProperty('height', nextY + 'px')


        #launched at init and by _scrollHandler event
        _adaptBuffer = () =>
            bfr = buffer
            _computeSafeZone()
            # safeZone = {firstRk, firstY, firstMonthRk, lastRk}
            safeZone =
                firstRk      : safeZone_startPt.rank
                firstY       : safeZone_startPt.y
                firstMonthRk :safeZone_startPt.monthRk
                lastRk       : safeZone_endPt.rank
            console.log safeZone
            console.log bfr
            if safeZone.lastRk > bfr.lastRk
                # the safeZone is going down and the bottom of the safeZone is empty
                #
                # nToFind = number of thumbs to find (by reusing thumbs from the
                # buffer or by creation new ones) in order to fill the bottom of
                # the safeZone
                nToFind = Math.min(safeZone.lastRk - bfr.lastRk, nThumbsInSafeZone)
                # the  available thumbs are the ones in the buffer and before the
                # safeZone
                # (rank greater than buffer.firstRk but lower than safeZone.firtsRk)
                nAvailable = safeZone.firstRk - bfr.firstRk
                if nAvailable < 0
                    nAvailable = 0
                if nAvailable > @nThumbs
                    nAvailable = @nThumbs

                nToCreate = nToFind - nAvailable
                nToMove   = nToFind - nToCreate

                if safeZone.firstRk < bfr.nextLastRk
                    # part of the buffer is in the safe zone : add thumbs after last
                    # thumb of the buffer
                    targetRk      = bfr.nextLastRk
                    targetMonthRk = bfr.nextLastMonthRk
                    targetCol     = bfr.nextLastCol
                    targetY       = bfr.nextLastY

                else
                    # the safeZone is completely after the buffer : ass thumbs at
                    # the beginning of the safeZone.
                    targetRk      = safeZone.firstRk
                    targetCol     = 0
                    targetMonthRk = safeZone.firstMonthRk
                    targetY       = safeZone.firstY

                if nToCreate > 0
                    [targetY, targetCol, targetMonthRk] =
                        _createThumbsBottom( nToCreate     ,
                                              targetRk     ,
                                              targetCol    ,
                                              targetY      ,
                                              targetMonthRk  )
                    targetRk += nToCreate

                if nToMove > 0
                    _moveBufferToBottom( nToMove        ,
                                          targetRk      ,
                                          targetCol     ,
                                          targetY       ,
                                          targetMonthRk  )

            # if safeZone.firstRk < bfr.firstRk

            @noScrollScheduled = true


        _computeSafeZone = () =>
            _initViewPort_startPt()
            # setSafeZone_startPt()
            _moveUp_SafeZone_startPt_ofNRows()
            hasReachedLastPhoto = _setViewPort_endPt()
            if hasReachedLastPhoto
                _moveUp_SafeZone_startPt_toRank(@nPhotos-nThumbsInSafeZone)

            # return {firstRk, firstY, firstMonthRk, lastRk}


        _initViewPort_startPt = ()=>
            Y = @viewPort$.scrollTop
            for month, monthRk in @months
                if month.yBottom > Y
                    break
            inMonthRowRk = Math.floor((Y-month.y-monthHeaderHeight)/@thumbHeight)
            if inMonthRowRk < 0
                # happens if the viewport is in the header of a month
                inMonthRowRk = 0
            safeZone_startPt.rank         = month.firstPhotoRk + inMonthRowRk * nThumbsPerRow
            safeZone_startPt.y            = month.y + monthHeaderHeight + inMonthRowRk * @thumbHeight
            safeZone_startPt.monthRk      = monthRk
            safeZone_startPt.inMonthRowRk = inMonthRowRk


        _moveUp_SafeZone_startPt_ofNRows = () =>

            inMonthRowRk = safeZone_startPt.inMonthRowRk - nRowsInSafeZoneMargin

            if inMonthRowRk >= 0
                # the row that we are looking for is in the current month
                month = @months[safeZone_startPt.monthRk]
                safeZone_startPt.rank = month.firstPhotoRk + inMonthRowRk * nThumbsPerRow
                safeZone_startPt.y    = month.y + monthHeaderHeight + inMonthRowRk * @thumbHeight
                safeZone_startPt.inMonthRowRk = inMonthRowRk
                return

            else
                # the row that we are looking for is before the current month
                rowsSeen = safeZone_startPt.inMonthRowRk
                for j in [safeZone_startPt.monthRk-1..0] by -1
                    month = @months[j]
                    if rowsSeen + month.nRows >= nRowsInSafeZoneMargin
                        inMonthRowRk = month.nRows - nRowsInSafeZoneMargin + rowsSeen
                        safeZone_startPt.rank = month.firstPhotoRk + inMonthRowRk * nThumbsPerRow
                        safeZone_startPt.y    = month.y + monthHeaderHeight + inMonthRowRk * @thumbHeight
                        safeZone_startPt.monthRk = j
                        safeZone_startPt.inMonthRowRk = inMonthRowRk
                        return

                    else
                        rowsSeen += month.nRows

            safeZone_startPt.rank         = 0
            safeZone_startPt.y            = monthHeaderHeight
            safeZone_startPt.monthRk      = 0
            safeZone_startPt.inMonthRowRk = 0


        _setViewPort_endPt = () =>
            lastRk = safeZone_startPt.rank + nThumbsInSafeZone - 1
            if lastRk >= @nPhotos
                lastRk = @nPhotos - 1
                safeZone_endPt.rank = lastRk
                return true
            safeZone_endPt.rank = lastRk
            return false


        _moveUp_SafeZone_startPt_toRank = ()=>
            months= @months
            monthRk = months.length - 1
            thumbsSeen = 0
            thumbsTarget = nThumbsInSafeZone
            for monthRk in [monthRk..0] by -1
                month = months[monthRk]
                thumbsSeen += month.nPhotos
                if thumbsSeen >= thumbsTarget
                    break

            rk           = @nPhotos - thumbsTarget
            inMonthRk    = rk - month.firstPhotoRk
            inMonthRowRk = Math.floor(inMonthRk / nThumbsPerRow)

            safeZone_startPt.monthRk      = monthRk
            safeZone_startPt.inMonthRowRk = inMonthRowRk
            safeZone_startPt.rank         = rk
            safeZone_startPt.y            = month.y + monthHeaderHeight + inMonthRowRk * @thumbHeight


        _createThumbsBottom = (nToCreate, startRk, startCol, startY, monthRk) =>
            rowY    = startY
            col     = startCol
            month   = @months[monthRk]
            localRk = startRk - month.firstPhotoRk
            for rk in [startRk..startRk+nToCreate-1] by 1
                thumb$ = document.createElement('div')
                thumb$.setAttribute('class', 'long-list-thumb')
                thumb =
                    next : buffer.last
                    prev : buffer.first
                    el   : thumb$
                    rank : rk
                buffer.first.next = thumb
                buffer.last.prev  = thumb
                buffer.last       = thumb
                thumb$.textContent = rk + ' ' + month.month.slice(0,4) + '-' + month.month.slice(4)
                style      = thumb$.style
                style.top  = rowY + 'px'
                style.left = col  *  @thumbWidth + 'px'
                @thumbs$.appendChild(thumb$)
                @nThumbs += 1
                localRk += 1
                if localRk == month.nPhotos
                    # jump to a new month
                    monthRk += 1
                    month    = @months[monthRk]
                    localRk  = 0
                    col      = 0
                    rowY    += monthHeaderHeight + @thumbHeight
                else
                    # change of column or back to a new row if we are at last column
                    col  += 1
                    if col is nThumbsPerRow
                        rowY += @thumbHeight
                        col   = 0
            buffer.lastRk = rk - 1
            # store the parameters of the thumb that is just after the last one
            buffer.nextLastRk      = rk
            buffer.nextLastCol     = col
            buffer.nextLastY       = rowY
            buffer.nextLastMonthRk = monthRk

            return [rowY, col, monthRk]


        _moveBufferToBottom= (nToMove, startRk, startCol, startY, monthRk)=>
            rowY    = startY
            col     = startCol
            month   = @months[monthRk]
            localRk = startRk - month.firstPhotoRk
            for rk in [startRk..startRk+nToMove-1] by 1
                thumb$ = buffer.first.el
                buffer.last  = buffer.first
                buffer.first = buffer.first.prev
                buffer.firstRk = buffer.first.rank
                thumb$.textContent = rk + ' ' + month.month.slice(0,4) + '-' + month.month.slice(4) #+ ' (moved from top to bottom)'
                buffer.last.rank = rk
                style      = thumb$.style
                style.top  = rowY + 'px'
                style.left = col  *  @thumbWidth + 'px'
                localRk += 1
                if localRk == month.nPhotos
                    # jump to a new month
                    monthRk += 1
                    month    = @months[monthRk]
                    localRk  = 0
                    col      = 0
                    rowY    += monthHeaderHeight + @thumbHeight
                else
                    # go to next column or to a new row if we are at last column
                    col  += 1
                    if col is nThumbsPerRow
                        rowY += @thumbHeight
                        col   = 0
            buffer.lastRk = rk - 1
            # store the parameters of the thumb that is just after the last one
            buffer.nextLastRk      = rk
            buffer.nextLastCol     = col
            buffer.nextLastY       = rowY
            buffer.nextLastMonthRk = monthRk




        ####
        # Get thumbs dimensions.
        # It is possible only when the longList is inserted into the DOM, that's
        # why we had to wait for _init() which occurs after both the reception
        # of the array of photo and after the parent view has launched init().
        thumbDim     = @buffer.first.el.getBoundingClientRect()
        @thumbWidth  = thumbDim.width
        @thumbHeight = thumbDim.height
        ####
        # Adapt the geometry and then the buffer
        _resizeHandler()
        _adaptBuffer()
        ####
        # bind events
        @thumbs$.addEventListener(   'click'  , _clickHandler )
        @viewPort$.addEventListener( 'scroll' , _scrollHandler )



        return {_adaptBuffer, print}





