'use strict'

utils = require 'utils'
signal = require 'signal'
log = require 'log'

log = log.scope 'Renderer', 'Binding'

{assert} = console
{isArray} = Array

module.exports = (impl) ->
	{items} = impl

	class Connection
		constructor: (@binding, @item, @prop) ->
			if isArray item
				@item = null
				child = @child = new Connection binding, item[0], item[1]
				child.parent = @
				@updateChild child
			else
				@listen()

		child: null
		binding: null
		item: null
		prop: null
		parent: null

		getObj: ->
			if @item instanceof impl.DeepObject
				@child.item[@child.prop]
			else
				@item

		listen: ->
			signalName = "#{@prop}Changed"
			handlerName = signal.getHandlerName signalName

			if @item
				@getObj()[handlerName]? @signalChangeListener, @

		updateChild: (child) ->
			signalName = "#{@prop}Changed"
			handlerName = signal.getHandlerName signalName

			if @item
				@getObj()[handlerName]?.disconnect @signalChangeListener, @
				@item = null

			if child
				if child.item
					@item = child.getValue()
					@listen()
					@signalChangeListener()
				else
					child.updateChild()

		signalChangeListener: ->
			if @parent
				@parent.updateChild @
			else
				@binding.update()

		getValue: ->
			@getObj()[@prop]

		destroy: ->
			@updateChild null

	class Binding
		@prepare = (arr, item) ->
			for elem, i in arr
				if isArray elem
					Binding.prepare elem, item
				else if elem is 'this'
					arr[i] = item
			null

		@getHash = do ->
			argI = 0

			(arr, isFork=false) ->
				r = ''
				for elem, i in arr
					if isArray elem
						r += Binding.getHash elem, true
					else if typeof elem is 'string'
						if i is 1 and typeof arr[0] is 'object' and ///^[a-zA-Z_]///.test elem
							r += "."
						r += elem
					else if typeof elem is 'object'
						r += "$#{argI++}"
				unless isFork
					argI = 0
				r

		@getItems = (arr, r=[])->
			for elem in arr
				if isArray elem
					Binding.getItems elem, r
				else if typeof elem is 'object'
					r.push elem
			r				

		@getFunc = do (cache = {}) -> (binding) ->
			hash = Binding.getHash binding
			if cache.hasOwnProperty hash
				cache[hash]
			else
				args = Binding.getItems binding
				for _, i in args
					args[i] = "$#{i}"

				hash ||= '0'
				args.push "return #{hash};"
				cache[hash] = Function.apply null, args

		constructor: (@item, @ns, @uniqueProp, @prop, binding, @extraResultFunc) ->
			Binding.prepare binding, item

			# properties
			@__hash__ = utils.uid()
			@func = Binding.getFunc binding
			@args = Binding.getItems binding

			# destroy on property value change
			signalName = "#{prop}Changed"
			handlerName = signal.getHandlerName signalName

			# connections
			connections = @connections = []
			for elem in binding
				if isArray elem
					connections.push new Connection @, elem[0], elem[1]

			# update
			@defaultValue = @getObj()[prop]
			@update()

		item: null
		ns: ''
		args: null
		uniqueProp: ''
		prop: ''
		func: null
		extraResultFunc: null
		updatePending: false
		connections: null

		getObj: ->
			if @ns
				@item[@ns]
			else
				@item

		getDefaultValue = (binding) ->
			val = binding.getObj()[binding.prop]
			switch typeof val
				when 'string'
					''
				when 'number'
					-1
				else
					null

		update: ->
			unless @args
				return

			result = utils.tryFunction @func, null, @args
			unless result?
				result = getDefaultValue @

			# extra func
			if @extraResultFunc
				funcResult = @extraResultFunc @item
				if typeof funcResult is 'number' and isFinite(funcResult)
					result += funcResult

			if typeof result is 'number' and not isFinite(result)
				result = getDefaultValue @

			@updatePending = true
			@getObj()[@prop] = result
			@updatePending = false

		destroy: ->
			# destroy connections
			for connection in @connections
				connection.destroy()

			# remove from the list
			nsImpl = @item._impl
			nsImpl.bindings[@uniqueProp] = null

			# disconnect listener
			signalName = "#{@prop}Changed"
			handlerName = signal.getHandlerName signalName

			# clear props
			@args = null
			@connections = null

			# restore default value
			@getObj()[@prop] = @defaultValue
			return

	setItemBinding: (ns, prop, uniqueProp, binding, extraResultFunc) ->
		data = @_impl
		data.bindings ?= {}

		if data.bindings[uniqueProp]?.updatePending
			return

		data.bindings[uniqueProp]?.destroy()

		if binding?
			data.bindings[uniqueProp] = new Binding @, ns, uniqueProp, prop, binding, extraResultFunc
		return
