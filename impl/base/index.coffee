'use strict'

utils = require 'utils'

exports.Types =
	Item: require './level0/item'
	Image: require './level0/image'
	Text: require './level0/text'
	TextInput: require './level0/text/input'
	FontLoader: require './level0/fontLoader'
	Device: require './level0/device'
	Screen: require './level0/screen'
	Navigator: require './level0/navigator'
	RotationSensor: require './level0/sensor/rotation'
	AmbientSound: require './level0/sound/ambient'

	Rectangle: require './level1/rectangle'
	Grid: require './level1/grid'
	Column: require './level1/column'
	Row: require './level1/row'
	Flow: require './level1/flow'

	Animation: require './level1/animation'
	PropertyAnimation: require './level1/animation/property'
	NumberAnimation: require './level1/animation/number'

	Scrollable: require './level2/scrollable'

exports.Extras =
	Binding: require './level1/binding'
	Anchors: require './level2/anchors'

exports.items = {}
exports.utils = require('./utils') exports

exports.window = null

exports.pixelRatio = 1

exports.setWindow = (item) ->
