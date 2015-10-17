'use strict'

utils = require 'utils'
signal = require 'signal'
log = require 'log'
assert = require 'assert'

log = log.scope 'Renderer', 'Binding'

{isArray} = Array

getPropHandlerName = do ->
	cache = Object.create null
	(prop) ->
		cache[prop] ||= "on#{utils.capitalize(prop)}Change"

MAX_LOOPS = 50

module.exports = (impl) ->
	{items} = impl

	class Connection
		pool = []

		@factory = (binding, objects, item, prop, parent=null) ->
			if pool.length > 0 and (elem = pool.pop())
				Connection.call elem, binding, objects, item, prop, parent
				elem
			else
				new Connection binding, objects, item, prop, parent

		constructor: (@binding, objects, item, @prop, @parent) ->
			@handlerName = getPropHandlerName prop
			@isConnected = false

			if isArray(item)
				@child = Connection.factory binding, objects, item[0], item[1], @
				@item = @child.getValue()
			else
				if item is 'this'
					@item = binding.ctx
				else if item is 'view'
					@item = impl.Renderer.window
				else
					@item = objects[item] or impl.Renderer[item]
				@child = null
			@connect()

			Object.preventExtensions @

		getSignalChangeListener = do ->
			withParent = ->
				@parent.updateItem()
			noParent = ->
				@binding.update()

			(connection) ->
				if connection.parent
					withParent
				else
					noParent

		update: ->
			getSignalChangeListener(@).call @

		connect: ->
			if @item
				handler = @item[@handlerName]
				if handler?
					@isConnected = true
					handler getSignalChangeListener(@), @
			return

		disconnect: ->
			if @item and @isConnected
				@item[@handlerName].disconnect getSignalChangeListener(@), @
			@isConnected = false
			return

		updateItem: ->
			oldVal = @item
			val = @child.getValue()
			if oldVal isnt val or utils.isObject(val)
				@disconnect()
				@item = val
				@connect()

				if @parent
					@parent.updateItem()
				else
					@binding.update()
			return

		getValue: ->
			@item?[@prop]

		destroy: ->
			@disconnect()
			@child?.destroy()
			pool.push @
			return

	# isSimpleBinding = (binding) ->
	# 	binding[1].length is 1 and isArray(binding[1][0]) and not isArray(binding[1][0][0])

	# class SimpleBinding
	# 	constructor: (@obj, @prop, binding, ctx) ->
	# 		item = obj._ref or obj
	# 		target = binding[1][0]

	# 		@func = binding[0]
	# 		@targetProp = target[1]
	# 		if target[0] is 'this'
	# 			@targetItem = ctx
	# 		else
	# 			@targetItem = ctx._component.itemsById[target[0]]

	# 		handlerName = "on#{utils.capitalize(target[1])}Change"
	# 		@targetItem[handlerName]? @update, @

	# 		Object.preventExtensions @

	# 		@update()

	# 	update: ->
	# 		@obj[@prop] = @targetItem[@targetProp
	# 		return

	# 	destroy: ->
	# 		handlerName = "on#{utils.capitalize(@targetProp)}Change"
	# 		@targetItem[handlerName].disconnect @update, @
	# 		# remove from the list
	# 		@obj._impl.bindings[@prop] = null
	# 		return

	class Binding
		pool = []

		@factory = (obj, prop, binding, component, ctx) ->
			if elem = pool.pop()
				Binding.call elem, obj, prop, binding, component, ctx
				elem
			else
				new Binding obj, prop, binding, component, ctx

		getPropHandlerName

		constructor: (@obj, @prop, binding, component, @ctx) ->
			assert.lengthOf binding, 2
			assert.isFunction binding[0]
			assert.isArray binding[1]

			item = @item = obj._ref or obj

			# properties
			@func = binding[0]
			@args = component.objectsOrder

			# connections
			connections = @connections ||= []
			for elem in binding[1]
				if isArray(elem)
					connections.push Connection.factory @, component.objects, elem[0], elem[1]

			# update
			`//<development>`
			@updatePending = false
			@updateLoop = 0
			`//</development>`
			Object.preventExtensions @

			@update()

		getDefaultValue = (binding) ->
			val = binding.obj[binding.prop]
			switch typeof val
				when 'string'
					''
				when 'number'
					0
				when 'boolean'
					false
				else
					null

		update: ->
			unless @args
				return

			`//<development>`
			if @updatePending
				if @updateLoop > MAX_LOOPS
					return
				if ++@updateLoop is MAX_LOOPS
					log.error "Potential loop detected. Property binding '#{@prop}' on item '#{@item.toString()}' has been disabled."
					return
			else
				@updateLoop = 0
			`//</development>`

			result = utils.tryFunction @func, @ctx, @args
			unless result?
				result = getDefaultValue @

			if typeof result is 'number' and not isFinite(result)
				result = getDefaultValue @

			`//<development>`
			@updatePending = true
			`//</development>`
			@obj[@prop] = result
			`//<development>`
			@updatePending = false
			`//</development>`
			return

		destroy: ->
			# destroy connections
			for connection in @connections
				connection.destroy()

			# remove from the list
			@obj._impl.bindings[@prop] = null

			# clear props
			@args = null
			utils.clear @connections

			pool.push @
			return

	setItemBinding: (prop, binding, component, ctx) ->
		data = @_impl
		data.bindings ?= {}

		data.bindings[prop]?.destroy()

		if binding?
			# if isSimpleBinding(binding)
			# 	data.bindings[prop] = new SimpleBinding @, prop, binding, ctx
			# else
			data.bindings[prop] = Binding.factory @, prop, binding, component, ctx

		return

	updateItemBinding: (prop) ->
		@_impl.bindings?[prop]?.update()
		return
