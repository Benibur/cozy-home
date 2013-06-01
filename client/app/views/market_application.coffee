BaseView = require 'lib/base_view'
ColorButton = require 'widgets/install_button'

module.exports = class ApplicationRow extends BaseView
    tagName: "div"
    className: "cozy-app"
    template: require 'templates/market_application'

    events:
        "mouseover .app-install-button": "onMouseoverInstallButton"
        "mouseout .app-install-button": "onMouseoutInstallButton"
        "click .app-install-button": "onInstallClicked"

    getRenderData: ->
        app: @app.attributes

    constructor: (@app, @marketView) ->

        #@events = {}
        #@events["click #add-#{@app.id}-install"] = 'onInstallClicked'

        super()

    afterRender: =>
        @installButton = new ColorButton(@$ "#add-#{@app.id}-install")

    onMouseoverInstallButton: =>
        @isSliding = true
        @$(".app-install-text").show 'slide', {direction: 'right'}, 300, =>
            @isSliding = false

    onMouseoutInstallButton: =>
        #if not @isSliding
            #setTimetout @onMouseoutInstallButton, 200
        #else
        #    @$(".app-install-text").hide 'slide', {direction: 'right'}, 300

    onInstallClicked: =>
        @$el.fadeOut =>
            setTimeout =>
                @marketView.runInstallation @app.attributes, @installButton
            , 200
