Photo    = require '../models/photo'

ACTIVATED = true
THROTTLE  = 350

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
# 1/ syntax
#   . a variable name ending with a '$' is a reference to a node in the DOM
#   . in a variable name, "Rk" means "rank"
#   . in a variable name, Pt means "Pointer". The safe zone is define by a
#     start pointer and an end pointer, themselves defined
#     by a rank, y monthRk and inMonthRk
#
# 2/ months
#   [ {nPhotos:45, month:"201503"}, ... ]
# array of all the months having a photo.
# months.length = number of months having a photo
# months[n] = {
#   nPhotos : number of photo of this month
#   month   : string, the month, format : "201503"
#   label$  : element in the DOM in the header of the month
#   nRows   : number of rows in the month
#   height  : in px
#   y       : y from the top of the thumbs container (@thumbs$), in px
#   yBottom : in px
#   firstRk : integer, rank of the first photo of the month
#   lastRk  : integer, rank of the last  photo of the month
# }
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
#   safeZone_startPt
#         rank         :
#         monthRk      :
#         inMonthRow :
#         col          :
#         y            :
#
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
        Photo.getPhotoArray (error, res) =>
            console.log 'longlist get an answer!', res
            @months  = res
            if @isInited
                ####
                # create DOM_controler
                @DOM_controler = @_DOM_controlerInit()
            else
                @isPhotoArrayLoaded = true
            return true


    init : () =>
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


    _DOM_controlerInit: () ->

        #######################
        # global variables
        months                = @months
        buffer                = @buffer
        cellPadding           = 4
        monthHeaderHeight     = 30
        monthTopPadding = monthHeaderHeight + cellPadding

        marginLeft            = null
        thumbWidth            = null
        thumbHeight           = null
        colWidth              = null
        rowHeight             = null
        nThumbsPerRow         = null
        nRowsInSafeZoneMargin = null
        nThumbsInSafeZone     = null
        viewPortDim           = null
        safeZone_startPt      = {}
        safeZone_endPt        = {}


        _scrollHandler = (e) =>
            if @noScrollScheduled
                setTimeout(_adaptBuffer,THROTTLE)
                @noScrollScheduled = false


        _clickHandler= (e) =>
            thumb$ = e.target
            thumb$.classList.toggle('selectedThumb')
            if @state.selected[thumb$.dataset.rank]
                @state.selected[thumb$.dataset.rank]=false
            else
                @state.selected[thumb$.dataset.rank]=true


        _resizeHandler= ()=>
            width = @viewPort$.clientWidth
            nThumbsPerRow = Math.floor((width-cellPadding)/colWidth)
            marginLeft = cellPadding + Math.round((
                width - nThumbsPerRow * colWidth - cellPadding)/2)
            # always at least 10 rows of thumbs in the buffer
            nRowsInViewPort         = Math.ceil(
                @viewPort$.clientHeight /rowHeight)
            nRowsInSafeZoneMargin   = Math.round(1.5 * nRowsInViewPort)
            nThumbsInSafeZoneMargin = nRowsInSafeZoneMargin * nThumbsPerRow # todo bja : quelle variable est à utiliser ? nbr de lignes ou de thumbs?
            # height reserved between two months
            # monthHeaderHeight = 40
            nThumbsInViewPort = nRowsInViewPort * nThumbsPerRow
            nThumbsInSafeZone = nThumbsInSafeZoneMargin * 2 + nThumbsInViewPort

            nextY   = 0
            nPhotos = 0
            for month in @months
                nPhotosInMonth     = month.nPhotos
                month.nRows        = Math.ceil(nPhotosInMonth / nThumbsPerRow)
                month.height       = monthTopPadding + month.nRows*rowHeight
                month.y            = nextY
                month.yBottom      = nextY + month.height
                month.firstRk      = nPhotos
                month.lastRk       = nPhotos + nPhotosInMonth - 1
                month.lastThumbCol = (nPhotosInMonth-1) % nThumbsPerRow
                nextY   += month.height
                nPhotos += nPhotosInMonth
            @nPhotos = nPhotos
            @thumbs$.style.setProperty('height', nextY + 'px')


        #launched at init and by _scrollHandler
        ###*
         * [_adaptBuffer description]
         * @return {[type]} [description]
        ###
        _adaptBuffer = () =>
            @noScrollScheduled = true
            bufr = buffer
            _computeSafeZone()
            safeZone =
                firstRk      : safeZone_startPt.rank
                firstMonthRk : safeZone_startPt.monthRk
                firstY       : safeZone_startPt.y
                lastRk       : safeZone_endPt.rank
                endCol       : safeZone_endPt.col
                endMonthRk   : safeZone_endPt.monthRk
                endY         : safeZone_endPt.y
            console.log safeZone
            console.log bufr
            if safeZone.lastRk > bufr.lastRk
                # the safeZone is going down and the bottom of the safeZone is
                # bellow the bottom of the buffer
                #
                # nToFind = number of thumbs to find (by reusing thumbs from the
                # buffer or by creation new ones) in order to fill the bottom of
                # the safeZone
                nToFind = Math.min(safeZone.lastRk - bufr.lastRk, nThumbsInSafeZone)
                # the  available thumbs are the ones in the buffer and above
                # the safeZone
                # (rank greater than buffer.firstRk but lower
                # than safeZone.firtsRk)
                nAvailable = safeZone.firstRk - bufr.firstRk
                if nAvailable < 0
                    nAvailable = 0
                if nAvailable > @nThumbs
                    nAvailable = @nThumbs

                nToCreate = nToFind - nAvailable
                nToMove   = nToFind - nToCreate

                if safeZone.firstRk < bufr.nextLastRk
                    # part of the buffer is in the safe zone : add thumbs after
                    # the last thumb of the buffer
                    _getBufferNextLast()
                    targetRk      = bufr.nextLastRk
                    targetMonthRk = bufr.nextLastMonthRk
                    targetCol     = bufr.nextLastCol
                    targetY       = bufr.nextLastY

                else
                    # the safeZone is completely bellow the buffer : add thumbs
                    # bellow the top of the safeZone.
                    targetRk      = safeZone.firstRk
                    targetCol     = 0
                    targetMonthRk = safeZone.firstMonthRk
                    targetY       = safeZone.firstY

                if nToCreate > 0
                    Photo.listFromFiles targetRk, nToCreate, (res, error) ->
                        console.log res


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

            else if safeZone.firstRk < bufr.firstRk
                # the safeZone is going up and the top of the safeZone is above
                # the buffer
                #
                # nToFind = number of thumbs to find (by reusing thumbs from the
                # buffer or by creation new ones) in order to fill the top of
                # the safeZone
                nToFind = Math.min(bufr.firstRk - safeZone.firstRk, nThumbsInSafeZone)
                # the  available thumbs are the ones in the buffer and under
                # the safeZone
                # (rank smaller than buffer.lastRk but higher
                # than safeZone.lastRk)
                nAvailable = bufr.lastRk - safeZone.lastRk
                if nAvailable < 0
                    nAvailable = 0
                if nAvailable > @nThumbs
                    nAvailable = @nThumbs

                nToCreate = nToFind - nAvailable
                nToMove   = nToFind - nToCreate

                if safeZone.lastRk >= bufr.firstRk
                    # part of the buffer is in the safe zone : add thumbs above
                    # the first thumb of the buffer
                    _getBufferNextFirst()
                    targetRk      = bufr.nextFirstRk
                    targetMonthRk = bufr.nextFirstMonthRk
                    targetCol     = bufr.nextFirstCol
                    targetY       = bufr.nextFirstY

                else
                    # the safeZone is completely above the buffer : add thumbs
                    # above the bottom of the safeZone.
                    targetRk      = safeZone.lastRk
                    targetCol     = safeZone.endCol
                    targetMonthRk = safeZone.endMonthRk
                    targetY       = safeZone.endY

                if nToCreate > 0
                    throw new Error('It should not be used in the current implementation')
                    [targetY, targetCol, targetMonthRk] =
                        _createThumbsTop(  nToCreate     ,
                                           targetRk     ,
                                           targetCol    ,
                                           targetY      ,
                                           targetMonthRk  )
                    targetRk += nToCreate

                if nToMove > 0
                    _moveBufferToTop( nToMove       ,
                                      targetRk      ,
                                      targetCol     ,
                                      targetY       ,
                                      targetMonthRk  )


        _getBufferNextFirst = ()=>
            bufr = buffer
            nextFirstRk     = bufr.firstRk - 1
            if nextFirstRk == -1
                return
            bufr.nextFirstRk     = nextFirstRk

            initMonthRk = safeZone_endPt.monthRk
            for monthRk in [initMonthRk..0] by -1
                month = months[monthRk]
                if month.firstRk <= nextFirstRk
                    break
            bufr.nextFirstMonthRk = monthRk
            localRk               = nextFirstRk - month.firstRk
            inMonthRow            = Math.floor(localRk/nThumbsPerRow)
            bufr.nextFirstY       = month.y + monthTopPadding + inMonthRow*rowHeight
            bufr.nextFirstCol     = localRk % nThumbsPerRow


        _getBufferNextLast = ()=>
            bufr = buffer
            nextLastRk     = bufr.lastRk + 1
            if nextLastRk == @nPhotos
                return
            bufr.nextLastRk = nextLastRk

            initMonthRk = safeZone_startPt.monthRk
            for monthRk in [initMonthRk..months.length-1] by 1
                month = months[monthRk]
                if nextLastRk <= month.lastRk
                    break
            bufr.nextLastMonthRk = monthRk
            localRk              = nextLastRk - month.firstRk
            inMonthRow           = Math.floor(localRk/nThumbsPerRow)
            bufr.nextLastY       = month.y + monthTopPadding + inMonthRow*rowHeight
            bufr.nextLastCol     = localRk % nThumbsPerRow


        _computeSafeZone = () =>
            _initViewPort_startPt()
            _moveUp_SafeZone_startPt_ofNRows()
            hasReachedLastPhoto = _setSafeZone_endPt()
            if hasReachedLastPhoto
                _moveUp_SafeZone_startPt_toRank()


        _initViewPort_startPt = ()=>
            Y = @viewPort$.scrollTop
            for month, monthRk in @months
                if month.yBottom > Y
                    break
            inMonthRow = Math.floor((Y-month.y-monthTopPadding)/rowHeight)
            if inMonthRow < 0
                # happens if the viewport is in the header of a month
                inMonthRow = 0
            safeZone_startPt.rank         = month.firstRk + inMonthRow * nThumbsPerRow
            safeZone_startPt.y            = month.y + monthTopPadding + inMonthRow * rowHeight
            safeZone_startPt.monthRk      = monthRk
            safeZone_startPt.inMonthRow = inMonthRow
            safeZone_startPt.col          = 0


        _moveUp_SafeZone_startPt_ofNRows = () =>

            inMonthRow = safeZone_startPt.inMonthRow - nRowsInSafeZoneMargin

            if inMonthRow >= 0
                # the row that we are looking for is in the current month
                # (monthRk and col are not changed then)
                month = @months[safeZone_startPt.monthRk]
                safeZone_startPt.rank = month.firstRk + inMonthRow * nThumbsPerRow
                safeZone_startPt.y    = month.y + monthTopPadding + inMonthRow*rowHeight
                safeZone_startPt.inMonthRow = inMonthRow
                return

            else
                # the row that we are looking for is before the current month
                # (col remains 0)
                rowsSeen = safeZone_startPt.inMonthRow
                for j in [safeZone_startPt.monthRk-1..0] by -1
                    month = @months[j]
                    if rowsSeen + month.nRows >= nRowsInSafeZoneMargin
                        inMonthRow                  = month.nRows - nRowsInSafeZoneMargin + rowsSeen
                        safeZone_startPt.rank       = month.firstRk + inMonthRow * nThumbsPerRow
                        safeZone_startPt.y          = month.y + monthTopPadding + inMonthRow*rowHeight
                        safeZone_startPt.inMonthRow = inMonthRow
                        safeZone_startPt.monthRk    = j
                        return

                    else
                        rowsSeen += month.nRows

            safeZone_startPt.rank       = 0
            safeZone_startPt.monthRk    = 0
            safeZone_startPt.inMonthRow = 0
            safeZone_startPt.col        = 0
            safeZone_startPt.y          = monthTopPadding




        ###*
         * Returns true if the safeZone start pointer should be before the first
         * thumb
        ###
        _moveUp_SafeZone_startPt_ofNThumbs = (n) =>

            targetRk = safeZone_startPt.rank - n

            if targetRk < 0
                safeZone_startPt.rank       = 0
                safeZone_startPt.monthRk    = 0
                safeZone_startPt.inMonthRow = 0
                safeZone_startPt.col        = 0
                safeZone_startPt.y          = monthTopPadding
                return true


            for monthRk in [safeZone_startPt.monthRk-1..0] by -1
                month = months[monthRk]
                if targetRk <= month.lastRk
                    safeZone_startPt.rank       = targetRk
                    safeZone_startPt.monthRk    = monthRk
                    inMonthRk                   = targetRk - month.firstRk
                    inMonthRow                  = Math.floor(inMonthRk/nThumbsPerRow)
                    safeZone_startPt.inMonthRow = inMonthRow
                    safeZone_startPt.col        = inMonthRk % nThumbsPerRow
                    safeZone_startPt.y          = month.y + monthTopPadding + inMonthRow*rowHeight
                    return false

            # if months[safeZone_startPt.monthRk].firstRk <= targetRk



            if inMonthRow >= 0
                # the row that we are looking for is in the current month
                # (monthRk and col are not changed then)
                month = @months[safeZone_startPt.monthRk]
                safeZone_startPt.rank = month.firstRk + inMonthRow * nThumbsPerRow
                safeZone_startPt.y    = month.y + monthTopPadding + inMonthRow*rowHeight
                safeZone_startPt.inMonthRow = inMonthRow
                return

            else
                # the row that we are looking for is before the current month
                # (col remains 0)
                rowsSeen = safeZone_startPt.inMonthRow
                for j in [safeZone_startPt.monthRk-1..0] by -1
                    month = @months[j]
                    if rowsSeen + month.nRows >= nRowsInSafeZoneMargin
                        inMonthRow = month.nRows - nRowsInSafeZoneMargin + rowsSeen
                        safeZone_startPt.rank = month.firstRk + inMonthRow * nThumbsPerRow
                        safeZone_startPt.y    = month.y + monthTopPadding + inMonthRow*rowHeight
                        safeZone_startPt.inMonthRow = inMonthRow
                        safeZone_startPt.monthRk = j
                        return

                    else
                        rowsSeen += month.nRows

            safeZone_startPt.rank         = 0
            safeZone_startPt.monthRk      = 0
            safeZone_startPt.inMonthRow = 0
            safeZone_startPt.col          = 0
            safeZone_startPt.y            = monthTopPadding


        ###*
         * Returns true if the safeZone end pointer should be after the last
         * thumb
        ###
        _setSafeZone_endPt = () =>
            lastRk = safeZone_startPt.rank + nThumbsInSafeZone - 1
            if lastRk >= @nPhotos
                lastRk = @nPhotos - 1
                safeZone_endPt.rank = lastRk
                # other safeZone_endPt are useless (safeZone is going down)
                return true
            #
            for monthRk in [safeZone_startPt.monthRk..months.length-1]
                month = months[monthRk]
                if lastRk < month.lastRk
                    break
            safeZone_endPt.rank       = lastRk
            safeZone_endPt.monthRk    = monthRk
            inMonthRk                 = lastRk - month.firstRk
            inMonthRow                = Math.floor(inMonthRk/nThumbsPerRow)
            safeZone_endPt.inMonthRow = inMonthRow
            safeZone_endPt.col        = inMonthRk % nThumbsPerRow
            safeZone_endPt.y          = month.y + monthTopPadding + inMonthRow*rowHeight
            return false


        # todo bja : à renommer
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
            inMonthRk    = rk - month.firstRk
            inMonthRow = Math.floor(inMonthRk / nThumbsPerRow)

            safeZone_startPt.monthRk      = monthRk
            safeZone_startPt.inMonthRow = inMonthRow
            safeZone_startPt.rank         = rk
            safeZone_startPt.y            = month.y + cellPadding + monthHeaderHeight + inMonthRow*rowHeight


        _createThumbsBottom = (nToCreate, startRk, startCol, startY, monthRk) =>
            rowY    = startY
            col     = startCol
            month   = @months[monthRk]
            localRk = startRk - month.firstRk
            for rk in [startRk..startRk+nToCreate-1] by 1
                if localRk == 0 then _insertMonthLabel(month)
                thumb$ = document.createElement('div')
                thumb$.dataset.rank = rk
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
                style.left = (marginLeft + col*colWidth) + 'px'
                if @state.selected[rk]
                    thumb$.classList.add('selectedThumb')
                @thumbs$.appendChild(thumb$)
                @nThumbs += 1
                localRk += 1
                if localRk == month.nPhotos
                    # jump to a new month
                    monthRk += 1
                    month    = @months[monthRk]
                    localRk  = 0
                    col      = 0
                    rowY    += rowHeight + monthTopPadding
                else
                    # go to next column or to a new row if we are at last column
                    col  += 1
                    if col is nThumbsPerRow
                        rowY += rowHeight
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
            localRk = startRk - month.firstRk
            for rk in [startRk..startRk+nToMove-1] by 1
                if localRk == 0
                    _insertMonthLabel(month)
                thumb$              = buffer.first.el
                thumb$.dataset.rank = rk
                thumb$.textContent  = rk + ' ' + month.month.slice(0,4) + '-' + month.month.slice(4) #+ ' (moved from top to bottom)'
                style               = thumb$.style
                style.top           = rowY + 'px'
                style.left          = (marginLeft + col*colWidth) + 'px'
                if @state.selected[rk]
                    thumb$.classList.add('selectedThumb')
                else
                    thumb$.classList.remove('selectedThumb')
                buffer.last      = buffer.first
                buffer.first     = buffer.first.prev
                buffer.firstRk   = buffer.first.rank
                buffer.last.rank = rk
                localRk += 1
                if localRk == month.nPhotos
                    # jump to a new month
                    monthRk += 1
                    month    = @months[monthRk]
                    localRk  = 0
                    col      = 0
                    rowY    += rowHeight + monthTopPadding
                else
                    # go to next column or to a new row if we are at last column
                    col  += 1
                    if col is nThumbsPerRow
                        rowY += rowHeight
                        col   = 0
            buffer.lastRk  = rk - 1
            buffer.firstRk = buffer.first.rank
            # store the parameters of the thumb that is just after the last one
            buffer.nextLastRk      = rk
            # buffer.nextFirstRk     = buffer.first.rank - 1
            buffer.nextLastCol     = col
            buffer.nextLastY       = rowY
            buffer.nextLastMonthRk = monthRk


        _moveBufferToTop= (nToMove, startRk, startCol, startY, monthRk)=>
            rowY    = startY
            col     = startCol
            month   = @months[monthRk]
            localRk = startRk - month.firstRk
            for rk in [startRk..startRk-nToMove+1] by -1
                thumb$              = buffer.last.el
                thumb$.dataset.rank = rk
                thumb$.textContent  = rk + ' ' + month.month.slice(0,4) + '-' + month.month.slice(4) # + ' (moved from bottom to top)'
                style               = thumb$.style
                style.top           = rowY + 'px'
                style.left          = (marginLeft + col*colWidth) + 'px'
                if @state.selected[rk]
                    thumb$.classList.add('selectedThumb')
                else
                    thumb$.classList.remove('selectedThumb')
                buffer.first      = buffer.last
                buffer.last       = buffer.last.next
                buffer.lastRk     = buffer.last.rank
                buffer.first.rank = rk
                localRk          -= 1
                if localRk == -1
                    if rk == 0
                        rk = -1
                        break
                    # jump to a new month
                    _insertMonthLabel(month)
                    monthRk -= 1
                    month    = @months[monthRk]
                    localRk  = month.nPhotos - 1
                    col      = month.lastThumbCol
                    rowY    -= cellPadding + monthHeaderHeight + rowHeight
                else
                    # go to next column or to a new row if we are at last column
                    col  -= 1
                    if col is -1
                        rowY -= rowHeight
                        col   = nThumbsPerRow - 1

            buffer.firstRk = rk + 1
            buffer.lastRk  = buffer.last.rank


        _insertMonthLabel = (month)=>
            if month.label$
                label$ = month.label$
            else
                label$ = document.createElement('div')
                label$.classList.add('long-list-month-label')
                @thumbs$.appendChild(label$)
                month.label$ = label$
            label$.textContent = month.month
            label$.style.top   = (month.y + monthTopPadding - 21) + 'px'
            label$.style.left  = '7px'


        ####
        # Get thumbs dimensions.
        # It is possible only when the longList is inserted into the DOM, that's
        # why we had to wait for _init() which occurs after both the reception
        # of the array of photo and after the parent view has launched init().
        thumbDim     = @buffer.first.el.getBoundingClientRect()
        thumbWidth   = thumbDim.width
        colWidth     = thumbWidth + cellPadding
        thumbHeight  = thumbDim.height
        rowHeight    = thumbHeight + cellPadding
        ####
        # Adapt the geometry and then the buffer
        _resizeHandler()
        _adaptBuffer()
        ####
        # bind events
        @thumbs$.addEventListener(   'click'  , _clickHandler  )
        @viewPort$.addEventListener( 'scroll' , _scrollHandler )



        return {_adaptBuffer, print}





