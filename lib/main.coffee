{CompositeDisposable, Disposable} = require 'atom'
helper                            = require './helpers'

MinimapGpoolDiffBinding = null

class Main
  
  # Whether or not the minimap portion of the plugin is active
  minimap_active: false
  # Whether or not the gpool portion of the plugin is active
  gpool_active: false
  
  
  # Whether or not the minimap portion of the plugin is active
  isActive: -> @minimap_active
  # Whether or not the gpool portion of the plugin is active
  gpl_isActive: -> @gpool_active
  
  
  # Activates the package
  activate: ->
    @bindings = new WeakMap
  
  
  # deactivates the package
  deactivate: ->
    @destroyBindings()
    @minimap?.unregisterPlugin 'gpool-diff'          # Unregsiter this plugin from minimap
    @gpool?.unregisterPlugin   'gpool-diff-minimap'  # Unregister this plugin from gpool-base
    @minimap = null
  
  
  # Consumes the gpool object
  consumeGpoolServiceV1: (@gpool) ->
    helper.setInstance @gpool                               # Put the instance into the helpers - needed to get the proper repository
    @gpool.registerPlugin "gpool-diff-minimap", this  # Register this plugin with gpool
  
  # Comsumes the minimap object
  consumeMinimapServiceV1: (@minimap) ->
    @minimap.registerPlugin 'gpool-diff', this  # Regsiter this plugin with minimap
  
  
  # Activates the minimap portion of the plugin
  activatePlugin: ->
    return if @minimap_active
    
    @subscriptions = new CompositeDisposable
    
    try
      @activateBinding()
      @minimap_active = true
      
      @subscriptions.add @minimap.onDidActivate @activateBinding
      @subscriptions.add @minimap.onDidDeactivate @destroyBindings
    catch e
      console.log e
  
  
  # Deactivates the minimap portion of the plugin
  deactivatePlugin: ->
    return unless @minimap_active
    
    @minimap_active = false
    @subscriptions.dispose()
    @destroyBindings()
  
  
  # Called when the 'gpool' package activates this plugin
  gpl_activatePlugin: ->
    return if @gpl_active  # If the plugin is already activated, there's no point in continuing
    
    @gpl_active = true                                                   # State that this plugin is now active
    @gpl_subscriptions = new CompositeDisposable                         # Create the subscriptions collection
    @gpl_subscriptions.add @gpool.onRepoListChange => @createBindings()  # Re-build the observers when the repository list changes
    @createBindings()                                                      # Observe the editor now
  
  
  # Called when the 'gpool' package deactivates this plugin
  gpl_deactivatePlugin: ->
    return unless @gpl_active  # If the plugin is already deactivated, there's no point in continuing
    
    @gpl_active = false           # State that this plugin is no longer active
    @gpl_subscriptions.dispose()  # Dispose of the subscriptions
    @gpl_subscriptions = null     # Remove the subscriptions object
  
  
  # Does something
  activateBinding: =>
    @createBindings() if Object.keys(helper.gpl.host._repos).length > 0
    
    @subscriptions.add atom.project.onDidChangePaths =>
      
      if Object.keys(helper.gpl.host._repos).length > 0
        @createBindings()
      else
        @destroyBindings()
  
  
  # Does another thing
  createBindings: =>
    return unless Object.keys(helper.gpl.host._repos).length > 0
    
    MinimapGpoolDiffBinding ||= require './minimap-gpool-diff-binding'
    
    @subscriptions.add @minimap.observeMinimaps (o) =>
      minimap = o.view ? o
      editor = minimap.getTextEditor()
      
      return unless editor?
      
      binding = new MinimapGpoolDiffBinding minimap
      @bindings.set(minimap, binding)
  
  
  # Wheee! Look at how much I know!
  destroyBindings: =>
    return unless @minimap? and @minimap.editorsMinimaps?
    @minimap.editorsMinimaps.forEach (minimap) =>
      @bindings.get(minimap)?.destroy()
      @bindings.delete(minimap)

module.exports = new Main
