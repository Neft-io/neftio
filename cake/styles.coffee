'use strict'

[vm, utils, expect, coffee] = ['vm', 'utils', 'expect', 'coffee-script'].map require

BINDING_RE = ///([a-z0-9_]+)\.(left|top|width|height)///ig
RESERVED_IDS = ['window']
HASH_PATTERN = '__{hash}__'
BINDED_PROPS = ['left', 'top', 'width', 'height']

result =
	items: []
	ids: {}
units = {}
sandbox = {}

sandbox.Item = (opts) ->
	index = result.items.length

	obj =
		type: 'Item'
		index: index
		config: opts

	result.items.push obj

	# id
	if opts.id
		result.ids[opts.id] = index
		obj.variables = {}
		obj.variables.id = opts.id + HASH_PATTERN
		opts.id = ''

	# binded properties
	for prop in BINDED_PROPS when typeof opts[prop] is 'string'
		obj.variables ?= {}
		obj.variables[prop] = opts[prop].replace BINDING_RE, (str, id, prop) ->
			return str if utils.has RESERVED_IDS, id
			"#{id}#{HASH_PATTERN}.#{prop}"
		opts[prop] = ''

	obj

sandbox.Node = (opts, children) ->
	if Array.isArray opts
		children = opts
		opts = {}

	if children ||= opts.children
		childrenIndexes = []

	obj = utils.merge sandbox.Item(opts),
		type: 'Node'
		children: childrenIndexes

	if children
		for child in children
			childrenIndexes.push child.index
			child.parent = obj.index

	obj

sandbox.Image = ->
	utils.merge sandbox.Item(arguments...),
		type: 'Image'

sandbox.Text = ->
	utils.merge sandbox.Item(arguments...),
		type: 'Text'

sandbox.Column = ->
	utils.merge sandbox.Node(arguments...),
		type: 'Column'

sandbox.Row = ->
	utils.merge sandbox.Node(arguments...),
		type: 'Row'

sandbox.Scrollable = ->
	utils.merge obj = sandbox.Node(arguments...),
		type: 'Scrollable'

	if obj.config.content?
		obj.links ?= {}
		obj.links.content = obj.config.content.index
		obj.config.content = null

	obj

sandbox.Unit = (name, node) ->
	expect(name).toBe.truthy().string()
	expect(node).toBe.object()

	units[name] = result
	result =
		items: []
		ids: {}

exports.compile = (data) ->

	data = coffee.compile data, bare: true

	script = vm.createScript data
	script.runInNewContext sandbox

	# stringify
	json = JSON.stringify units, null, 4

	# clear
	utils.clear result.items
	utils.clear result.ids

	json