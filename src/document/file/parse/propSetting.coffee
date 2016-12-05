'use strict'

module.exports = (File) ->
    {PropsToSet} = File
    {Tag} = File.Element

    (file) ->
        {propsToSet} = file

        forEachNodeRec = (node) ->
            for child in node.children
                unless child instanceof Tag
                    continue

                forEachNodeRec child

                nodeProps = null
                for prop of child.props when child.props.hasOwnProperty(prop)
                    if prop in ['name', 'children', 'props', 'style']
                        continue
                    unless prop of child
                        continue
                    nodeProps ?= {}
                    nodeProps[prop] = true

                if nodeProps
                    propsToSet.push new PropsToSet file, child, nodeProps
            return

        forEachNodeRec file.node

        return
