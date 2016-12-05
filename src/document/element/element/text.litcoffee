# Text

    'use strict'

    utils = require 'src/utils'
    assert = require 'src/assert'
    signal = require 'src/signal'

    {emitSignal} = signal.Emitter

    assert = assert.scope 'View.Element.Text'

    module.exports = (Element) -> class Text extends Element
        @__name__ = 'Text'
        @__path__ = 'File.Element.Text'

        JSON_CTOR_ID = @JSON_CTOR_ID = Element.JSON_CTORS.push(Text) - 1

        i = Element.JSON_ARGS_LENGTH
        JSON_TEXT = i++
        JSON_ARGS_LENGTH = @JSON_ARGS_LENGTH = i

        @_fromJSON = (arr, obj=new Text) ->
            Element._fromJSON arr, obj
            obj._text = arr[JSON_TEXT]
            obj

## *Text* Text::constructor() : *Element*

        constructor: ->
            Element.call this

            @_text = ''

            `//<development>`
            if @constructor is Text
                Object.seal @
            `//</development>`

        clone: (clone = new Text) ->
            super clone
            clone._text = @_text
            clone

## *String* Text::text

        opts = utils.CONFIGURABLE
        utils.defineProperty @::, 'text', opts, ->
            @_text
        , (value) ->
            assert.isString value

            old = @_text
            if old is value
                return false

            # set text
            @_text = value

            # trigger event
            emitSignal @, 'onTextChange', old
            Element.Tag.query.checkWatchersDeeply @

            true

## *Signal* Text::onTextChange(*String* oldValue)

        signal.Emitter.createSignal @, 'onTextChange'

        toJSON: (arr) ->
            unless arr
                arr = new Array JSON_ARGS_LENGTH
                arr[0] = JSON_CTOR_ID
            super arr
            arr[JSON_TEXT] = @text
            arr
