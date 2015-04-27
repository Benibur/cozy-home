Photo    = require '../models/photo'

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
# 2/ @months
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
# 3/ @nPhotos
#   Total number of images in the long list.
#
# 4/ "rank"
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
#      nThumbs : {integer} # number of thumbs in the buffer
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
#      id   : {integer} # id of the corresponding image
#   Element of the buffer, keeps a reference (el) to the thumb element inserted
#   in the DOM.
#
# 8/ safeZone
#   firstVisibleRk     : {integer}
#   firstThumbToUpdate : {thumb}
#   rank               : {integer}
#   monthRk            : {integer}
#   inMonthRow         : {integer}
#   col                : {integer}
#   y                  : {integer}
#
#
################################################################################


################################################################################
## CONSTANTS ##
#
# minimum duration between two refresh (_adaptBuffer)
THROTTLE            = 350
# number of "screens" before and after the viewport
# (ex : 1.5 => 1+2*1.5=4 screens always ready)
COEF_SECURITY       = 1.5
# space between 2 months (in pixels)
MONTH_HEADER_HEIGHT = 40
# padding in pixels between thumbs
CELL_PADDING        = 4



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
        Photo.getMonthdistribution (error, res) =>
            # console.log 'longlist get an answer!', res
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
        thumb$ = document.createElement('img')
        @thumbs$.appendChild(thumb$)
        thumb$.setAttribute('class', 'long-list-thumb')
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
                nThumbs : 1
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
        cellPadding           = CELL_PADDING
        monthHeaderHeight     = MONTH_HEADER_HEIGHT
        monthTopPadding       = monthHeaderHeight + cellPadding

        marginLeft            = null
        thumbWidth            = null
        thumbHeight           = null
        colWidth              = null
        rowHeight             = null
        nThumbsPerRow         = null
        nRowsInSafeZoneMargin = null
        nThumbsInSafeZone     = null
        viewPortDim           = null
        safeZone_endPt        = {}
        safeZone =
            firstRk              : null
            firstMonthRk         : null
            firstInMonthRow      : null
            firstCol             : null
            firstVisibleRk       : null
            firstY               : null
            lastRk               : null
            endCol               : null
            endMonthRk           : null
            endY                 : null
            firstThumbToUpdate   : null
            firstThumbRkToUpdate : null


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
            nRowsInViewPort         = Math.ceil(@viewPort$.clientHeight /rowHeight)
            nRowsInSafeZoneMargin   = Math.round(COEF_SECURITY * nRowsInViewPort)
            nThumbsInSafeZoneMargin = nRowsInSafeZoneMargin * nThumbsPerRow
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


        ###*
         * Adapt the buffer when the viewport has moved
         * Launched at init and by _scrollHandler
         * Steps :
        ###
        _adaptBuffer = () =>
            @noScrollScheduled = true
            bufr               = buffer
            # re init safeZone but keep a reference on the
            # previous firstThumbToUpdate and firstThumbRkToUpdate
            safeZone.firstRk              = null
            safeZone.firstMonthRk         = null
            safeZone.firstInMonthRow      = null
            safeZone.firstCol             = null
            safeZone.firstVisibleRk       = null
            safeZone.firstY               = null
            safeZone.lastRk               = null
            safeZone.endCol               = null
            safeZone.endMonthRk           = null
            safeZone.endY                 = null
            previous_firstThumbToUpdate   = safeZone.firstThumbToUpdate
            safeZone.firstThumbToUpdate   = null
            previous_firstThumbRkToUpdate = safeZone.firstThumbRkToUpdate
            safeZone.firstThumbRkToUpdate = null

            _computeSafeZone()

            console.log '\n======_adaptBuffer==beginning======='
            console.log 'safeZone', JSON.stringify(safeZone,2)
            console.log 'bufr', bufr
            if safeZone.lastRk > bufr.lastRk
                # 1/ the safeZone is going down and the bottom of the safeZone
                # is bellow the bottom of the buffer
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
                if nAvailable > bufr.nThumbs
                    nAvailable = bufr.nThumbs

                nToCreate = Math.max(nToFind - nAvailable, 0)
                nToMove   = nToFind - nToCreate

                if safeZone.firstRk <= bufr.lastRk
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
                    targetMonthRk = safeZone.firstMonthRk
                    targetCol     = 0
                    targetY       = safeZone.firstY

                console.log 'direction: DOWN',         \
                            'nToFind:'   + nToFind,    \
                            'nAvailable:'+ nAvailable, \
                            'nToCreate:' + nToCreate,  \
                            'nToMove:'   + nToMove,    \
                            'targetRk:'  + targetRk

                if nToFind > 0
                    Photo.listFromFiles targetRk, nToFind, (error, res) ->
                        if Error
                            console.log Error
                        _updateThumb(res.files, res.firstRank)

                if nToCreate > 0
                    [targetY, targetCol, targetMonthRk] =
                        _createThumbsBottom( nToCreate     ,
                                              targetRk     ,
                                              targetCol    ,
                                              targetY      ,
                                              targetMonthRk  )
                    targetRk += nToCreate

                if nToMove > 0
                    # console.log "nToMove",nToMove
                    # console.log "targetRk",targetRk
                    # Photo.listFromFiles targetRk, nToMove, (error, res) ->
                    #     _updateThumb(res.files, res.firstRank)
                    _moveBufferToBottom( nToMove        ,
                                          targetRk      ,
                                          targetCol     ,
                                          targetY       ,
                                          targetMonthRk  )

            else if safeZone.firstRk < bufr.firstRk
                # 2/ the safeZone is going up and the top of the safeZone is
                # above the buffer
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
                if nAvailable > bufr.nThumbs
                    nAvailable = bufr.nThumbs

                nToCreate = Math.max(nToFind - nAvailable, 0)
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

                console.log 'direction: UP',           \
                            'nToFind:'   + nToFind,    \
                            'nAvailable:'+ nAvailable, \
                            'nToCreate:' + nToCreate,  \
                            'nToMove:'   + nToMove,    \
                            'targetRk:'  + targetRk

                if nToFind > 0
                    Photo.listFromFiles targetRk - nToFind + 1 , nToFind, (error, res) ->
                        if Error
                            console.log Error
                        _updateThumb(res.files, res.firstRank)

                if nToCreate > 0
                    throw new Error('It should not be used in the current implementation')
                    [targetY, targetCol, targetMonthRk] =
                        _createThumbsTop(  nToCreate    ,
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
            if !nToFind?
                console.log 'buffer inside safe zone, no modification of the buffer'
                safeZone.firstThumbToUpdate   = previous_firstThumbToUpdate
                safeZone.firstThumbRkToUpdate = previous_firstThumbRkToUpdate

            console.log '======_adaptBuffer==ending='
            console.log 'bufr', bufr
            console.log '======_adaptBuffer==ended======='

        ###*
         * Called when we get from the server the ids of the thumbs that have
         * been created or moved
         * @param  {Array} files     [{id},..,{id}] in chronological order
         * @param  {Integer} fstFileRk The rank of the first file of files
        ###
        _updateThumb = (files, fstFileRk)->
            lstFileRk = fstFileRk + files.length - 1
            bufr      = buffer
            thumb     = bufr.first
            firstThumbToUpdate   = safeZone.firstThumbToUpdate
            firstThumbRkToUpdate = firstThumbToUpdate.rank
            last  = bufr.last
            first = bufr.first
            console.log '\n======_updateThumb started ================='

            if firstThumbRkToUpdate < fstFileRk
                th = firstThumbToUpdate.prev
                while true
                    if th == bufr.first
                        return
                    if th.rank == fstFileRk
                        firstThumbToUpdate   = th
                        firstThumbRkToUpdate = th.rank
                        break
                    th = th.prev
            if lstFileRk < firstThumbRkToUpdate
                th = firstThumbToUpdate.next
                while true
                    if th == bufr.last
                        return
                    if th.rank == lstFileRk
                        firstThumbToUpdate   = th
                        firstThumbRkToUpdate = th.rank
                        break
                    th = th.next

            if firstThumbRkToUpdate <= lstFileRk
                console.log " update forward: #{firstThumbRkToUpdate}->#{lstFileRk}"
                console.log "   firstThumbRkToUpdate", firstThumbRkToUpdate, "nFiles", files.length, "fstFileRk", fstFileRk, "lstFileRk",lstFileRk
            else
                console.log " update forward: none"
            thumb = firstThumbToUpdate
            for file_i in [firstThumbRkToUpdate-fstFileRk..files.length-1] by 1
                file         = files[file_i]
                thumb.el.src = "files/photo/thumbs/#{file.id}.jpg"
                thumb.id     = file.id
                thumb        = thumb.prev

            if firstThumbRkToUpdate > fstFileRk
                console.log " update backward #{firstThumbRkToUpdate-1}->#{fstFileRk}"
                console.log "   firstThumbRkToUpdate", firstThumbRkToUpdate, "nFiles", files.length, "fstFileRk", fstFileRk, "lstFileRk",lstFileRk
            else
                console.log " update backward: none"
            thumb = firstThumbToUpdate.next
            for file_i in [firstThumbRkToUpdate-fstFileRk-1..0] by -1
                file         = files[file_i]
                thumb.el.src = "files/photo/thumbs/#{file.id}.jpg"
                thumb.id     = file.id
                thumb        = thumb.next
            console.log '======_updateThumb finished ================='


        _getBufferNextFirst = ()=>
            bufr = buffer
            nextFirstRk     = bufr.firstRk - 1
            if nextFirstRk == -1
                return
            bufr.nextFirstRk     = nextFirstRk

            initMonthRk = safeZone.endMonthRk
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

            initMonthRk = safeZone.firstMonthRk
            for monthRk in [initMonthRk..months.length-1] by 1
                month = months[monthRk]
                if nextLastRk <= month.lastRk
                    break
            bufr.nextLastMonthRk = monthRk
            localRk              = nextLastRk - month.firstRk
            inMonthRow           = Math.floor(localRk/nThumbsPerRow)
            bufr.nextLastY       = month.y + monthTopPadding + inMonthRow*rowHeight
            bufr.nextLastCol     = localRk % nThumbsPerRow

        ###*
         * [_computeSafeZone description]
         * @return {[type]} [description]
        ###
        _computeSafeZone = () =>
            # 1/ init the start of the safe zone at the start of the viewport
            _SZ_initStartPoint()
            # 2/ move the start of the safe zone in order to have a margin
            _SZ_setMarginAtStart()
            # 3/ init the end of the safe zone: start of SZ + nb of thumbs in SZ
            hasReachedLastPhoto = _SZ_initEndPoint()
            # 4/ if the end of SZ is at the last photo, move up the start of the
            # SZ in order to have if possible nThumbsInSafeZone
            if hasReachedLastPhoto
                _SZ_bottomCase()


        _SZ_initStartPoint = ()=>
            SZ = safeZone
            Y = @viewPort$.scrollTop
            for month, monthRk in @months
                if month.yBottom > Y
                    break
            inMonthRow = Math.floor((Y-month.y-monthTopPadding)/rowHeight)
            if inMonthRow < 0
                # happens if the viewport is in the header of a month
                inMonthRow = 0
            SZ.firstRk            = month.firstRk + inMonthRow * nThumbsPerRow
            SZ.firstY             = month.y + monthTopPadding + inMonthRow * rowHeight
            SZ.firstMonthRk       = monthRk
            SZ.firstCol           = 0
            SZ.firstThumbToUpdate = null
            SZ.firstInMonthRow    = inMonthRow
            SZ.firstVisibleRk     = SZ.firstRk # true because it is the init of SZ


        _SZ_setMarginAtStart= () =>
            SZ = safeZone
            inMonthRow = SZ.firstInMonthRow - nRowsInSafeZoneMargin

            if inMonthRow >= 0
                # the row that we are looking for is in the current month
                # (monthRk and col are not changed then)
                month = @months[SZ.firstMonthRk]
                SZ.firstRk = month.firstRk + inMonthRow * nThumbsPerRow
                SZ.firstY  = month.y + monthTopPadding + inMonthRow*rowHeight
                SZ.firstInMonthRow = inMonthRow
                return

            else
                # the row that we are looking for is before the current month
                # (col remains 0)
                rowsSeen = SZ.firstInMonthRow
                for j in [SZ.firstMonthRk-1..0] by -1
                    month = @months[j]
                    if rowsSeen + month.nRows >= nRowsInSafeZoneMargin
                        inMonthRow         = month.nRows - nRowsInSafeZoneMargin + rowsSeen
                        SZ.firstRk         = month.firstRk + inMonthRow * nThumbsPerRow
                        SZ.firstY          = month.y + monthTopPadding + inMonthRow*rowHeight
                        SZ.firstInMonthRow = inMonthRow
                        SZ.firstMonthRk    = j
                        return

                    else
                        rowsSeen += month.nRows

            SZ.firstRk         = 0
            SZ.firstMonthRk    = 0
            SZ.firstInMonthRow = 0
            SZ.firstCol        = 0
            SZ.firstY          = monthTopPadding


        ###*
         * Returns true if the safeZone end pointer should be after the last
         * thumb
        ###
        _SZ_initEndPoint = () =>
            SZ = safeZone
            lastRk = SZ.firstRk + nThumbsInSafeZone - 1
            if lastRk >= @nPhotos
                lastRk = @nPhotos - 1
                safeZone.lastRk = lastRk
                # other safeZone_endPt are useless (safeZone is going down)
                return true
            #
            for monthRk in [SZ.firstMonthRk..months.length-1]
                month = months[monthRk]
                if lastRk <= month.lastRk
                    break
            safeZone.lastRk     = lastRk
            safeZone.endMonthRk = monthRk
            inMonthRk           = lastRk - month.firstRk
            inMonthRow          = Math.floor(inMonthRk/nThumbsPerRow)
            safeZone.endCol     = inMonthRk % nThumbsPerRow
            safeZone.endY       = month.y         +
                                  monthTopPadding +
                                  inMonthRow*rowHeight
            return false


        _SZ_bottomCase = ()=>
            SZ = safeZone
            months       = @months
            monthRk      = months.length - 1
            thumbsSeen   = 0
            thumbsTarget = nThumbsInSafeZone
            for monthRk in [monthRk..0] by -1
                month = months[monthRk]
                thumbsSeen += month.nPhotos
                if thumbsSeen >= thumbsTarget
                    break
            if thumbsSeen < thumbsTarget
                # happens if the number of photo is smaller than the number
                # in safezone (nThumbsInSafeZone), it means that safe zone
                # begins at the first photo
                SZ.firstMonthRk    = 0
                SZ.firstInMonthRow = 0
                SZ.firstRk         = 0
                SZ.firstY          = month.y + cellPadding + monthHeaderHeight
            else
                rk         = @nPhotos - thumbsTarget
                inMonthRk  = rk - month.firstRk
                inMonthRow = Math.floor(inMonthRk / nThumbsPerRow)

                SZ.firstMonthRk    = monthRk
                SZ.firstInMonthRow = inMonthRow
                SZ.firstRk         = rk
                SZ.firstY          = month.y           +
                                     cellPadding       +
                                     monthHeaderHeight +
                                     inMonthRow * rowHeight


        _createThumbsBottom = (nToCreate, startRk, startCol, startY, monthRk) =>
            bufr     = buffer
            rowY     = startY
            col      = startCol
            month    = @months[monthRk]
            localRk  = startRk - month.firstRk
            lastLast = bufr.last
            for rk in [startRk..startRk+nToCreate-1] by 1
                if localRk == 0 then _insertMonthLabel(month)
                thumb$ = document.createElement('img')
                thumb$.dataset.rank = rk
                thumb$.setAttribute('class', 'long-list-thumb')
                thumb =
                    next : bufr.last
                    prev : bufr.first
                    el   : thumb$
                    rank : rk
                if rk == safeZone.firstVisibleRk
                    safeZone.firstThumbToUpdate = thumb
                bufr.first.next = thumb
                bufr.last.prev  = thumb
                bufr.last       = thumb
                thumb$.textContent = rk + ' ' + month.month.slice(0,4) + '-' + month.month.slice(4)
                style      = thumb$.style
                style.top  = rowY + 'px'
                style.left = (marginLeft + col*colWidth) + 'px'
                if @state.selected[rk]
                    thumb$.classList.add('selectedThumb')
                @thumbs$.appendChild(thumb$)
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
            bufr.lastRk   = rk - 1
            bufr.nThumbs += nToCreate
            # if the first visible thumb has not bee created, then the first
            # thumb to update will be the first created thumb (lastLast.prev :-)
            if safeZone.firstThumbToUpdate == null
                safeZone.firstThumbToUpdate = lastLast.prev
            # store the parameters of the thumb that is just after the last one
            bufr.nextLastRk      = rk
            bufr.nextLastCol     = col
            bufr.nextLastY       = rowY
            bufr.nextLastMonthRk = monthRk

            return [rowY, col, monthRk]


        _moveBufferToBottom= (nToMove, startRk, startCol, startY, monthRk)=>
            monthRk_initial = monthRk
            rowY    = startY
            col     = startCol
            month   = @months[monthRk]
            localRk = startRk - month.firstRk

            # by default the firstThumbToUpdate will be the first moved down
            # (ie buffer.first :-)
            if safeZone.firstThumbToUpdate == null
                safeZone.firstThumbToUpdate = buffer.first

            for rk in [startRk..startRk+nToMove-1] by 1
                if localRk == 0
                    _insertMonthLabel(month)
                thumb = buffer.first
                thumb$              = thumb.el
                thumb$.dataset.rank = rk
                thumb.rank          = rk
                thumb$.src          = ''
                style      = thumb$.style
                style.top  = rowY + 'px'
                style.left = (marginLeft + col*colWidth) + 'px'
                if @state.selected[rk]
                    thumb$.classList.add('selectedThumb')
                else
                    thumb$.classList.remove('selectedThumb')
                # if during the move of the thumbs we meet the thumb with the
                # firstVisibleRk, then this thumb is the firstThumbToUpdate
                if rk == safeZone.firstVisibleRk
                    safeZone.firstThumbToUpdate = thumb
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

            console.log 'firstThumbToUpdate (_moveBufferToBottom)', safeZone.firstThumbToUpdate.el
            buffer.lastRk  = rk - 1
            buffer.firstRk = buffer.first.rank
            # store the parameters of the thumb that is just after the last one
            buffer.nextLastRk      = rk
            buffer.nextLastCol     = col
            buffer.nextLastY       = rowY
            buffer.nextLastMonthRk = monthRk


        _moveBufferToTop= (nToMove, startRk, startCol, startY, monthRk)=>
            rowY    = startY
            col     = startCol
            month   = @months[monthRk]
            localRk = startRk - month.firstRk

            # by default the firstThumbToUpdate will be the first moved down
            # (ie buffer.first :-)
            if safeZone.firstThumbToUpdate == null
                safeZone.firstThumbToUpdate = buffer.last

            for rk in [startRk..startRk-nToMove+1] by -1
                thumb               = buffer.last
                thumb$              = thumb.el
                thumb$.dataset.rank = rk
                thumb.rank          = rk
                thumb$.src          = ''
                style               = thumb$.style
                style.top           = rowY + 'px'
                style.left          = (marginLeft + col*colWidth) + 'px'
                if @state.selected[rk]
                    thumb$.classList.add('selectedThumb')
                else
                    thumb$.classList.remove('selectedThumb')
                # if during the move of the thumbs we meet the thumb with the
                # firstVisibleRk, then this thumb is the firstThumbToUpdate
                if rk == safeZone.firstVisibleRk
                    safeZone.firstThumbToUpdate = thumb
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

            console.log 'firstThumbToUpdate (_moveBufferToTop)', safeZone.firstThumbToUpdate.el
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
            label$.textContent =   month.month.slice(0,4) \
                                 + '-'                    \
                                 + month.month.slice(-2)
            label$.style.top   = (month.y + monthTopPadding - 21) + 'px'
            label$.style.left  = '7px'


        ####
        # Get thumbs dimensions.
        # It is possible only when the longList is inserted into the DOM, that's
        # why we had to wait for _init() which occurs after both the reception
        # of the array of photo and after the parent view has launched init().
        thumbDim    = @buffer.first.el.getBoundingClientRect()
        thumbWidth  = thumbDim.width
        colWidth    = thumbWidth + cellPadding
        thumbHeight = thumbDim.height
        rowHeight   = thumbHeight + cellPadding
        ####
        # Adapt the geometry and then the buffer
        _resizeHandler()
        _adaptBuffer()
        ####
        # bind events
        @thumbs$.addEventListener(   'click'  , _clickHandler  )
        @viewPort$.addEventListener( 'scroll' , _scrollHandler )



        return {_adaptBuffer, print}





