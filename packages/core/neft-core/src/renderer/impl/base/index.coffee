'use strict'

utils = require '../../../util'

exports.Types =
    Item: require './level0/item'
    Image: require './level0/image'
    Text: require './level0/text'
    Native: require './level0/native'
    FontLoader: require './level0/loader/font'
    Device: require './level0/device'
    Screen: require './level0/screen'
    Navigator: require './level0/navigator'

    Rectangle: require './level1/rectangle'

    Animation: require './level1/animation'
    PropertyAnimation: require './level1/animation/property'
    NumberAnimation: require './level1/animation/number'

exports.Extras =
    Binding: require './level1/binding'
    Anchors: require './level1/anchors'

exports.items = {}
exports.utils = require('./utils') exports

exports.pixelRatio = 1

exports.setWindow = (item) ->
