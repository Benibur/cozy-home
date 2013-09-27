BaseView = require 'lib/base_view'
ColorButton = require 'widgets/install_button'
PopoverPermissionsView = require 'views/popover_permissions'
WidgetTemplate = require 'templates/home_application_widget'

# Row displaying application name and attributes
module.exports = class ApplicationRow extends BaseView
    className: "application"
    tagName: "div"

    template: require 'templates/home_application'

    getRenderData: ->
        app: @model.attributes

    events:
        "click .application-inner" : "onAppClicked"
        'click .use-widget'        : 'onUseWidgetClicked'

    ### Constructor ####

    constructor: (options) ->
        @id = "app-btn-#{options.model.id}"
        @enabled = true
        super

    enable: () ->
        @enabled = true
        @$el.resizable 'disable'
        @$('.widget-mask').hide()
        @$('.use-widget').hide()

    disable: () ->
        console.log "disable called", new Error().stack
        @enabled = false
        @$el.resizable('enable') if @$el.resizable 'widget'
        if @canUseWidget()
            @$('.widget-mask').show()
            @$('.use-widget').show()

    afterRender: =>
        console.log "enabled called"
        @icon = @$ 'img'
        @stateLabel = @$ '.state-label'
        @title = @$ '.app-title'

        @listenTo @model, 'change', @onAppChanged
        @onAppChanged @model

    ### Listener ###

    onAppChanged: (app) =>
        if @model.get('state') isnt 'installed' or not @canUseWidget()
            @$('.use-widget').hide()

        switch @model.get 'state'
            when 'broken'
                @icon.attr 'src', "img/broken.png"
                @stateLabel.show().text t 'broken'
            when 'installed'
                @icon.attr 'src', "api/applications/#{app.id}.png"
                @icon.removeClass 'stopped'
                @stateLabel.hide()
                useWidget = @model.get('homeposition')?.useWidget
                @setUseWidget true if @canUseWidget() and useWidget

            when 'installing'
                @icon.attr 'src', "img/installing.gif"
                @icon.removeClass 'stopped'
                @stateLabel.show().text 'installing'
            when 'stopped'
                @icon.attr 'src', "api/applications/#{app.id}.png"
                @icon.addClass 'stopped'
                @stateLabel.hide()

    onAppClicked: (event) =>
        event.preventDefault()
        return null unless @enabled
        switch @model.get 'state'
            when 'broken'
                msg = 'This app is broken. Try install again.'
                errormsg = @model.get 'errormsg'
                msg += " Error was : #{errormsg}" if errormsg
                alert msg
            when 'installed'
                @launchApp()
            when 'installing'
                alert t 'this app is being installed. Wait a little'
            when 'stopped'
                @model.start success: @launchApp

    setUseWidget: (widget = true) =>
        widgetUrl = @model.get 'widget'
        if widget
            @$('.use-widget').text t 'Use icon'
            @icon.detach()
            @stateLabel.detach()
            @title.detach()
            @$('.application-inner').html WidgetTemplate url: widgetUrl
        else
            @$('.use-widget').text t 'Use widget'
            @$('.application-inner').empty()
            @$('.application-inner').append @icon
            @$('.application-inner').append @title
            @$('.application-inner').append @stateLabel

    canUseWidget: () => @model.has 'widget'

    onUseWidgetClicked: () =>
        useWidget = not @model.get('homeposition')?.useWidget
        @model.saveHomePosition 'useWidget', useWidget,
            success: => @setUseWidget useWidget

    ### Functions ###

    launchApp: =>
        window.app.routers.main.navigate "apps/#{@model.id}/", true
