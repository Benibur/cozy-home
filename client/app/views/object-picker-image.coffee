template = require '../templates/object-picker-image'
Photo    = require '../models/photo'
LongList = require 'views/long-list-images'


module.exports = class ObjectPickerImage

####################
## PUBLIC SECTION ##
#
    constructor: (@objectPicker, @config) ->
        ####
        # init state
        @state =
            selected    : {} # selected.photoID = thumb = {id,name,thumbEl}
            selected_n  : 0  # number of photos selected
            skip        : 0  # rank of the oldest downloaded thumb
            percent     : 0  # % of thumbnails computation avancement (if any)
        @name     = 'thumbPicker'
        @tabLabel = 'image'
        ####
        # get elements (name ends with '$')
        @tab      = @_createTab()
        @panel    = $(template())[0]
        # @thumbs$  = @panel.querySelector('.thumbsContainer') # the div containing photos
        ####
        # bind events
        # @thumbs$.addEventListener( 'click'   , @_validateClick    )
        @panel.addEventListener( 'dblclick', @_validateDblClick )
        ####
        # construct the long list of images
        @longList = new LongList(@panel)


    init : () ->
        @longList.init()


    getObject : () ->
        return "files/photo/screens/#{@longList.getSelectedID()}.jpg"


    setFocusIfExpected : () ->
        # the panel doesn't want the focus because otherwise the arrows keys
        # makes thumbs scroll
        return false


    keyHandler : (e)->
        ####
        console.log 'ObjectPickerImage.keyHandler', e.which
        switch e.which
            when 27 # escape key
                e.stopPropagation()
                @objectPicker.onNo()
            when 13 # return key
                e.stopPropagation()
                @objectPicker.onYes()
            # when 39 # right key
            #     e.stopPropagation()
            #     e.preventDefault()
            #     @_selectNextThumb()
            # when 37 # left key
            #     e.stopPropagation()
            #     e.preventDefault()
            #     @_selectPreviousThumb()
            # when 38 # up key
            #     e.stopPropagation()
            #     e.preventDefault()
            #     @_selectThumbUp()
            # when 40 # down key
            #     e.stopPropagation()
            #     e.preventDefault()
            #     @_selectThumbDown()
            else
                return @longList.keyHandler(e)
        return


#####################
## PRIVATE SECTION ##
#
    _createTab : () ->
        tab$ = document.createElement('div')
        tab$.textContent  = @tabLabel
        return tab$


    # _addPage:(skip, limit)=>
    #     # Recover files
    #     Photo.listFromFiles skip, limit, @_listFromFiles_cb
    #     @state.skip +=  @config.numPerPage


    # _listFromFiles_cb: (err, body) =>
    #     files = body.files if body?.files?

    #     if err
    #         return console.log err

    #     # If server is creating thumbs : then wait before to display files.
    #     else if body.percent?
    #         @state.percent = body.percent
    #         pathToSocketIO = \
    #             "#{window.location.pathname.substring(1)}socket.io"
    #         socket = io.connect window.location.origin,
    #             resource: pathToSocketIO
    #         socket.on 'progress', (event) =>
    #             @state.percent = event.percent
    #             if @state.percent is 100
    #                 # TODO
    #             else
    #                 # TODO

    #     # If there is no photos in Cozy
    #     else if files? and Object.keys(files).length is 0
    #         @thumbs$.innerHTML = "<p style='margin-top:20px'>#{t 'no image'}</p>"
    #         btn = @thumbs$.parentElement.children[1]
    #         btn.parentElement.removeChild(btn)

    #     # there are some images, add thumbs to modal
    #     else
    #         if body?.hasNext?
    #             hasNext = body.hasNext
    #         else
    #             hasNext = false
    #         @_addThumbs(body.files, hasNext)
    #         if @config.singleSelection and @state.selected_n == 0
    #             @_selectFirstThumb()


    # _addThumbs : (files, hasNext) ->
    #     # Add next button
    #     if !hasNext
    #         @nextBtn$.style.display = 'none'
    #     # dates = Object.keys files
    #     # dates.sort (a, b) ->
    #     #     -1 * a.localeCompare b
    #     frag = document.createDocumentFragment()
    #     s = ''
    #     # for month in dates
    #     #     photos = files[month]
    #     for p in files
    #         img       = new Image()
    #         img.src   = "files/thumbs/#{p.id}.jpg"
    #         img.id    = "#{p.id}"
    #         img.title = "#{p.name}"
    #         frag.appendChild(img)
    #     @thumbs$.appendChild(frag)


    # _validateDblClick:(e)=>
    #     # console.log 'dblclick'
    #     if e.target.nodeName != "IMG"
    #         return
    #     if @config.singleSelection
    #         if typeof @state.selected[e.target.id] != 'object'
    #             @_toggleClicked(e.target)
    #         @objectPicker.onYes()
    #     else
    #         return


    # _validateClick:(e)=>
    #     # console.log 'click'
    #     el = e.target
    #     if el.nodeName != "IMG"
    #         return
    #     @_toggleClicked(el)


    # _toggleClicked: (el) ->
    #     id = el.id
    #     if @config.singleSelection
    #         currentID = @_getSelectedID()
    #         if currentID == id
    #             return
    #         @_toggleOne(el, id)
    #         # unselect other thumbs
    #         for i, thumb of @state.selected # thumb = {id,name,thumbEl}
    #             if i != id
    #                 if typeof(thumb) == 'object' # means thumb is selected
    #                     $(thumb.el).removeClass('selected')
    #                     @state.selected[i] = false
    #                     @state.selected_n -=1
    #     else
    #         @_toggleOne(el, id)


    # _selectFirstThumb:()->
    #     @_toggleClicked(@thumbs$.firstChild)


    # _selectNextThumb: ()->
    #     thumb = @_getSelectedThumb()
    #     if thumb == null
    #         return
    #     nextThumb = thumb.nextElementSibling
    #     if nextThumb
    #         @_toggleClicked(nextThumb)


    # _selectPreviousThumb : ()->
    #     thumb = @_getSelectedThumb()
    #     if thumb == null
    #         return
    #     prevThumb = thumb.previousElementSibling
    #     if prevThumb
    #         @_toggleClicked(prevThumb)


    # _selectThumbUp : ()->
    #     thumb = @_getSelectedThumb()
    #     if thumb == null
    #         return
    #     x = thumb.x
    #     prevThumb = thumb.previousElementSibling
    #     while prevThumb
    #         if prevThumb.x == x
    #             @_toggleClicked(prevThumb)
    #             return
    #         prevThumb = prevThumb.previousElementSibling
    #     firstThumb = thumb.parentElement.firstChild
    #     if firstThumb != thumb
    #         @_toggleClicked(firstThumb)


    # _selectThumbDown : ()->
    #     thumb = @_getSelectedThumb()
    #     if thumb == null
    #         return
    #     x = thumb.x
    #     nextThumb = thumb.nextElementSibling
    #     while nextThumb
    #         if nextThumb.x == x
    #             @_toggleClicked(nextThumb)
    #             return
    #         nextThumb = nextThumb.nextElementSibling
    #     lastThumb = thumb.parentElement.lastChild
    #     if lastThumb != thumb
    #         @_toggleClicked(lastThumb)


    # _toggleOne: (thumbEl, id) ->
    #     if typeof(@state.selected[id]) == 'object'
    #         $(thumbEl).removeClass('selected')
    #         @state.selected[id] = false
    #         @state.selected_n -=1
    #     else
    #         $(thumbEl).addClass('selected')
    #         @state.selected[id] = {id:id,name:"",el:thumbEl}
    #         @state.selected_n +=1


    # _getSelectedID : () ->
    #     for k, val of @state.selected
    #         if typeof(val)=='object'
    #             return k
    #     return null


    # _getSelectedThumb : () ->
    #     for k, val of @state.selected
    #         if typeof(val)=='object'
    #             return val.el
    #     return null

