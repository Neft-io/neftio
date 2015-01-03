'use strict'

utils = require 'utils'

WHEEL_DIVISOR = 8

module.exports = (impl) ->
	{Types} = impl
	{Item, Rectangle} = Types

	scrolling = false
	resetScrolling = ->
		scrolling = false
	setScrolling = ->
		scrolling = true
		requestAnimationFrame resetScrolling

	###
	Scroll container by given x and y deltas
	###
	scroll = (item, x=0, y=0) ->
		if scrolling
			return;

		{contentItem, globalScale} = item._impl

		x /= globalScale
		x = item.contentX - x
		max = contentItem.width - item.width
		x = Math.max(0, Math.min(max, x))

		y /= globalScale
		y = item.contentY - y
		max = contentItem.height - item.height
		y = Math.max(0, Math.min(max, y))

		if item.contentX isnt x or item.contentY isnt y
			item.contentX = x
			item.contentY = y
			setScrolling()

	getItemGlobalScale = (item) ->
		val = item.scale
		while item = item.parent
			val *= item.scale
		val

	createContinuous = (item, prop) ->
		velocity = 0
		amplitude = 0
		timestamp = 0

		scrollProp = do ->
			switch prop
				when 'x'
					(val) ->
						scroll item, val, 0
				when 'y'
					(val) ->
						scroll item, 0, val

		anim = ->
			return unless amplitude

			elapsed = Date.now() - timestamp
			delta = -amplitude*0.1 * Math.exp(-elapsed / 325);
			if Math.abs(delta) > 0.5
				scrollProp delta
				requestAnimationFrame anim

		press: ->
			velocity = amplitude = 0
			timestamp = Date.now()

		release: ->
			if Math.abs(velocity) > 10
				amplitude = 0.8 * velocity
				timestamp = Date.now()

				requestAnimationFrame anim

		update: (val) ->
			now = Date.now()
			elapsed = now - timestamp
			timestamp = now

			v = 100 * -val / (1 + elapsed);
			velocity = 0.8 * v + 0.2 * velocity;

	usePointer = (item) ->
		horizontalContinuous = createContinuous item, 'x'
		verticalContinuous = createContinuous item, 'y'

		focus = false
		x = y = 0

		moveMovement = (e) ->
			dx = e.x - x
			dy = e.y - y
			scroll item, dx, dy

		impl.attachItemSignal.call item, 'pointerPressed', (e) ->
			focus = true

			item._impl.globalScale = getItemGlobalScale item
			horizontalContinuous.press()
			verticalContinuous.press()

			x = e.x; y = e.y

		listenOnWindowSignals = ->
			impl.attachItemSignal.call impl.window, 'pointerReleased', (e) ->
				return unless focus
				focus = false

				moveMovement e

				horizontalContinuous.release()
				verticalContinuous.release()

				x = y = 0

			impl.attachItemSignal.call impl.window, 'pointerMove', (e) ->
				return unless focus

				moveMovement e

				horizontalContinuous.update e.x - x
				verticalContinuous.update e.y - y

				x = e.x; y = e.y

		if impl.window?
			listenOnWindowSignals()
		else
			impl.onWindowReady listenOnWindowSignals

	useWheel = (item) ->
		impl.attachItemSignal.call item, 'pointerWheel', (e) ->
			item._impl.globalScale = getItemGlobalScale item
			x = e.x / WHEEL_DIVISOR
			y = e.y / WHEEL_DIVISOR
			scroll item, x, y

	create: (item) ->
		storage = item._impl

		Item.create item

		storage.scroll = (x, y) -> scroll item, x, y
		storage.contentItem = null
		storage.globalScale = 1

		# item props
		impl.setItemClip.call item, true

		# signals
		usePointer item
		useWheel item

	setScrollableContentItem: (val) ->
		if oldVal = @_impl.contentItem
			oldVal.onWidthChanged.disconnect @_impl.scroll
			oldVal.onHeightChanged.disconnect @_impl.scroll

		if newVal = val
			@_impl.contentItem = newVal
			newVal.onWidthChanged @_impl.scroll
			newVal.onHeightChanged @_impl.scroll

	setScrollableContentX: (val) ->
		@_impl.contentItem?.x = -val

	setScrollableContentY: (val) ->
		@_impl.contentItem?.y = -val
