# Database

Access it with:
```javascript
var db = require('db');
```

    'use strict'

    utils = require 'src/utils'
    assert = require 'src/assert'
    List = require 'src/list'
    Dict = require 'src/dict'

    assert = assert.scope 'Database'

    NOP = ->

    impl = require './implementation'
    watchersCount = Object.create null
    watchers = Object.create null

## *Integer* db.OBSERVABLE

    exports.OBSERVABLE = 1<<29

    BITMASK = exports.OBSERVABLE

## db.get(*String* key, [*Integer* options], *Function* callback)

```javascript
db.set('items', [], function(){
\  db.get('items', db.OBSERVABLE, function(err, dict){
\    dict.onInserted(function(index){
\      console.log(this.get(index) + ' inserted!');
\    });
\
\    db.append('items', 'item1', function(){
\      // item1 inserted
\    });
\  });
});
```

    exports.get = (key, opts, callback) ->
        if typeof opts is 'function'
            callback = opts
            opts = 0
        assert.isString key
        assert.notLengthOf key, 0
        assert.isInteger opts
        assert.is opts | BITMASK, BITMASK, 'Invalid options bitmask'
        assert.isFunction callback

        if opts & exports.OBSERVABLE and watchers[key]?
            return callback null, watchers[key].spawn()

        impl.get key, (err, data) ->
            if err? or not data
                return callback err, data

            if opts & exports.OBSERVABLE
                if Array.isArray(data)
                    data = new DbList key, data, opts
                else if utils.isObject(data)
                    data = new DbDict key, data, opts
                data = watchers[key]?.spawn() or data

            callback null, data

        return

## db.set(*String* key, *Any* value, [*Function* callback])

    exports.set = (key, val, callback=NOP) ->
        assert.isString key
        assert.notLengthOf key, 0
        assert.isFunction callback

        watchers[key]?.disconnect()
        impl.set key, val, callback
        return

## db.remove(*String* key, [*Any* value, *Function* callback])

    exports.remove = (key, val, callback=NOP) ->
        if typeof val is 'function'
            callback = val
            val = null
        assert.isString key
        assert.notLengthOf key, 0
        assert.isFunction callback

        if val?
            exports.get key, (err, data) ->
                if err?
                    return callback err
                unless Array.isArray(data)
                    return callback new Error "'#{key}' is not an array"

                # remove from watcher
                if list = watchers[key]
                    if (index = list.items().indexOf(val)) isnt -1
                        list.pop index
                    else
                        for item, i in list.items()
                            if utils.isEqual(item, val)
                                list.pop i
                                break

                # remove from data
                if (index = data.indexOf(val)) isnt -1
                    data.splice index, 1
                else
                    for item, i in data
                        if utils.isEqual(item, val)
                            data.splice i, 1
                            break

                impl.set key, data, callback
        else
            watchers[key]?.disconnect()
            impl.remove key, callback
        return

## db.append(*String* key, *Any* value, [*Function* callback])

    exports.append = (key, val, callback=NOP) ->
        assert.isString key
        assert.notLengthOf key, 0
        assert.isFunction callback

        exports.get key, (err, data) ->
            if err?
                return callback err

            data ?= []
            unless Array.isArray(data)
                return callback new Error "'#{key}' is not an array"

            watchers[key]?.append val

            data.push val
            impl.set key, data, callback
        return

    createPassProperty = (object, name) ->
        utils.defineProperty object, name, null, ->
            Object.getPrototypeOf(@)[name]
        , (val) ->
            Object.getPrototypeOf(@)[name] = val

## *DbList* DbList() : *List*

    class DbList extends List
        onChange = (key) ->
            if @_watchersCount > 0
                impl.set @_key, @_data, NOP
            return

        constructor: (key, data, opts) ->
            super data

            @_key = key
            @_watchersCount = 0
            watchers[key] = @

            @onChange onChange
            @onInsert onChange
            @onPop onChange

        spawn: ->
            @_watchersCount += 1
            @

## DbList::disconnect()

        disconnect: ->
            unless --watchersCount[@_key]
                watchers[@_key] = null
            return

## *DbDict* DbDict() : *Dict*

    class DbDict extends Dict
        onChange = (key) ->
            if @_watchersCount > 0
                impl.set @_key, @, NOP
            return

        constructor: (key, data, opts) ->
            super data

            utils.defineProperty @, '_key', 0, key
            utils.defineProperty @, '_watchersCount', utils.WRITABLE, 0
            watchers[key] = @

            @onChange onChange

        spawn: ->
            @_watchersCount += 1
            @

## DbDict::disconnect()

        disconnect: ->
            unless --watchersCount[@_key]
                watchers[@_key] = null
            return
