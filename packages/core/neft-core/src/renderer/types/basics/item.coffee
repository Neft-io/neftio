'use strict'

assert = require '../../../assert'
utils = require '../../../util'
{SignalsEmitter} = require '../../../signal'
Matrix = require '../../utils/Matrix'

{isArray} = Array

assert = assert.scope 'Renderer.Item'

module.exports = (Renderer, Impl, itemUtils) -> class Item extends itemUtils.Object
    @__name__ = 'Item'

    DocElement = require '../../../document/element'

    @New = (opts) ->
        item = new Item
        itemUtils.Object.initialize item, opts
        item

    constructor: ->
        assert.instanceOf @, Item

        super()
        @_parent = null
        @_children = null
        @_previousSibling = null
        @_nextSibling = null
        @_belowSibling = null
        @_aboveSibling = null
        @_width = 0
        @_height = 0
        @_x = 0
        @_y = 0
        @_z = 0
        @_visible = true
        @_clip = false
        @_scale = 1
        @_rotation = 0
        @_opacity = 1
        @_anchors = null
        @_layout = null
        @_fillWidth = false
        @_fillHeight = false
        @_keys = null
        @_pointer = null
        @_margin = null
        @_padding = null
        @_columns = 2
        @_rows = Infinity
        @_spacing = null
        @_alignment = null
        @_classes = null
        @_query = ''
        @_element = null

    utils.defineProperty @::, 'query', null, ->
        @_query
    , (val) ->
        if @_query is ''
            @_query = val
        return

    itemUtils.defineProperty
        constructor: @
        name: 'element'
        defaultValue: null
        developmentSetter: (val) ->
            if val?
                assert.instanceOf val, DocElement

    SignalsEmitter.createSignal @, 'onAnimationFrame', do ->
        now = Date.now()
        items = []

        frame = ->
            oldNow = now
            now = Date.now()
            ms = now - oldNow

            for item in items
                item.emit 'onAnimationFrame', ms
            requestAnimationFrame frame

        requestAnimationFrame? frame

        (item) ->
            items.push item

    utils.defineProperty @::, 'children', null, ->
        @_children ||= new ChildrenObject(@)
    , (val) ->
        assert.isArray val, "Item.children needs to be an array, but #{val} given"
        @clear()
        for item in val
            val.parent = @
        return

    SignalsEmitter.createSignal @, 'onChildrenChange'

    class ChildrenObject extends itemUtils.MutableDeepObject
        constructor: (ref) ->
            @_firstChild = null
            @_lastChild = null
            @_bottomChild = null
            @_topChild = null
            @_length = 0
            super ref

        utils.defineProperty @::, 'firstChild', null, ->
            @_firstChild
        , null

        utils.defineProperty @::, 'lastChild', null, ->
            @_lastChild
        , null

        utils.defineProperty @::, 'bottomChild', null, ->
            @_bottomChild
        , null

        utils.defineProperty @::, 'topChild', null, ->
            @_topChild
        , null

        utils.defineProperty @::, 'length', null, ->
            @_length
        , null

        get: (val) ->
            assert.operator val, '>=', 0, """
                Item.children.get index cannot be lower than zero, #{val} given
            """
            assert.operator val, '<', @length, """
                Item.children.get index must be lower than children.length, \
                #{val} given
            """

            if val < @length / 2
                sibling = @firstChild
                while val > 0
                    sibling = sibling.nextSibling
                    val--
            else
                sibling = @lastChild
                while val > 0
                    sibling = sibling.previousSibling
                    val--

            sibling

        index: (val) ->
            if @has(val)
                val.index
            else
                -1

        has: (val) ->
            @_ref is val._parent

        clear: ->
            while last = @last
                last.parent = null
            return

    setFakeParent = (child, parent, index=-1) ->
        child.parent = null

        if index >= 0 and parent.children._length < index
            Impl.insertItemBefore.call child, parent.children[index]
        else
            Impl.setItemParent.call child, parent

        child._parent = parent
        child.emit 'onParentChange', null
        return

    updateZSiblingsForAppendedItem = (item, z, newChildren) ->
        child = newChildren._topChild
        while child
            if child._z <= z
                if item._aboveSibling = child._aboveSibling
                    item._aboveSibling._belowSibling = item
                item._belowSibling = child
                child._aboveSibling = item
                return
            unless nextChild = child._belowSibling
                item._aboveSibling = child
                child._belowSibling = item
                item._belowSibling = null
                return
            child = nextChild
        return

    insertItemInImpl = (item) ->
        if aboveSibling = item._aboveSibling
            Impl.insertItemBefore.call item, aboveSibling
        else
            Impl.setItemParent.call item, item._parent
        return

    itemUtils.defineProperty
        constructor: @
        name: 'parent'
        defaultValue: null
        setter: (_super) -> (val = null) ->
            old = @_parent
            oldChildren = old?.children
            valChildren = val?.children

            if old is val
                return

            assert.isNot @, val, "Item.parent cannot be set with context item, #{val} given"

            if pointer = @_pointer
                pointer.hover = pointer.pressed = false

            if val isnt null
                assert.instanceOf val, Item, """
                    Item.parent needs to be an Item or null, but #{val} given
                """

            # old siblings
            oldPreviousSibling = @_previousSibling
            oldNextSibling = @_nextSibling
            if oldPreviousSibling isnt null
                oldPreviousSibling._nextSibling = oldNextSibling
            if oldNextSibling isnt null
                oldNextSibling._previousSibling = oldPreviousSibling

            # new siblings
            if val isnt null
                if previousSibling = @_previousSibling = valChildren.lastChild
                    previousSibling._nextSibling = @
            else
                @_previousSibling = null
            if oldNextSibling isnt null
                @_nextSibling = null

            # children
            if oldChildren
                oldChildren._length -= 1
                if oldChildren.firstChild is @
                    oldChildren._firstChild = oldNextSibling
                if oldChildren.lastChild is @
                    oldChildren._lastChild = oldPreviousSibling
            if valChildren
                if ++valChildren._length is 1
                    valChildren._firstChild = @
                valChildren._lastChild = @

            # old z-index siblings
            oldBelowSibling = @_belowSibling
            oldAboveSibling = @_aboveSibling
            if oldBelowSibling isnt null
                oldBelowSibling._aboveSibling = oldAboveSibling
            if oldAboveSibling isnt null
                oldAboveSibling._belowSibling = oldBelowSibling

            # new z-index siblings
            @_belowSibling = @_aboveSibling = null
            if valChildren
                updateZSiblingsForAppendedItem @, @_z, valChildren

            # z-index children
            if oldChildren
                unless oldAboveSibling
                    oldChildren._topChild = oldBelowSibling
                unless oldBelowSibling
                    oldChildren._bottomChild = oldAboveSibling
            if valChildren
                unless @_aboveSibling
                    valChildren._topChild = @
                unless @_belowSibling
                    valChildren._bottomChild = @

            # parent
            @_parent = val
            insertItemInImpl @

            if process.env.NODE_ENV isnt 'production'
                assert.is @nextSibling, null
                if val
                    assert.is val.children.lastChild, @
                    assert.isDefined val.children.firstChild
                    assert.isDefined val.children.lastChild
                    assert.isDefined val.children.topChild
                    assert.isDefined val.children.bottomChild
                if old and old.children.length is 0
                    assert.isNotDefined old.children.firstChild
                    assert.isNotDefined old.children.lastChild
                    assert.isNotDefined old.children.topChild
                    assert.isNotDefined old.children.bottomChild

            # signals
            if old isnt null
                old.emit 'onChildrenChange', null, @
            if val isnt null
                val.emit 'onChildrenChange', @, null

            @emit 'onParentChange', old

            if oldPreviousSibling isnt null
                oldPreviousSibling.emit 'onNextSiblingChange', @
            if oldNextSibling isnt null
                oldNextSibling.emit 'onPreviousSiblingChange', @

            if val isnt null or oldPreviousSibling isnt null
                if previousSibling
                    previousSibling.emit 'onNextSiblingChange', null
                @emit 'onPreviousSiblingChange', oldPreviousSibling
            if oldNextSibling isnt null
                @emit 'onNextSiblingChange', oldNextSibling

            return

    utils.defineProperty @::, 'previousSibling', null, ->
        @_previousSibling
    , (val = null) ->
        assert.isNot @, val, """
            Item.previousSibling cannot be set with context Item, #{val} given
        """

        if val is @_previousSibling
            return

        if val
            assert.instanceOf val, Item, """
                Item.previousSibling must be an Item or null, but #{val} given
            """
            nextSibling = val._nextSibling
            if not nextSibling and val._parent isnt @_parent
                @parent = val._parent
            else
                @nextSibling = nextSibling
        else
            assert.isDefined @_parent, """
                Cannot null Item.previousSibling when Item has no parent
            """
            @nextSibling = @_parent.children.firstChild

        assert.is @_previousSibling, val
        return

    SignalsEmitter.createSignal @, 'onPreviousSiblingChange'

    isNextSibling = (item, sibling) ->
        while item
            nextItem = item._nextSibling
            if nextItem is sibling
                return true
            item = nextItem
        return false

    isPreviousSibling = (item, sibling) ->
        while item
            prevItem = item._previousSibling
            if prevItem is sibling
                return true
            item = prevItem
        return false

    updateZSiblingsForInsertedItem = (item, nextSibling, z, newChildren) ->
        if nextSibling._z is z
            # simple case - the same z-index as in nextSibling
            if item._belowSibling = nextSibling._belowSibling
                item._belowSibling._aboveSibling = item
            item._aboveSibling = nextSibling
            nextSibling._belowSibling = item
        else
            # hard case - different z-indexes
            nextChild = newChildren._bottomChild
            while child = nextChild
                nextChild = child._aboveSibling
                if child._z > z or (child._z is z and isNextSibling(item, child))
                    item._aboveSibling = child
                    if item._belowSibling = child._belowSibling
                        item._belowSibling._aboveSibling = item
                    child._belowSibling = item
                    break
                unless nextChild
                    item._aboveSibling = null
                    item._belowSibling = child
                    child._aboveSibling = item
        return

    utils.defineProperty @::, 'nextSibling', null, ->
        @_nextSibling
    , (val = null) ->
        assert.isNot @, val, """
            Item.nextSibling cannot be set with context Item, #{val} given
        """
        if val
            assert.instanceOf val, Item, """
                Item.nextSibling needs to be an Item or null, but #{val} given
            """
            assert.isDefined val._parent, """
                Item.nextSibling value needs to have a parent, given #{val} has no parent
            """
        else
            assert.isDefined @_parent, """
                Cannot null Item.nextSibling when Item has no parent
            """

        if val is @_nextSibling
            return

        oldParent = @_parent
        oldChildren = oldParent?._children
        oldPreviousSibling = @_previousSibling
        oldNextSibling = @_nextSibling

        if val
            newParent = val._parent
            newChildren = newParent._children
        else
            newParent = oldParent
            newChildren = oldChildren

        # new parent
        @_parent = newParent

        # current siblings
        oldPreviousSibling?._nextSibling = oldNextSibling
        oldNextSibling?._previousSibling = oldPreviousSibling

        # new siblings
        previousSibling = previousSiblingOldNextSibling = null
        nextSibling = nextSiblingOldPreviousSibling = null
        if val
            if previousSibling = val._previousSibling
                previousSiblingOldNextSibling = previousSibling._nextSibling
                previousSibling._nextSibling = @

            nextSibling = val
            nextSiblingOldPreviousSibling = nextSibling._previousSibling
            nextSibling._previousSibling = @
        else
            if previousSibling = newChildren.lastChild
                previousSibling._nextSibling = @

        @_previousSibling = previousSibling
        @_nextSibling = nextSibling

        # children
        if oldChildren
            oldChildren._length -= 1
            unless oldPreviousSibling
                oldChildren._firstChild = oldNextSibling
            unless oldNextSibling
                oldChildren._lastChild = oldPreviousSibling
        newChildren._length += 1
        if newChildren.firstChild is val
            newChildren._firstChild = @
        unless val
            newChildren._lastChild = @

        # old z-index siblings
        oldBelowSibling = @_belowSibling
        oldAboveSibling = @_aboveSibling
        if oldBelowSibling isnt null
            oldBelowSibling._aboveSibling = oldAboveSibling
        if oldAboveSibling isnt null
            oldAboveSibling._belowSibling = oldBelowSibling

        # new z-index siblings
        @_belowSibling = @_aboveSibling = null
        if nextSibling
            updateZSiblingsForInsertedItem @, nextSibling, @_z, newChildren
        else
            updateZSiblingsForAppendedItem @, @_z, newChildren

        # z-index children
        if oldChildren
            unless oldAboveSibling
                oldChildren._topChild = oldBelowSibling
            unless oldBelowSibling
                oldChildren._bottomChild = oldAboveSibling
        unless @_aboveSibling
            newChildren._topChild = @
        unless @_belowSibling
            newChildren._bottomChild = @

        # implementation
        insertItemInImpl @

        if process.env.NODE_ENV isnt 'production'
            assert.is @_nextSibling, val
            assert.is @_parent, newParent
            if val
                assert.is @_parent, val._parent
            if @_previousSibling
                assert.is @_previousSibling._nextSibling, @
            if @_nextSibling
                assert.is @_nextSibling._previousSibling, @
            if oldPreviousSibling
                assert.is oldPreviousSibling._nextSibling, oldNextSibling
            if oldNextSibling
                assert.is oldNextSibling._previousSibling, oldPreviousSibling

        # children signal
        if oldParent isnt newParent
            if oldParent
                oldParent.emit 'onChildrenChange', null, @
            newParent.emit 'onChildrenChange', @, null
            @emit 'onParentChange', oldParent
        else
            newParent.emit 'onChildrenChange', null, null

        # current siblings signals
        if oldPreviousSibling
            oldPreviousSibling.emit 'onNextSiblingChange', @
        if oldNextSibling
            oldNextSibling.emit 'onPreviousSiblingChange', @

        # new siblings signals
        @emit 'onPreviousSiblingChange', oldPreviousSibling
        if previousSibling
            previousSibling.emit 'onNextSiblingChange', previousSiblingOldNextSibling
        @emit 'onNextSiblingChange', oldNextSibling
        if nextSibling
            nextSibling.emit 'onPreviousSiblingChange', nextSiblingOldPreviousSibling

        return

    SignalsEmitter.createSignal @, 'onNextSiblingChange'

    utils.defineProperty @::, 'belowSibling', null, ->
        @_belowSibling
    , null

    utils.defineProperty @::, 'aboveSibling', null, ->
        @_aboveSibling
    , null

    utils.defineProperty @::, 'index', null, ->
        index = 0
        sibling = @
        while sibling = sibling.previousSibling
            index++
        index
    , (val) ->
        assert.isInteger val, "Item.index needs to be a integer, but #{val} given"
        assert.isDefined @_parent, """
            When setting Item.index, item needs to have a parent, #{@} has no parent
        """
        assert.operator val, '>=', 0, "Item.index needs to greater than zero, #{val} given"
        assert.operator val, '<=', @_parent._children.length, """
            Item.index needs to be lower than parent.children.length, #{val} given
        """

        {children} = @parent
        if val >= children.length
            @nextSibling = null
        else if (valItem = children.get(val)) isnt @
            @nextSibling = valItem

        return

    itemUtils.defineProperty
        constructor: @
        name: 'visible'
        defaultValue: true
        implementation: Impl.setItemVisible
        developmentSetter: (val) ->
            assert.isBoolean val, "Item.visible needs to be a boolean, but #{val} given"

    itemUtils.defineProperty
        constructor: @
        name: 'clip'
        defaultValue: false
        implementation: Impl.setItemClip
        developmentSetter: (val) ->
            assert.isBoolean val, "Item.clip needs to be a boolean, but #{val} given"

    itemUtils.defineProperty
        constructor: @
        name: 'width'
        defaultValue: 0
        implementation: Impl.setItemWidth
        developmentSetter: (val) ->
            assert.isFloat val, "Item.width needs to be a float, but #{val} given"

    itemUtils.defineProperty
        constructor: @
        name: 'height'
        defaultValue: 0
        implementation: Impl.setItemHeight
        developmentSetter: (val) ->
            assert.isFloat val, "Item.height needs to be a float, but #{val} given"

    itemUtils.defineProperty
        constructor: @
        name: 'x'
        defaultValue: 0
        implementation: Impl.setItemX
        developmentSetter: (val) ->
            assert.isFloat val, "Item.x needs to be a float, but #{val} given"

    itemUtils.defineProperty
        constructor: @
        name: 'y'
        defaultValue: 0
        implementation: Impl.setItemY
        developmentSetter: (val) ->
            assert.isFloat val, "Item.y needs to be a float, but #{val} given"

    itemUtils.defineProperty
        constructor: @
        name: 'z'
        defaultValue: 0
        developmentSetter: (val) ->
            assert.isFloat val, "Item.z needs to be a float, but #{val} given"
        setter: (_super) -> (val) ->
            oldVal = @_z
            if oldVal is val
                return

            _super.call @, val

            unless parent = @_parent
                return
            children = parent._children
            oldAboveSibling = @_aboveSibling
            oldBelowSibling = @_belowSibling

            # new siblings
            if val > oldVal
                nextChild = @_aboveSibling
                while child = nextChild
                    nextChild = child._aboveSibling
                    if child._z > val or (child._z is val and isNextSibling(@, child))
                        if oldAboveSibling is child
                            break
                        @_aboveSibling = child
                        if @_belowSibling = child._belowSibling
                            @_belowSibling._aboveSibling = @
                        child._belowSibling = @
                        break
                    unless nextChild
                        @_aboveSibling = null
                        @_belowSibling = child
                        child._aboveSibling = @

            if val < oldVal
                prevChild = @_belowSibling
                while child = prevChild
                    prevChild = child._belowSibling
                    if child._z < val or (child._z is val and isPreviousSibling(@, child))
                        if oldBelowSibling is child
                            break
                        @_belowSibling = child
                        aboveSibling = child._aboveSibling
                        if @_aboveSibling = child._aboveSibling
                            @_aboveSibling._belowSibling = @
                        child._aboveSibling = @
                        break
                    unless prevChild
                        @_belowSibling = null
                        @_aboveSibling = child
                        child._belowSibling = @

            # clean old siblings
            if oldBelowSibling and oldBelowSibling isnt @_belowSibling
                oldBelowSibling._aboveSibling = oldAboveSibling
            if oldAboveSibling and oldAboveSibling isnt @_aboveSibling
                oldAboveSibling._belowSibling = oldBelowSibling

            # new children
            if @_belowSibling
                if children._bottomChild is @
                    children._bottomChild = oldAboveSibling
            else
                children._bottomChild = @
            if @_aboveSibling
                if children._topChild is @
                    children._topChild = oldBelowSibling
            else
                children._topChild = @

            # implementation
            if oldAboveSibling isnt @_aboveSibling
                insertItemInImpl @

            if process.env.NODE_ENV isnt 'production'
                assert.isNot @_belowSibling, @
                assert.isNot @_belowSibling?._belowSibling, @
                assert.isNot @_aboveSibling, @
                assert.isNot @_aboveSibling?._aboveSibling, @
                if @_belowSibling
                    assert.is @_belowSibling._aboveSibling, @
                if @_aboveSibling
                    assert.is @_aboveSibling._belowSibling, @
            return

    itemUtils.defineProperty
        constructor: @
        name: 'scale'
        defaultValue: 1
        implementation: Impl.setItemScale
        developmentSetter: (val) ->
            assert.isFloat val, "Item.scale needs to be a float, but #{val} given"

    itemUtils.defineProperty
        constructor: @
        name: 'rotation'
        defaultValue: 0
        implementation: Impl.setItemRotation
        developmentSetter: (val) ->
            assert.isFloat val, "Item.rotation needs to be a float, but #{val} given"

    itemUtils.defineProperty
        constructor: @
        name: 'opacity'
        defaultValue: 1
        implementation: Impl.setItemOpacity
        developmentSetter: (val) ->
            assert.isFloat val, "Item.opacity needs to be a float, but #{val} given"

    itemUtils.defineProperty
        constructor: @
        name: 'layout'
        defaultValue: null
        implementation: Impl.setItemLayout
        developmentSetter: (val) ->
            if val isnt null
                assert.isString val

    itemUtils.defineProperty
        constructor: @
        name: 'fillWidth'
        defaultValue: false
        implementation: Impl.setItemFillWidth
        developmentSetter: (val) ->
            assert.isBoolean val

    itemUtils.defineProperty
        constructor: @
        name: 'fillHeight'
        defaultValue: false
        implementation: Impl.setItemFillHeight
        developmentSetter: (val) ->
            assert.isBoolean val

    itemUtils.defineProperty
        constructor: @
        name: 'columns'
        defaultValue: 2
        implementation: Impl.setItemColumns
        developmentSetter: (val) ->
            assert.operator val, '>=', 0
        setter: (_super) -> (val) ->
            if val <= 0
                val = 1
            _super.call @, val

    itemUtils.defineProperty
        constructor: @
        name: 'rows'
        defaultValue: Infinity
        implementation: Impl.setItemRows
        developmentSetter: (val) ->
            assert.operator val, '>=', 0
        setter: (_super) -> (val) ->
            if val <= 0
                val = 1
            _super.call @, val

    scaleInPoint: (scale, pointX, pointY) ->
        oldScale = @scale

        # scale
        @scale = scale

        # move to point horizontal
        {width} = @
        widthChange = (width * scale - width * oldScale) / 2
        xOriginToChange = -2 * (pointX / width) + 1
        @x += xOriginToChange * widthChange

        # move to point vertical
        {height} = @
        heightChange = (height * scale - height * oldScale) / 2
        yOriginToChange = -2 * (pointY / height) + 1
        @y += yOriginToChange * heightChange

        return

    getGlobalComputes: ->
        m = new Matrix()
        {visible, opacity} = @

        chain = []
        item = @
        while item
            chain.push(item)

            visible and= item.visible
            opacity *= item.opacity
            item = item.parent

        for item in chain by -1
            originX = item.width / 2
            originY = item.height / 2

            m.translate(item.x + originX, item.y + originY)
            m.scale(item.scale)
            m.rotate(item.rotation)
            m.translate(-originX, -originY)

        mScale = m.getScale()
        mRotation = m.getRotation()

        m2 = new Matrix()
        m2.translate(-@width / 2, -@height / 2)
        m2.rotate(mRotation)
        m2.translate(@width * mScale / 2, @height * mScale / 2)

        mTranslate = m.getTranslate()
        m2Translate = m2.getTranslate()

        x: mTranslate.x + m2Translate.x
        y: mTranslate.y + m2Translate.y
        scale: mScale
        rotation: mRotation

    @createSpacing = require('./item/spacing') Renderer, Impl, itemUtils, Item
    @createAlignment = require('./item/alignment') Renderer, Impl, itemUtils, Item
    @createAnchors = require('./item/anchors') Renderer, Impl, itemUtils, Item
    @createMargin = require('./item/margin') Renderer, Impl, itemUtils, Item
    @createPointer = require('./item/pointer') Renderer, Impl, itemUtils, Item
    @createKeys = require('./item/keys') Renderer, Impl, itemUtils, Item

    @createAnchors @
    @Pointer = @createPointer @
    @createMargin @
    @createMargin @, propertyName: 'padding'
    @createAlignment @
    @createSpacing @
    @Keys = @createKeys @

    Item
