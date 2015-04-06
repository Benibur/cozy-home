Photo    = require '../models/photo'


module.exports = class LongList

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
        ####################### XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
        # REMOVE FOR PRODUCTION
        window.longList = this
        @activated = false
        ####################### XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

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
        thumb.prev = thumb
        thumb.next = thumb

        return first : thumb, last  : thumb, lastRk : -1, firstRk : -1


    ####################### XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    # REMOVE FOR PRODUCTION
    _activate:(doActivate) ->
        @activated = doActivate
    ####################### XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


    _DOM_controlerInit: () ->

        buffer = @buffer
        nThumbsPerRow = 0
        # nRowsInViewPort = 0
        nRowsInSafeZoneMargin = 0
        monthHeaderHeight = 0
        nThumbsInSafeZone = 0
        viewPortDim = null
        safeZone_startPt = {}
        safeZone_endPt   = {}
        months = @months


        _scrollHandler = (e) =>
            ####################### XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
            # REMOVE FOR PRODUCTION
            if !@activated
                @noScrollScheduled = true
                return true
            ####################### XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

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
                # safeZone_startPt.rank      = month.firstPhotoRk + inMonthRowRk * nThumbsPerRow
                # safeZone_startPt.y         = month.y + monthHeaderHeight + inMonthRowRk * @thumbHeight
                # safeZone_startPt.monthRk   = monthRk
                # safeZone_startPt.inMonthRowRk
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
                        _createThumbsBottom( nToCreate    ,
                                              targetRk     ,
                                              targetCol    ,
                                              targetY      ,
                                              targetMonthRk  )
                    targetRk += nToCreate

                if nToMove > 0
                    _moveBufferToBottom( nToMove       ,
                                          targetRk      ,
                                          targetCol     ,
                                          targetY       ,
                                          targetMonthRk  )

            # if safeZone.firstRk < bfr.firstRk


            @noScrollScheduled = true


        _computeSafeZone_ORIGINAL = () =>
            [firstRk,firstY, firstMonthRk] = _getPhotoRk_AtY_minusN( @viewPort$.scrollTop , nRowsInSafeZoneMargin)
            if firstRk < 0
                firstRk = 0
            lastRk = firstRk + nThumbsInSafeZone - 1
            if lastRk > @nPhotos
                lastRk = @nPhotos
            console.log 'safeZone:', {firstRk, firstY, firstMonthRk, lastRk}
            return {firstRk, firstY, firstMonthRk, lastRk}


        _computeSafeZone = () =>
            initViewPort_startPt()
            # setSafeZone_startPt()
            moveUp_SafeZone_startPt_ofNRows()
            hasReachedLastPhoto = setViewPort_endPt()
            if hasReachedLastPhoto
                moveUp_SafeZone_startPt_toRank(@nPhotos-nThumbsInSafeZone)

            # return {firstRk, firstY, firstMonthRk, lastRk}

        initViewPort_startPt = ()=>
            Y = @viewPort$.scrollTop
            for month, monthRk in @months
                if month.yBottom > Y
                    break
            inMonthRowRk = Math.floor((Y-month.y-monthHeaderHeight)/@thumbHeight)
            if inMonthRowRk < 0
                # happens if the viewport is in the header of a month
                inMonthRowRk = 0
            safeZone_startPt.rank      = month.firstPhotoRk + inMonthRowRk * nThumbsPerRow
            safeZone_startPt.y         = month.y + monthHeaderHeight + inMonthRowRk * @thumbHeight
            safeZone_startPt.monthRk   = monthRk
            safeZone_startPt.inMonthRowRk = inMonthRowRk


        moveUp_SafeZone_startPt_ofNRows = () =>
            inMonthRowRk = safeZone_startPt.inMonthRowRk - nRowsInSafeZoneMargin

            # if  (@nPhotos - )

            if inMonthRowRk >= 0
                # the row that we are looking for is in the current month
                month = @months[safeZone_startPt.monthRk]
                safeZone_startPt.rank = month.firstPhotoRk + inMonthRowRk * nThumbsPerRow
                safeZone_startPt.y    = month.y + monthHeaderHeight + inMonthRowRk * @thumbHeight
                found = true
                # safeZone_startPt.monthRk = safeZone_startPt.monthRk
                # return [
                #     month.firstPhotoRk + inMonthRowRk * nThumbsPerRow ,
                #     month.y + monthHeaderHeight + inMonthRowRk * @thumbHeight,
                #     i
                # ]
            else
                # the row that we are looking for is before the current month
                rowsSeen = safeZone_startPt.rank
                for j in [safeZone_startPt.monthRk-1..0] by -1
                    month = @months[j]
                    if rowsSeen + month.nRows >= nRowsInSafeZoneMargin
                        inMonthRowRk = month.nRows - nRowsInSafeZoneMargin + rowsSeen

                        firstRk      = month.firstPhotoRk + inMonthRowRk * nThumbsPerRow
                        firstY       = month.y + monthHeaderHeight + inMonthRowRk * @thumbHeight
                        firstMonthRk = j
                        found = true
                        break
                        # return [
                        #     month.firstPhotoRk + inMonthRowRk * nThumbsPerRow ,
                        #     month.y + monthHeaderHeight + inMonthRowRk * @thumbHeight,
                        #     j
                        # ]
                    else
                        rowsSeen += month.nRows

            if !found
                firstRk      = 0
                firstY       = monthHeaderHeight
                firstMonthRk = 0

            # return [0, monthHeaderHeight,0]


            safeZone_startPt.rank      = firstRk
            safeZone_startPt.y         = firstY
            safeZone_startPt.monthRk   = firstMonthRk
            safeZone_startPt.inMonthRowRk = inMonthRowRk

            # return [firstRk, firstY, inMonthRowRk]

        setViewPort_endPt = () =>
            lastRk = safeZone_startPt.rank + nThumbsInSafeZone - 1
            if lastRk >= @nPhotos
                lastRk = @nPhotos - 1
                safeZone_endPt.rank = lastRk
                return true
            safeZone_endPt.rank = lastRk
            return false
            # console.log 'safeZone:', {firstRk, firstY, firstMonthRk, lastRk}
            # return {firstRk, firstY, firstMonthRk, lastRk}


        moveUp_SafeZone_startPt_toRank = ()=>
            # Y = @viewPort$.scrollTop
            # RK = safeZone_endPt.rank
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
            inMonthRk    = rk - month.firstRk
            inMonthRowRk = Math.ceil(inMonthRk / nThumbsPerRow)

            safeZone_startPt.monthRk      = monthRk
            safeZone_startPt.inMonthRowRk = inMonthRowRk
            safeZone_startPt.rank         = rk
            safeZone_startPt.y            = month.y + inMonthRowRk * @thumbHeight


        _getPhotoRk_AtY = (Y) =>
            for month, monthRk in @months
                if month.yBottom > Y
                    break
            rowLocalRk = Math.floor((Y-month.y-monthHeaderHeight)/@thumbHeight)
            if rowLocalRk < 0
                # happens if the viewport is in the header of a month
                rowLocalRk = 0
            return [ month.firstPhotoRk + rowLocalRk * nThumbsPerRow          ,
                     month.y + monthHeaderHeight + rowLocalRk * @thumbHeight ,
                     monthRk
                    ]


        # returns [firstRk,firstY, firstMonthRk]
        _getPhotoRk_AtY_minusN = (Y, minusN) =>
            for month, i in @months
                if month.yBottom > Y
                    break
            rowY = Math.floor((Y-month.y-monthHeaderHeight)/@thumbHeight)
            if rowY < 0
                # happens if the viewport is in the header of a month
                rowY = 0
            row_minuxN = rowY - minusN

            # if  (@nPhotos - )

            if row_minuxN >= 0
                # the row that we are looking for is in the current month
                firstRk      = month.firstPhotoRk + row_minuxN * nThumbsPerRow
                firstY       = month.y + monthHeaderHeight + row_minuxN * @thumbHeight
                firstMonthRk = i
                # return [
                #     month.firstPhotoRk + row_minuxN * nThumbsPerRow ,
                #     month.y + monthHeaderHeight + row_minuxN * @thumbHeight,
                #     i
                # ]
            else
                # the row that we are looking for is before the current month
                rowsSeen = rowY
                for j in [i-1..0] by -1
                    month = @months[j]
                    if rowsSeen + month.nRows >= minusN
                        row_minuxN = month.nRows - minusN + rowsSeen

                        firstRk      = month.firstPhotoRk + row_minuxN * nThumbsPerRow
                        firstY       = month.y + monthHeaderHeight + row_minuxN * @thumbHeight
                        firstMonthRk = j
                        break
                        # return [
                        #     month.firstPhotoRk + row_minuxN * nThumbsPerRow ,
                        #     month.y + monthHeaderHeight + row_minuxN * @thumbHeight,
                        #     j
                        # ]
                    else
                        rowsSeen += month.nRows

            if !firstRk
                firstRk      = 0
                firstY       = monthHeaderHeight
                firstMonthRk = 0

            # return [0, monthHeaderHeight,0]



            return [firstRk, firstY, firstMonthRk]


        _createThumbsBottom = (nToCreate, startRk, startCol, startY, monthRk) =>
            bfr     = @buffer
            rowY    = startY
            col     = startCol
            month   = @months[monthRk]
            localRk = startRk - month.firstPhotoRk
            for rk in [startRk..startRk+nToCreate-1] by 1
                thumb$ = document.createElement('div')
                thumb$.setAttribute('class', 'long-list-thumb')
                thumb =
                    next : bfr.last
                    prev : bfr.first
                    el   : thumb$
                    rank : rk
                bfr.first.next = thumb
                bfr.last.prev  = thumb
                bfr.last       = thumb
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
            bfr.lastRk = rk - 1
            # store the parameters of the thumb that is just after the last one
            bfr.nextLastRk      = rk
            bfr.nextLastCol     = col
            bfr.nextLastY       = rowY
            bfr.nextLastMonthRk = monthRk

            return [rowY, col, monthRk]


        _moveBufferToBottom= (nToMove, startRk, startCol, startY, monthRk)=>
            bfr     = @buffer
            rowY    = startY
            col     = startCol
            month   = @months[monthRk]
            localRk = startRk - month.firstPhotoRk
            for rk in [startRk..startRk+nToMove-1] by 1
                thumb$ = bfr.first.el
                bfr.last  = bfr.first
                bfr.first = bfr.first.prev
                bfr.firstRk = bfr.first.rank
                thumb$.textContent = rk + ' ' + month.month.slice(0,4) + '-' + month.month.slice(4) + ' (moved from top to bottom)'
                bfr.last.rank = rk
                style      = thumb$.style
                style.top  = rowY + 'px'
                style.left = col  *  @thumbWidth + 'px'
                # @thumbs$.appendChild(thumb$)
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
            bfr.lastRk = rk - 1
            # store the parameters of the thumb that is just after the last one
            bfr.nextLastRk      = rk
            bfr.nextLastCol     = col
            bfr.nextLastY       = rowY
            bfr.nextLastMonthRk = monthRk




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



        return {_adaptBuffer}





