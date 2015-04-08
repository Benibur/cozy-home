template    = require '../templates/object-picker-photoURL'
proxyclient = require 'lib/proxyclient'


module.exports = class ObjectPickerPhotoURL


    constructor: (objectPicker) ->
        @objectPicker = objectPicker
        @name     = 'urlPhotoUpload'
        @tabLabel = 'url'
        @tab      = @_createTab()
        @panel    = $(template())[0]
        @img      = @panel.querySelector('.url-preview')
        @blocContainer=@panel.querySelector('.bloc-container')
        @url      = undefined
        @input    = @panel.querySelector('.modal-url-input')
        @_setupInput()


    getObject : () ->
        if @url
            return @url
        else
            return false

    setFocusIfExpected : () ->
        @input.focus()
        @input.select()
        return true


    keyHandler : (e)->
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


    # manages the url typed in the input and update image
    _setupInput: ()->
        img = @img
        urlRegexp = /\b(https?|ftp|file):\/\/[\-A-Z0-9+&@#\/%?=~_|$!:,.;]*[A-Z0-9+&@#\/%=~_|$]/i
        imgTmp = new Image()

        imgTmp.onerror =  () ->
            img.style.backgroundImage = ""
            @url = undefined

        imgTmp.onload =  () =>
            img.style.maxWidth  = imgTmp.naturalWidth  + 'px'
            img.style.maxHeight = imgTmp.naturalHeight + 'px'
            img.parentElement.style.display = 'flex'
            img.style.backgroundImage = 'url(' + imgTmp.src + ')'
            @url = imgTmp.src
            @blocContainer.style.height = (imgTmp.naturalHeight+40) + 'px'

        preloadImage = (src) ->
            imgTmp.src = src

        @input.addEventListener('input',(e)->
            newurl = e.target.value
            if urlRegexp.test(newurl)
                url = 'api/proxy/?url=' + encodeURIComponent(newurl)
                preloadImage(url)
            else
                img.style.backgroundImage = ""
                @url = undefined
        ,false)


    _createTab : () ->
        tab = document.createElement('div')
        tab.textContent  = @tabLabel
        return tab

