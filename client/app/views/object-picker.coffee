Modal                = require '../views/modal'
template             = require('../templates/object-picker')()
ObjectPickerPhotoURL = require './object-picker-photoURL'
ObjectPickerUpload   = require './object-picker-upload'
ObjectPickerImage    = require './object-picker-image'


module.exports = class PhotoPickerCroper extends Modal

####################
## PUBLIC SECTION ##
#
# Class attributes

    id                : 'object-picker'
    title             :  'pick from files' # todo bja : t undefined ??
    # title             : t 'pick from files' # todo bja : t undefined ??

# Methods

    events: -> _.extend super,
        'click    a.next'           : 'displayMore'
        'click    a.prev'           : 'displayPrevPage'
        'click    .chooseAgain'     : 'chooseAgain'


    initialize: (params, cb) ->

        # init config & state and super
        @config =
            cssSpaceName    : "object-picker"
            singleSelection : true # tells if user can select one or more photo
            numPerPage      : 50   # number of thumbs preloaded per request
            yes             : t 'modal ok'
            no              : t 'modal cancel'
            cb              : cb  # will be called by onYes
            target_h        : 100 # height of the img-preview div
            target_w        : 100 # width  of the img-preview div
        @state =
            currentStep : 'objectPicker' # 2 states : 'croper' & 'objectPicker'
            img_naturalW: 0  # natural width  (px) of the selected file
            img_naturalH: 0  # natural height (px) of the selected file
        super(@config)

        # get elements
        body              = @el.querySelector('.modalCY-body')
        body.innerHTML    = template
        @body             = body
        @objectPickerCont = body.querySelector('.objectPickerCont')
        @tablist          = body.querySelector('[role=tablist]')
        @cropper$         = @el.querySelector('.croperCont')
        @imgToCrop        = @cropper$.querySelector('#img-to-crop')
        @imgPreview       = @cropper$.querySelector('#img-preview')
        @nextBtn          = body.querySelector('.next')

        # initialise tabs and panels
        tabControler = require('views/tab-controler')
        @imagePanel = new ObjectPickerImage(this, @config)
        tabControler.addTab @objectPickerCont, @tablist, @imagePanel
        @photoURLpanel = new ObjectPickerPhotoURL(this)
        tabControler.addTab @objectPickerCont, @tablist, @photoURLpanel
        @uploadPanel = new ObjectPickerUpload(this)
        tabControler.addTab @objectPickerCont, @tablist, @uploadPanel
        tabControler.initializeTabs(body)
        @listenTabsSelection()
        @selectDefaultTab(@imagePanel.name)

        # init the cropper
        @imgToCrop.addEventListener('load', @onImgToCropLoaded, false)
        @cropper$.style.display = 'none'

        return true


    # supercharge the modal behavour : "ok" leads to the cropping step
    onYes: ()->
        # console.log "onYes", @state.currentStep, @sourceType
        if @state.currentStep == 'objectPicker'
            switch @sourceType
                when @imagePanel.name
                    url = @imagePanel.getObject()
                when @photoURLpanel.name
                    url = @photoURLpanel.getObject()
                when @uploadPanel.name
                    url = @uploadPanel.getObject()
            if url
                @showCropingTool(url)
        else
            s = @imgPreview.style
            r = @state.img_naturalW / @imgPreview.width
            d =
                sx      : Math.round(- parseInt(s.marginLeft)*r)
                sy      : Math.round(- parseInt(s.marginTop )*r)
                sWidth  : Math.round(@config.target_h*r)
                sHeight : Math.round(@config.target_w*r)
            @close()
            @cb(true,@getResultDataURL(@imgPreview, d))


#####################
## PRIVATE SECTION ##
#

    getResultDataURL:(img, dimensions)->
        IMAGE_DIMENSION = 600

        # use canvas to resize the image
        canvas = document.createElement 'canvas'
        canvas.height = canvas.width = IMAGE_DIMENSION
        ctx = canvas.getContext '2d'
        if dimensions?
            d = dimensions
            ctx.drawImage( img, d.sx, d.sy, d.sWidth,
                           d.sHeight, 0, 0, IMAGE_DIMENSION, IMAGE_DIMENSION)
        return dataUrl =  canvas.toDataURL 'image/jpeg'



    onKeyStroke: (e)->
        console.log 'onKeyStroke', e.which, @sourceType
        if @state.currentStep == 'croper'
            if e.which is 27 # escape key => choose another photo
                e.stopPropagation()
                @chooseAgain()
            else if e.which == 13 # return key => validate modal
                e.stopPropagation()
                @onYes()
                return
            else
                return
        else # @state.currentStep == 'objectPicker'
            switch @sourceType
                when @imagePanel.name
                    @imagePanel.keyHandler(e)
                when @uploadPanel.name
                    @uploadPanel.keyHandler(e)
                when @photoURLpanel.name
                    @photoURLpanel.keyHandler(e)
        return


    # url : path or dataUrl
    showCropingTool: (url)->
        @state.currentStep = 'croper'
        @currentPhotoScroll = @body.scrollTop

        @objectPickerCont.style.display = 'none'
        @cropper$.style.display = ''

        @imgToCrop.src  = url
        @imgPreview.src = url


    onImgToCropLoaded: ()=>
        img_w  = @imgToCrop.width
        img_h  = @imgToCrop.height
        @img_w = img_w
        @img_h = img_h
        @state.img_naturalW = @imgToCrop.naturalWidth
        @state.img_naturalH = @imgToCrop.naturalHeight
        selection_w   = Math.round(Math.min(img_h,img_w)*1)
        x = Math.round( (img_w-selection_w)/2 )
        y = Math.round( (img_h-selection_w)/2 )
        options =
            onChange    : @updateCropedPreview
            onSelect    : @updateCropedPreview
            aspectRatio : 1
            setSelect   : [ x, y, x+selection_w, y+selection_w ]
        t = this
        $(@imgToCrop).Jcrop( options, ()->
            t.jcrop_api = this
        )
        t.jcrop_api.focus()


    updateCropedPreview: (coords) =>
        prev_w = @img_w / coords.w * @config.target_w
        prev_h = @img_h / coords.h * @config.target_h
        prev_x = @config.target_w  / coords.w * coords.x
        prev_y = @config.target_h  / coords.h * coords.y
        s            = @imgPreview.style
        s.width      = Math.round(prev_w) + 'px'
        s.height     = Math.round(prev_h) + 'px'
        s.marginLeft = '-' + Math.round(prev_x) + 'px'
        s.marginTop  = '-' + Math.round(prev_y) + 'px'
        return true


    chooseAgain : ()->
        @state.currentStep = 'objectPicker'
        @jcrop_api.destroy()
        @imgToCrop.removeAttribute('style')
        @imgToCrop.src = ''
        @objectPickerCont.style.display = ''
        @cropper$.style.display = 'none'
        @body.scrollTop = @currentPhotoScroll


    listenTabsSelection: ()->
        @objectPickerCont.addEventListener('panelSelect',(event)=>
            @activateSourceType(event.target.className)
        )


    selectDefaultTab:(panelClassName)->
        @tablist.querySelector("[aria-controls=#{panelClassName}]").click()


    activateSourceType: (sourceType)->
        console.log 'sourceType =', sourceType
        @sourceType = sourceType

