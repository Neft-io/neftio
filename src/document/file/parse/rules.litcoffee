# rule

Tag used in the parsing process.
Performs some actions on found elements in the parent element.

## props

Adds attributes if not exists.

```xml
<rule query="input[type=string]">
  <props class="specialInput" />
</rule>
```

    'use strict'

    utils = require 'src/utils'
    log = require 'src/log'

    log = log.scope 'Document', 'rule'

    commands =
        'props': (command, node) ->
            for name, val of command.props when command.props.hasOwnProperty(name)
                unless node.props.has(name)
                    node.props.set name, val
            return

    enterCommand = (command, node) ->
        unless commands[command.name]
            log.error "Rule '#{command.name}' not found"
            return

        commands[command.name] command, node
        return

    getNodeLength = (node) ->
        i = 0
        while node = node.parent
            i++
        i

    isMainFileRule = (node) ->
        while node = node.parent
            if node.name isnt 'blank' and node.name isnt 'rule'
                return false
        true

    module.exports = (File) ->
        fileRules = Object.create null

        (file) ->
            rules = []
            fileRules[file.path] = rules

            # get rules from this file
            localRules = file.node.queryAll 'rule'
            localRules.sort (a, b) ->
                getNodeLength(b) - getNodeLength(a)

            for rule in localRules
                query = rule.props.query
                unless query
                    log.error "rule no 'query' attribute found"
                    continue

                children = rule.children
                i = 0
                n = children.length
                while i < n
                    child = children[i]
                    if child.name is 'rule'
                        subquery = child.props['query']
                        if /^[A-Za-z]/.test(subquery)
                            subquery = query + ' ' + subquery
                        else
                            subquery = query + subquery
                        child.props.set 'query', subquery
                        child.parent = rule.parent
                        n--
                    else
                        i++

            for localRule in localRules
                rules.push
                    node: localRule
                    parent: localRule.parent
                localRule.parent = null

            for rule in rules
                unless query = rule.node.props['query']
                    continue

                nodes = rule.parent.queryAll query
                for node in nodes
                    for command in rule.node.children
                        enterCommand command, node

            return

# Glossary

- [rule](#rule)
