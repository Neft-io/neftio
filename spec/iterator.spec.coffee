'use strict'

View = require '../index.coffee.md'
{describe, it} = require 'neft-unit'
assert = require 'neft-assert'
{renderParse, uid} = require './utils'
Dict = require 'neft-dict'
List = require 'neft-list'

describe 'neft:each', ->
	it 'loops expected times', ->
		source = View.fromHTML uid(), '<ul neft:each="[0,0]">1</ul>'
		View.parse source
		view = source.clone()

		renderParse view
		assert.is view.node.stringify(), '<ul>11</ul>'

	it 'provides `attrs.item` property', ->
		source = View.fromHTML uid(), '<ul neft:each="[1,2]">${attrs.item}</ul>'
		View.parse source
		view = source.clone()

		renderParse view
		assert.is view.node.stringify(), '<ul>12</ul>'

	it 'provides `attrs.index` property', ->
		source = View.fromHTML uid(), '<ul neft:each="[1,2]">${attrs.index}</ul>'
		View.parse source
		view = source.clone()

		renderParse view
		assert.is view.node.stringify(), '<ul>01</ul>'

	it 'provides `attrs.each` property', ->
		source = View.fromHTML uid(), '<ul neft:each="[1,2]">${attrs.each}</ul>'
		View.parse source
		view = source.clone()

		renderParse view
		assert.is view.node.stringify(), '<ul>1,21,2</ul>'

	it 'supports runtime updates', ->
		source = View.fromHTML uid(), '<ul neft:each="${this.arr}">${attrs.each[attrs.index]}</ul>'
		View.parse source
		view = source.clone()

		storage = arr: arr = new List [1, 2]

		renderParse view, storage: storage
		assert.is view.node.stringify(), '<ul>12</ul>'

		arr.insert 1, 'a'
		assert.is view.node.stringify(), '<ul>1a2</ul>'

		arr.pop 1
		assert.is view.node.stringify(), '<ul>12</ul>'

		arr.append 3
		assert.is view.node.stringify(), '<ul>123</ul>'

	it 'access global `this`', ->
		source = View.fromHTML uid(), '<ul neft:each="[1,2]">${this.a}</ul>'
		View.parse source
		view = source.clone()

		renderParse view,
			storage: a: 'a'
		assert.is view.node.stringify(), '<ul>aa</ul>'

	it 'access `ids`', ->
		source = View.fromHTML uid(), """
			<div id="a" prop="a" visible="false" />
			<ul neft:each="[1,2]">${ids.a.attrs.prop}</ul>
		"""
		View.parse source
		view = source.clone()

		renderParse view
		assert.is view.node.stringify(), '<ul>aa</ul>'

	it 'access neft:fragment `attrs`', ->
		source = View.fromHTML uid(), """
			<neft:fragment neft:name="a" a="a">
				<ul neft:each="[1,2]">${attrs.a}${attrs.b}</ul>
			</neft:fragment>
			<neft:use neft:fragment="a" b="b" />
		"""
		View.parse source
		view = source.clone()

		renderParse view
		assert.is view.node.stringify(), '<ul>abab</ul>'
