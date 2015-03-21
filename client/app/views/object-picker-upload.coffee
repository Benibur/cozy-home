template    = require('../templates/object-picker-upload')()


module.exports = class ObjectPickerUpload

####################
## PUBLIC SECTION ##
#
    constructor: (objectPicker) ->
        # get elements
        @objectPicker = objectPicker
        @name     = 'photoUpload'
        @tabLabel = 'upload'
        @tab      = @_createTab()
        @panel    = $(template)[0]
        # @uploader = @panel.querySelector('.modal-uploadBtn')
        # bind events
        @_bindFileDropZone()
        btn = @panel.querySelector('.modal-uploadBtn')
        btn.addEventListener('click', @_changePhotoFromUpload)
        @uploader = @panel.querySelector('.uploader')
        @uploader.addEventListener('change', @_handleUploaderChange)


    getObject : () ->
        return @dataURL


    keyHandler : (e)=>
        # console.log 'ObjectPickerUpload', e.which
        switch e.which
            when 27 # escape key
                e.stopPropagation()
                @objectPicker.onNo()
            when 13 # return key
                e.stopPropagation()
                @objectPicker.onYes()
            else
                return false
        return false


#####################
## PRIVATE SECTION ##
#
    _createTab : () ->
        tab = document.createElement('div')
        tab.textContent  = @tabLabel
        return tab


    _bindFileDropZone: ()->

        dropbox = @panel.querySelector(".modal-file-drop-zone>div")
        hasEnteredText = false

        dropbox.addEventListener("dragenter", (e)->
            console.log 'dragenter'
            e.stopPropagation()
            e.preventDefault()
            dropbox.classList.add('dragging')
        ,false)

        dropbox.addEventListener("dragleave", (e)->
            console.log 'dragleave'
            e.stopPropagation()
            e.preventDefault()
            dropbox.classList.remove('dragging')
        , false)

        dragenter = (e)->
            e.stopPropagation()
            e.preventDefault()

        drop = (e) =>
            e.stopPropagation()
            e.preventDefault()
            dt = e.dataTransfer
            files = dt.files
            @_handleFile(files[0])

        dragover = dragenter
        dropbox.addEventListener("dragover", dragover, false);
        dropbox.addEventListener("drop", drop, false);


    _changePhotoFromUpload: () =>
        console.log "_changePhotoFromUpload"
        @uploadPopupOpened = true # todo bja : pb : is not set to false if the user close the popup by clicking on the close button...
        @uploader.click()


    _handleUploaderChange: () =>
        file = @uploader.files[0]
        @_handleFile(file)


    _handleFile: (file) =>
        console.log "_handleFile"
        unless file.type.match /image\/.*/
            return alert t 'This is not an image'
        reader = new FileReader()
        img = new Image()
        reader.readAsDataURL file
        reader.onloadend = =>
            @dataURL = reader.result
            @objectPicker.onYes()

