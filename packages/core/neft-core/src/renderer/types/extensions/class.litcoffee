# Class

    'use strict'

    assert = require '../../../assert'
    utils = require '../../../util'
    {SignalsEmitter} = require '../../../signal'
    log = require '../../../log'
    TagQuery = require '../../../document/element/element/tag/query'

    log = log.scope 'Rendering', 'Class'

    module.exports = (Renderer, Impl, itemUtils) ->
        CHANGES_OMIT_ATTRIBUTES =
            __proto__: null
            id: true
            properties: true
            signals: true
            children: true

        class ChangesObject
            constructor: (@_attributes, @_bindings, @_namespaces) ->
                @_attributes ?= Object.create null
                @_bindings ?= Object.create null
                @_namespaces ?= []

            setAttribute: (prop, val) ->
                @_attributes[prop] = val
                return

            setBinding: (prop, val) ->
                @_attributes[prop] = val
                @_bindings[prop] = true
                return

            setValue: (prop, val) ->
                path = splitAttribute prop

                if path.length > 1 and not utils.has(@_namespaces, path[0])
                    @_namespaces.push path[0]

                if Array.isArray(val) and val.length is 2 and typeof val[0] is 'function' and Array.isArray(val[1])
                    @setBinding prop, val
                else if not CHANGES_OMIT_ATTRIBUTES[prop]
                    @setAttribute prop, val

                return

            fillByObject: (obj) ->
                for prop, val of obj
                    @setValue prop, val
                return

            clone: ->
                attributes = Object.create @_attributes
                bindings = Object.create @_bindings
                namespaces = utils.clone @_namespaces
                new ChangesObject attributes, bindings, namespaces

        reloadNamespaceClasses = (classElem) ->
            changes = classElem._changes
            target = classElem._target

            if not changes or not target
                return

            initialized = false
            classElem._namespaceClasses = null

            for namespace in changes._namespaces
                if target[namespace] instanceof itemUtils.Object
                    namespaceClass = new Class
                    unless initialized
                        classElem._namespaceClasses = {}
                        initialized = true
                    classElem._namespaceClasses[namespace] = namespaceClass
                    for attr, attrVal of changes._attributes
                        path = splitAttribute attr
                        if path.length > 1 and path[0] is namespace
                            subAttr = path.slice(1).join('.')
                            namespaceClass.changes.setValue subAttr, attrVal

            return

        class Class extends Renderer.Extension
            @__name__ = 'Class'

## *Renderer.Class* Class.New([*Object* options])

            @New = (opts) ->
                item = new Class
                itemUtils.Object.initialize item, opts
                item

## *Class* Class::constructor() : *Renderer.Extension*

            lastUid = 0
            constructor: ->
                super()
                @_classUid = String(lastUid++)
                @_priority = 0
                @_inheritsPriority = 0
                @_nestingPriority = 0
                @_changes = null
                @_customProperties = null
                @_customSignals = null
                @_document = null
                @_children = null
                @_nesting = null
                @_namespaceClasses = null

## *Item* Class::target

Reference to the *Item* on which this class has effects.

If state is created inside the *Item*, this property is set automatically.

## *Signal* Class::onTargetChange(*Item* oldValue)

            itemUtils.defineProperty
                constructor: @
                name: 'target'
                developmentSetter: (val) ->
                    if val?
                        assert.instanceOf val, itemUtils.Object
                setter: (_super) -> (val) ->
                    oldVal = @_target

                    if oldVal is val
                        return

                    isRunning = @_running

                    if isRunning
                        @running = false

                    if oldVal
                        utils.remove oldVal._extensions, @
                        if @_running and not @_document?._query
                            unloadObjects @, oldVal

                    _super.call @, val

                    if val
                        val._extensions.push @

                        if val instanceof itemUtils.Object and Object.isExtensible(val)
                            if @_customProperties
                                for prop in @_customProperties
                                    if not (prop of val)
                                        itemUtils.Object.createProperty val, prop

                            if @_customSignals
                                for signal in @_customSignals
                                    if not (signal of val)
                                        itemUtils.Object.createSignal val, signal

                        reloadNamespaceClasses @

                        if @_priority isnt -1 and !@_bindings?.running and !@_document?._query
                            @running = true

                    if isRunning
                        @running = true
                    return

## *Object* Class::changes

This objects contains all properties to change on the target item.

            utils.defineProperty @::, 'changes', null, ->
                @_changes ||= new ChangesObject
            , (obj = {}) ->
                assert.isObject obj

                isRunning = @_running and !!@_target

                if isRunning
                    updateTargetClass disableClass, @_target, @

                @_changes = new ChangesObject
                @_changes.fillByObject obj
                reloadNamespaceClasses @

                if isRunning
                    updateTargetClass enableClass, @_target, @

                return

## *Object* Class::customProperties

            utils.defineProperty @::, 'customProperties', null, ->
                @_customProperties ||= []
            , (arr) ->
                assert.isArray arr
                assert.notOk @_running, "Changing class custom properties when running is not yet supported"
                @_customProperties = arr
                return

## *Object* Class::customSignals

            utils.defineProperty @::, 'customSignals', null, ->
                @_customSignals ||= []
            , (arr) ->
                assert.isArray arr
                assert.notOk @_running, "Changing class custom signals when running is not yet supported"
                @_customSignals = arr
                return

## *Integer* Class::priority = `0`

## *Signal* Class::onPriorityChange(*Integer* oldValue)

            itemUtils.defineProperty
                constructor: @
                name: 'priority'
                defaultValue: 0
                developmentSetter: (val) ->
                    assert.isInteger val
                setter: (_super) -> (val) ->
                    _super.call @, val
                    updatePriorities @
                    return

## *Boolean* Class::running

Indicates whether the class is active or not.

Mostly used with bindings.

```javascript
Grid {
    columns: 2
    // reduce to one column if the view width is lower than 500 pixels
    Class {
        running: windowItem.width < 500
        changes: {
            columns: 1
        }
    }
}
```

## *Signal* Class::onRunningChange(*Boolean* oldValue)

            _enable: ->
                assert.ok @_running

                docQuery = @_document?._query
                if not @_target or docQuery
                    if docQuery
                        for classElem in @_document._classesInUse
                            classElem.running = true
                    return

                updateTargetClass saveAndEnableClass, @_target, @

                unless @_document?._query
                    loadObjects @, @_target

                return

            _disable: ->
                assert.notOk @_running

                if not @_target
                    if @_document and @_document._query
                        for classElem in @_document._classesInUse
                            classElem.running = false
                    return

                unless @_document?._query
                    unloadObjects @, @_target

                updateTargetClass saveAndDisableClass, @_target, @
                return

## *Object* Class::children

            utils.defineProperty @::, 'children', null, ->
                @_children ||= new ChildrenObject(@)
            , (val) ->
                {children} = @

                # clear
                length = children.length
                while length--
                    children.pop length

                if val
                    assert.isArray val

                    for child in val
                        children.append child

                return

            utils.defineProperty @::, 'nesting', null, null, (val) ->
                assert.notOk @_running
                @_nesting = val
                return

            class ChildrenObject

## *Integer* Class::children.length = `0`

                constructor: (ref) ->
                    @_ref = ref
                    @length = 0

## *Object* Class::children.append(*Object* value)

                append: (val) ->
                    assert.instanceOf val, itemUtils.Object
                    assert.isNot val, @_ref

                    if val instanceof Class
                        updateChildPriorities @_ref, val

                    @[@length++] = val

                    val

## *Object* Class::children.pop(*Integer* index)

                pop: (i = @length - 1) ->
                    assert.operator i, '>=', 0
                    assert.operator i, '<', @length

                    oldVal = @[i]
                    delete @[i]
                    --@length

                    oldVal

            clone: ->
                clone = cloneClassWithNoDocument.call @

                if doc = @_document
                    cloneDoc = clone.document
                    cloneDoc.query = doc.query
                    for name, arr of doc._signals
                        cloneDoc._signals[name] = utils.clone arr

                clone

        loadObjects = (classElem, item) ->
            if children = classElem._children
                for child in children
                    if child instanceof Renderer.Item
                        child.parent ?= item
                    else
                        if child instanceof Class
                            updateChildPriorities classElem, child
                        child.target ?= item
            return

        unloadObjects = (classElem, item) ->
            if children = classElem._children
                for child in children
                    if child instanceof Renderer.Item
                        if child.parent is item
                            child.parent = null
                    else
                        if child.target is item
                            child.target = null
            return

        updateChildPriorities = (parent, child) ->
            child._inheritsPriority = parent._inheritsPriority + parent._priority
            child._nestingPriority = parent._nestingPriority + 1 + (child._document?._priority or 0)
            updatePriorities child
            return

        updatePriorities = (classElem) ->
            # refresh if needed
            if classElem._running and ifClassListWillChange(classElem)
                target = classElem._target
                updateTargetClass disableClass, target, classElem
                updateClassList target
                updateTargetClass enableClass, target, classElem

            # children
            if children = classElem._children
                for child in children
                    if child instanceof Class
                        updateChildPriorities classElem, child

            # document
            if document = classElem._document
                {_inheritsPriority, _nestingPriority} = classElem
                for child in document._classesInUse
                    child._inheritsPriority = _inheritsPriority
                    child._nestingPriority = _nestingPriority
                    updatePriorities child
                for child in document._classesPool
                    child._inheritsPriority = _inheritsPriority
                    child._nestingPriority = _nestingPriority
            return

        ifClassListWillChange = (classElem) ->
            unless target = classElem._target
                return false
            classList = target._classList
            index = classList.indexOf classElem

            if index > 0 and classListSortFunc(classElem, classList[index - 1]) < 0
                return true
            if index < classList.length - 1 and classListSortFunc(classElem, classList[index + 1]) > 0
                return true
            false

        classListSortFunc = (a, b) ->
            (b._priority + b._inheritsPriority) - (a._priority + a._inheritsPriority) or
            (b._nestingPriority) - (a._nestingPriority)

        updateClassList = (item) ->
            item._classList.sort classListSortFunc

        initializeNesting = (classElem) ->
            if typeof classElem._nesting is 'function'
                {changes, children} = classElem._nesting()
                if changes
                    if classElem._changes
                        classElem._changes = classElem._changes.clone()
                        classElem._changes.fillByObject changes
                    else
                        classElem.changes = changes
                if children
                    for child in children
                        if child instanceof Class and not child._document
                            initializeNesting child
                        classElem.children.append child
            return

        cloneClassChild = (classElem, child) ->
            child.clone()

        cloneClassWithNoDocument = ->
            clone = Class.New()
            clone.id = @id
            clone._path = @_path
            clone._classUid = @_classUid
            clone._priority = @_priority
            clone._inheritsPriority = @_inheritsPriority
            clone._nestingPriority = @_nestingPriority
            clone._changes = @_changes
            clone._customProperties = @_customProperties
            clone._customSignals = @_customSignals
            clone._nesting = @_nesting

            if @_bindings
                for prop, val of @_bindings
                    clone.createBinding prop, val

            # clone children
            if children = @_children
                for child, i in children
                    childClone = cloneClassChild clone, child
                    clone.children.append childClone

            # create nested objects
            initializeNesting clone

            clone

        {splitAttribute, getObjectByPath} = itemUtils

        setAttribute = (item, attr, val) ->
            path = splitAttribute attr
            if object = getObjectByPath(item, path)
                object[path[path.length - 1]] = val
            return

        saveAndEnableClass = (item, classElem) ->
            assert.notOk utils.has(item._classList, classElem)
            item._classList.unshift classElem
            if ifClassListWillChange(classElem)
                updateClassList item
            enableClass item, classElem

        saveAndDisableClass = (item, classElem) ->
            assert.ok utils.has(item._classList, classElem)
            disableClass item, classElem
            utils.remove item._classList, classElem

        ATTRS_CONFLICTS = [
            ['x', 'anchors.left', 'anchors.right', 'anchors.horizontalCenter', 'anchors.centerIn'],
            ['y', 'anchors.top', 'anchors.bottom', 'anchors.verticalCenter', 'anchors.centerIn'],
            ['width', 'anchors.fill', 'fillWidth'],
            ['height', 'anchors.fill', 'fillHeight'],
        ]

        ATTRS_ALIAS = Object.create null

        do ->
            # for conflicts we alias ant attr in a row with other attrs in a row
            for aliases in ATTRS_CONFLICTS
                for prop in aliases
                    arr = ATTRS_ALIAS[prop] ?= []
                    for alias in aliases
                        if alias isnt prop
                            arr.push alias
            return

        getContainedAttribute = (classElem, attr) ->
            if changes = classElem._changes
                attrs = changes._attributes
                if attrs[attr] isnt undefined
                    return attr
            return ''

        getContainedAlias = (classElem, attr) ->
            if changes = classElem._changes
                attrs = changes._attributes
                if aliases = ATTRS_ALIAS[attr]
                    for alias in aliases
                        if attrs[alias] isnt undefined
                            return alias
            return ''

        getContainedAttributeOrAlias = (classElem, attr) ->
            if changes = classElem._changes
                attrs = changes._attributes
                if attrs[attr] isnt undefined
                    return attr
                else if aliases = ATTRS_ALIAS[attr]
                    for alias in aliases
                        if attrs[alias] isnt undefined
                            return alias
            return ''

        getPropertyDefaultValue = (obj, prop) ->
            proto = Object.getPrototypeOf obj
            innerProp = itemUtils.getInnerPropName(prop)
            if innerProp of proto
                proto[innerProp]
            else
                proto[prop]

        logNoAttributeFound = (item, classElem, attr) ->
            query = classElem.document?._parent?.query
            path = classElem._path
            msg = ""
            if query and path
                msg = "Selector `#{query}` at `#{path}`"
            else if path
                msg = "Selector at `#{path}`"

            if msg
                msg += " tries to set unknown attribute `#{attr}` on `#{item}`"
            else
                msg = "Attribute `#{attr}` doesn't exist in `#{item}`"

            log.error msg
            return

        enableClass = (item, classElem) ->
            assert.instanceOf item, itemUtils.Object
            assert.instanceOf classElem, Class

            classList = item._classList
            classListIndex = classList.indexOf classElem
            classListLength = classList.length
            if classListIndex is -1
                return

            unless changes = classElem._changes
                return

            namespaceClasses = classElem._namespaceClasses
            attributes = changes._attributes
            bindings = changes._bindings

            # enable namespace classes
            if namespaceClasses
                for namespace, subClass of namespaceClasses
                    object = item[namespace]
                    if object
                        subClass.target = object
                        subClass._priority = classElem._priority * 10
                        subClass.running = true

            # attributes
            for attr, val of attributes
                path = splitAttribute attr

                # don't write if there is a namespace class
                if path.length > 1 and namespaceClasses?[path[0]]
                    continue

                # don't write if more important class has it
                writeAttr = true
                alias = ''
                for i in [classListIndex - 1..0] by -1
                    if getContainedAttributeOrAlias(classList[i], attr)
                        writeAttr = false
                        break

                if writeAttr
                    # unset alias
                    for i in [classListIndex + 1...classListLength] by 1
                        if (alias = getContainedAlias(classList[i], attr))
                            path = splitAttribute alias
                            object = getObjectByPath item, path
                            lastPath = path[path.length - 1]
                            unless object
                                continue
                            defaultValue = getPropertyDefaultValue object, lastPath
                            defaultIsBinding = !!classList[i].changes._bindings[alias]
                            if defaultIsBinding
                                object.createBinding lastPath, null, item
                            object[lastPath] = defaultValue
                            break

                    # set new attribute
                    if attr isnt alias or not path
                        path = splitAttribute attr
                        lastPath = path[path.length - 1]
                        object = getObjectByPath item, path

                    if not object or not (lastPath of object)
                        if process.env.NODE_ENV isnt 'production'
                            logNoAttributeFound item, classElem, attr
                        continue

                    if bindings[attr]
                        object.createBinding lastPath, val, item
                    else if typeof val is 'function' and object[lastPath]?.connect
                        object[lastPath].connect val, item
                    else
                        if object._bindings?[lastPath]
                            object.createBinding lastPath, null, item
                        object[lastPath] = val

            return

        disableClass = (item, classElem) ->
            assert.instanceOf item, itemUtils.Object
            assert.instanceOf classElem, Class

            classList = item._classList
            classListIndex = classList.indexOf classElem
            classListLength = classList.length
            if classListIndex is -1
                return

            unless changes = classElem._changes
                return

            namespaceClasses = classElem._namespaceClasses
            attributes = changes._attributes
            bindings = changes._bindings

            # disable namespace classes
            if namespaceClasses
                for namespace, subClass of namespaceClasses
                    subClass.running = false

            # attributes
            for attr, val of attributes
                path = splitAttribute attr
                restoreDefault = true

                # don't write if there is a namespace class
                if path.length > 1 and namespaceClasses?[path[0]]
                    continue

                # don't restore if this attribute is already set by more important class
                for i in [classListIndex - 1..0] by -1
                    if getContainedAttributeOrAlias(classList[i], attr)
                        restoreDefault = false
                        break

                if restoreDefault
                    # we firstly restore the attribute itself then alias
                    getAttributeMethod = getContainedAttribute
                    while getAttributeMethod
                        path = null
                        alias = ''

                        # get default value
                        defaultValue = undefined
                        defaultIsBinding = false
                        for i in [classListIndex + 1...classListLength] by 1
                            if alias = getAttributeMethod(classList[i], attr)
                                defaultValue = classList[i].changes._attributes[alias]
                                defaultIsBinding = !!classList[i].changes._bindings[alias]
                                break

                        if getAttributeMethod is getContainedAttribute
                            # we need to restore the original attribute in the next iteration
                            alias ||= attr
                            getAttributeMethod = getContainedAlias
                        else
                            # nothing to scan
                            getAttributeMethod = null

                        unless alias
                            continue

                        # restore binding
                        if !!bindings[attr]
                            path = splitAttribute attr
                            object = getObjectByPath item, path
                            lastPath = path[path.length - 1]
                            unless object
                                continue
                            object.createBinding lastPath, null, item

                        # set default value
                        if attr isnt alias or not path
                            path = splitAttribute alias
                            object = getObjectByPath item, path
                            lastPath = path[path.length - 1]
                            unless object
                                continue

                        if defaultIsBinding
                            object.createBinding lastPath, defaultValue, item
                        else if typeof val is 'function' and object[lastPath]?.connect
                            object[lastPath].disconnect val, item
                        else
                            if defaultValue is undefined
                                defaultValue = getPropertyDefaultValue object, lastPath
                            object[lastPath] = defaultValue

            return

        runQueue = (target) ->
            classQueue = target._classQueue
            [func, target, classElem] = classQueue
            func target, classElem
            classQueue.shift()
            classQueue.shift()
            classQueue.shift()
            if classQueue.length > 0
                runQueue target
            return

        updateTargetClass = (func, target, classElem) ->
            classQueue = target._classQueue
            classQueue.push func, target, classElem
            if classQueue.length is 3
                runQueue target
            return

        class ElementTarget extends itemUtils.Object
            constructor: (element) ->
                super()
                @_element = element
                Object.seal @

            itemUtils.defineProperty
                constructor: @
                name: 'element'
                defaultValue: null

        Class.ElementTarget = ElementTarget

## *Object* Class::document

        class ClassChildDocument
            constructor: (parent) ->
                @_ref = parent._ref
                @_parent = parent
                @_multiplicity = 0
                Object.preventExtensions @

        class ClassDocument extends itemUtils.DeepObject
            @__name__ = 'ClassDocument'

## *Signal* Class::onDocumentChange(*Object* document)

            itemUtils.defineProperty
                constructor: Class
                name: 'document'
                valueConstructor: @

            onTargetChange = (oldVal) ->
                if oldVal
                    oldVal.onElementChange.disconnect @reloadQuery, @
                if val = @_ref._target
                    val.onElementChange.connect @reloadQuery, @
                if oldVal isnt val
                    @reloadQuery()
                return

            constructor: (ref) ->
                @_query = ''
                @_queryElements = null
                @_classesInUse = []
                @_classesPool = []
                @_nodeWatcher = null
                @_priority = 0
                super ref

                ref.onTargetChange.connect onTargetChange, @
                onTargetChange.call @, ref._target

## *Signal* Class::document.onNodeAdd(*Element* node)

            SignalsEmitter.createSignal @, 'onNodeAdd'

## *Signal* Class::document.onNodeRemove(*Element* node)

            SignalsEmitter.createSignal @, 'onNodeRemove'

## *String* Class::document.query

## *Signal* Class::document.onQueryChange(*String* oldValue)

            itemUtils.defineProperty
                constructor: @
                name: 'query'
                defaultValue: ''
                namespace: 'document'
                parentConstructor: ClassDocument
                developmentSetter: (val) ->
                    assert.isString val
                setter: (_super) -> (val) ->
                    assert.notOk @_parent

                    if @_query is val
                        return

                    unless @_query
                        unloadObjects @, @_target

                    _super.call @, val
                    @reloadQuery()

                    # update priority
                    if @_ref._priority < 1
                        # TODO
                        # while calculating selector priority we take only the first query
                        # as a priority for the whole selector;
                        # to fix this we can split selector with multiple queries ('a, b')
                        # into separated class instances
                        cmdLen = TagQuery.getSelectorPriority val, 0, 1
                        oldPriority = @_priority
                        @_priority = cmdLen
                        @_ref._nestingPriority += cmdLen - oldPriority
                        updatePriorities @_ref

                    unless val
                        loadObjects @, @_target
                    return

            itemUtils.defineProperty
                constructor: @
                name: 'queryElements'
                defaultValue: ''
                namespace: 'document'
                parentConstructor: ClassDocument
                developmentSetter: (val) ->
                    assert.isArray val if val?
                setter: (_super) -> (val) ->
                    assert.notOk @_parent

                    if @_queryElements is val
                        return

                    _super.call @, val
                    @reloadQuery()

                    return

            getChildClass = (style, parentClass) ->
                for classElem in style._extensions
                    if classElem instanceof Class
                        if classElem._document?._parent is parentClass
                            return classElem
                return

            connectNodeStyle = (style) ->
                # omit duplications
                uid = @_ref._classUid
                for classElem in style._extensions
                    if classElem instanceof Class
                        if classElem isnt @_ref and classElem._classUid is uid and classElem._document instanceof ClassChildDocument
                            classElem._document._multiplicity++
                            return

                # get class
                unless classElem = @_classesPool.pop()
                    classElem = cloneClassWithNoDocument.call @_ref
                    classElem._document = new ClassChildDocument @

                # save
                @_classesInUse.push classElem
                classElem.target = style

                # run if needed
                if not classElem._bindings?.running
                    classElem.running = true
                return

            disconnectNodeStyle = (style) ->
                unless classElem = getChildClass(style, @)
                    return
                if classElem._document._multiplicity > 0
                    classElem._document._multiplicity--
                    return
                classElem.target = null
                utils.remove @_classesInUse, classElem
                @_classesPool.push classElem
                return

            onNodeStyleChange = (oldVal, val) ->
                if oldVal
                    disconnectNodeStyle.call @, oldVal
                if val
                    connectNodeStyle.call @, val
                return

            onNodeAdd = (node) ->
                node.onStyleChange.connect onNodeStyleChange, @
                if style = node._style
                    connectNodeStyle.call @, style
                @emit 'onNodeAdd', node
                return

            onNodeRemove = (node) ->
                node.onStyleChange.disconnect onNodeStyleChange, @
                if style = node._style
                    disconnectNodeStyle.call @, style
                @emit 'onNodeRemove', node
                return

            reloadQuery: ->
                # remove old
                @_nodeWatcher?.disconnect()
                @_nodeWatcher = null
                while classElem = @_classesInUse.pop()
                    classElem.target = null
                    @_classesPool.push classElem

                # add new ones
                if (query = @_query) and (target = @_ref.target) and (node = target.element) and node.watch
                    watcher = @_nodeWatcher = node.watch query, @_queryElements
                    watcher.onAdd.connect onNodeAdd, @
                    watcher.onRemove.connect onNodeRemove, @
                return

        Class
