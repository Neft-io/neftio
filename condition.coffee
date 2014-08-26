'use strict'

[expect, utils] = ['expect', 'utils'].map require

cache = {}
cachelen = 0
MAX_IN_CACHE = 4000

module.exports = (File) -> class Condition

	@__name__ = 'Condition'
	@__path__ = 'File.Condition'

	@FALSE_FUNC = -> false

	@getCondFunc: (exp) ->

		try
			cond = "!!(#{unescape(exp)})"
			new Function "try { return #{cond}; } catch(_){ return false; }"
		catch
			Condition.FALSE_FUNC

	constructor: (opts) ->

		expect(opts).toBe.simpleObject()
		expect(opts.self).toBe.any File
		expect(opts.node).toBe.any File.Element

		utils.fill @, opts

	self: null
	node: null

	execute: ->

		exp = @node.attrs.get 'x:if'

		unless cache[exp]
			if cachelen++ > MAX_IN_CACHE
				cache = {}
				cachelen = 0

			cache[exp] = Condition.getCondFunc exp

		return cache[exp].call()

	render: ->
		expect(@self.isRendered).toBe.truthy()

		result = @execute()
		return if @node.visible is result

		@node.visible = result

	revert: ->
		expect(@self.isRendered).toBe.falsy()

		@node.visible = true

	clone: (original, self) ->

		clone = Object.create @

		clone.clone = undefined
		clone.self = self
		clone.node = original.node.getCopiedElement @node, self.node
		clone.render = @render.bind clone
		clone.revert = @revert.bind clone

		clone.self.onRender.connect clone.render
		clone.self.onRevert.connect clone.revert
		clone.node.onAttrChanged.connect (attr) ->
			clone.render() if attr is 'x:if'

		clone
