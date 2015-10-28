'use strict'

utils = require 'utils'
Element = require('../index')

isEqualArrays = (arr1, arr2) ->
	if arr1.length isnt arr2.length
		return false

	for elem, i in arr1
		if arr2[i] isnt elem
			return false
	true

describe 'View Element', ->

	HTML = '<b><em>abc</em></b><u></u><p title="textTitle" class="a bb c2" data-custom="customValue"></p>'
	doc = null
	b = em = div = p = null

	describe 'parsed html', ->

		it 'is an Element', ->

			doc = Element.fromHTML HTML

			expect(doc).toEqual jasmine.any Element

			b = doc.children[0]
			em = b.children[0]
			div = doc.children[1]
			p = doc.children[2]

		it 'has proper amount of children', ->

			expect(doc.children.length).toBe 3
			expect(b.children.length).toBe 1
			expect(em.children.length).toBe 1
			expect(div.children.length).toBe 0
			expect(p.children.length).toBe 0

		it 'has proper elements names', ->

			expect(doc.name).toBe 'neft:blank'
			expect(b.name).toBe 'b'
			expect(em.name).toBe 'em'
			expect(div.name).toBe 'u'

	it 'stringify to html', ->

		html = doc.stringify()

		expect(html).toBe HTML

	it 'hidden attrs are omitted in the stringified process', ->

		elem = Element.fromHTML '<span neft:if="a" neft:each="a"></span>'
		html = elem.stringify()

		expect(html).toBe '<span></span>'

	it 'stringify children to html', ->

		elem = Element.fromHTML '<span><b></b></span>'
		htmlOuter = elem.children[0].stringify()
		htmlInner = elem.children[0].stringifyChildren()

		expect(htmlOuter).toBe '<span><b></b></span>'
		expect(htmlInner).toBe '<b></b>'

	it 'change parents properly', ->

		em.parent = div
		p.parent = undefined

		expect(em.parent).toBe div
		expect(b.children.length).toBe 0
		expect(div.children.length).toBe 1
		expect(div.children[0]).toBe em
		expect(doc.stringify()).toBe '<b></b><u><em>abc</em></u>'
		expect(-> em.parent = em).toThrow()

		em.parent = b
		p.parent = doc

	describe 'text property', ->

		it 'is filled properly', ->

			expect(b.text).toBeUndefined()
			expect(em.text).toBeUndefined()
			expect(em.children[0].text).toBe 'abc'

		it 'can be changed', ->

			em.children[0].text = '123'
			expect(em.children[0].text).toBe '123'
			expect(b.children[0]).toBe em
			expect(b.stringify()).toBe '<b><em>123</em></b>'

			em.children[0].text = '123'

			# change text with elements in html
			# b.text = '<em>123</em>'
			# b.text = '<em>345</em>'
			# expect(b.children.length).toBe 1
			# expect(b.children[0].name).toBe 'em'
			# expect(b.children[0].children[0].text).toBe '345'
			# expect(b.children[0]).not.toBe em
			# expect(em.parent).toBeUndefined()

			# b.children[0].parent = undefined
			# em.parent = b
	
	it 'can be cloned deep', ->

		clone = b.cloneDeep()
		# clone.attrs.set 'a', 'a'

		expect(clone).toEqual jasmine.any Element
		expect(clone).not.toBe b
		# expect(b.attrs.get 'a').not.toBe 'a'
		expect(clone.children[0]).toEqual jasmine.any Element
		expect(clone.children[0]).not.toBe em
		expect(clone.children[0].name).toBe 'em'

		# clone.attrs.set 'a', undefined
		# expect(clone.stringify()).toBe b.stringify()

	describe 'attrs', ->

		it 'are filled properly', ->

			expect(doc.attrs.item(0)).toEqual [undefined, undefined]
			expect(div.attrs.item(0)).toEqual [undefined, undefined]
			expect(p.attrs.item(0)).toEqual ['title', 'textTitle']
			expect(p.attrs.item(1)).toEqual ['class', 'a bb c2']
			expect(p.attrs.item(2)).toEqual ['data-custom', 'customValue']

			expect(p.attrs.get('title')).toBe 'textTitle'

		it 'can be changed', ->

			elem = p.clone()

			expect(elem.attrs.get 'title').toBe 'textTitle'

			# change
			elem.attrs.set 'title', 'changed value'
			expect(elem.attrs.get 'title').toBe 'changed value'

		it 'can store references to the objects', ->

			elem = p.clone()
			title = elem.attrs.get 'title'
			obj = a: 1

			# change
			elem.attrs.set 'title', obj
			expect(elem.attrs.get 'title').toBe obj
			expect(elem.stringify()).toBe '<p title="[object Object]" class="a bb c2" data-custom="customValue"></p>'

			elem.attrs.set 'title', title

	describe 'index property', ->

		it 'returns child index in the parent', ->

			expect(div.index).toBe 1

		it 'change child index in the parent', ->

			elem = Element.fromHTML '<a></a><b></b>'
			[elemA, elemB] = elem.children

			elemB.index = 0

			expect(elem.children).toEqual [elemB, elemA]

	it 'replace() works properly', ->

		elem = Element.fromHTML '<b><em></em></b><u></u><p></p>'

		[elemB, elemDiv, elemP] = elem.children
		[elemEm] = b.children

		elem.replace elemB, elemP

		expect(elem.children.length).toBe 2
		expect(elem.children[0]).toBe elemP
		expect(elem.stringify()).toBe '<p></p><u></u>'

		elem.replace elemP, elemB
		elemP.parent = elem

		expect(elem.children.length).toBe 3
		expect(elem.children[0]).toBe elemB
		expect(elem.children[1]).toBe elemDiv
		expect(elem.children[2]).toBe elemP
		expect(elem.stringify()).toBe '<b><em></em></b><u></u><p></p>'

	describe 'queryAll() works with selector', ->
		doc2 = Element.fromHTML "<div><b class='first second'><u color='blue' attr='1'><u></u></u></b></div><div attr='2'><neft:blank><em></em></neft:blank><em></em></div>"
		doc2div1 = doc2.children[0]
		doc2b = doc2div1.children[0]
		doc2u = doc2b.children[0]
		doc2u2 = doc2b.children[0].children[0]
		doc2div2 = doc2.children[1]
		doc2em1 = doc2div2.children[0].children[0]
		doc2em2 = doc2div2.children[1]

		it 'E', ->
			expect(doc2.queryAll('div')).toEqual [doc2div1, doc2div2]
			expect(doc2.queryAll('u')).toEqual [doc2u, doc2u2]

		it 'E F', ->
			expect(doc2.queryAll('div u')).toEqual [doc2u, doc2u2]
			expect(doc2.queryAll('b u')).toEqual [doc2u, doc2u2]
			expect(doc2.queryAll('b div')).toEqual []

		it 'E > F', ->
			expect(doc2.queryAll('div > u')).toEqual []
			expect(doc2.queryAll('div > b')).toEqual [doc2b]
			expect(doc2.queryAll('b > u')).toEqual [doc2u]

		it '[foo]', ->
			expect(doc2.queryAll('[attr]')).toEqual [doc2u, doc2div2]
			expect(doc2.queryAll('[color]')).toEqual [doc2u]
			expect(doc2.queryAll('[width]')).toEqual []

		it '[foo=bar]', ->
			expect(doc2.queryAll('[attr=2]')).toEqual [doc2div2]
			expect(doc2.queryAll('[attr="2"]')).toEqual [doc2div2]
			expect(doc2.queryAll('[attr=\'2\']')).toEqual [doc2div2]
			expect(doc2.queryAll('[attr=3]')).toEqual []

		it '[foo^=bar]', ->
			expect(doc2.queryAll('[color^=bl]')).toEqual [doc2u]
			expect(doc2.queryAll('[color^="b"]')).toEqual [doc2u]
			expect(doc2.queryAll('[color^=\'blue\']')).toEqual [doc2u]
			expect(doc2.queryAll('[color^=lue]')).toEqual []

		it '[foo$=bar]', ->
			expect(doc2.queryAll('[color$=ue]')).toEqual [doc2u]
			expect(doc2.queryAll('[color$="e"]')).toEqual [doc2u]
			expect(doc2.queryAll('[color$=\'blue\']')).toEqual [doc2u]
			expect(doc2.queryAll('[color$=blu]')).toEqual []

		it '[foo*=bar]', ->
			expect(doc2.queryAll('[color*=bl]')).toEqual [doc2u]
			expect(doc2.queryAll('[color*="lu"]')).toEqual [doc2u]
			expect(doc2.queryAll('[color*=\'blue\']')).toEqual [doc2u]
			expect(doc2.queryAll('[color*=bl][color*=lu]')).toEqual [doc2u]
			expect(doc2.queryAll('[color*=lue1]')).toEqual []

		it '.foo', ->
			expect(doc2.queryAll('.first')).toEqual [doc2b]
			expect(doc2.queryAll('.first.second')).toEqual [doc2b]
			expect(doc2.queryAll('.first.second.third')).toEqual []

		it 'E.foo', ->
			expect(doc2.queryAll('b.first')).toEqual [doc2b]
			expect(doc2.queryAll('b.first.second')).toEqual [doc2b]
			expect(doc2.queryAll('b.first.second.third')).toEqual []

		it '*', ->
			expect(doc2.queryAll('*')).toEqual [doc2div1, doc2b, doc2u, doc2u2, doc2div2, doc2em1, doc2em2]

		it '*[foo]', ->
			expect(doc2.queryAll('*[color]')).toEqual [doc2u]

		it 'E > * > F[foo]', ->
			expect(doc2.queryAll('div > * > u[color]')).toEqual [doc2u]

		it 'E > * > F[foo], F[foo]', ->
			expect(doc2.queryAll('div > * > u[color], div[attr]')).toEqual [doc2u, doc2div2]
			expect(doc2.queryAll('div > * > u[color],div[attr]')).toEqual [doc2u, doc2div2]

		it 'omits neft:blank', ->
			expect(doc2.queryAll('div > em')).toEqual [doc2em1, doc2em2]

	describe 'query() works with selector', ->
		doc2 = Element.fromHTML "<div><b><u color='blue' attr='1'></u></b></div><div attr='2'><neft:blank><em></em></neft:blank></div>"
		doc2div1 = doc2.children[0]
		doc2b = doc2div1.children[0]
		doc2u = doc2b.children[0]
		doc2div2 = doc2.children[1]
		doc2em = doc2div2.children[0].children[0]

		it 'E', ->
			expect(doc2.query('div')).toBe doc2div1
			expect(doc2.query('u')).toBe doc2u

		it '[foo]', ->
			expect(doc2.query('[attr]')).toBe doc2u
			expect(doc2.query('[color]')).toBe doc2u
			expect(doc2.query('[width]')).toBe null

		it 'omits neft:blank', ->
			expect(doc2.query('div > em')).toBe doc2em

	describe 'queryParents() works with selector', ->
		doc2 = Element.fromHTML "<div><b><u color='blue' attr='1'></u></b></div><div attr='2'><neft:blank><em></em></neft:blank></div>"
		doc2div1 = doc2.children[0]
		doc2b = doc2div1.children[0]
		doc2u = doc2b.children[0]
		doc2div2 = doc2.children[1]
		doc2em = doc2div2.children[0].children[0]

		it 'E', ->
			expect(doc2u.queryParents('div')).toBe doc2div1
			expect(doc2b.queryParents('div')).toBe doc2div1

		it 'E > F', ->
			expect(doc2u.queryParents('div > b')).toBe doc2div1
			expect(doc2u.queryParents('div > b >')).toBe doc2div1

	describe 'watch()', ->
		tags = doc2 = doc2div1 = doc2b = doc2u = doc2u2 = doc2div2 = doc2em1 = doc2em2 = null

		beforeEach ->
			tags = []
			doc2 = Element.fromHTML "<div><b><u color='blue' attr='1'><u></u></u></b></div><div attr='2'><neft:blank><em></em></neft:blank><em></em></div>"
			doc2div1 = doc2.children[0]
			doc2b = doc2div1.children[0]
			doc2u = doc2b.children[0]
			doc2u2 = doc2b.children[0].children[0]
			doc2div2 = doc2.children[1]
			doc2em1 = doc2div2.children[0].children[0]
			doc2em2 = doc2div2.children[1]

		it 'is a function', ->
			expect(doc2.watch).toEqual jasmine.any Function

		describe 'works with selector', ->
			it 'E', ->
				doc2b.parent = null
				watcher = doc2.watch 'b'
				watcher.onAdd (tag) ->
					tags.push tag
				doc2b.parent = doc2div1
				expect(tags).toEqual [doc2b]

			it 'E F', ->
				doc2u.parent = null
				watcher = doc2.watch 'b u'
				watcher.onAdd (tag) ->
					tags.push tag
				doc2u.parent = doc2b
				expect(tags).toEqual [doc2u, doc2u2]

			it 'E > F', ->
				doc2u.parent = null
				watcher = doc2div1.watch '> u'
				watcher.onAdd (tag) ->
					tags.push tag
				doc2u.parent = doc2div1
				expect(tags).toEqual [doc2u]

			it '[foo]', ->
				watcher = doc2div1.watch '[attr2]'
				watcher.onAdd (tag) ->
					tags.push tag
				watcher.onRemove (tag) ->
					utils.remove tags, tag
				doc2u.attrs.set 'attr2', '2'
				expect(tags).toEqual [doc2u]
				doc2u.attrs.set 'attr2', undefined
				expect(tags).toEqual []

			it '[foo=bar]', ->
				watcher = doc2div1.watch '[attr=2]'
				watcher.onAdd (tag) ->
					tags.push tag
				watcher.onRemove (tag) ->
					utils.remove tags, tag
				doc2u.attrs.set 'attr', '2'
				expect(tags).toEqual [doc2u]
				doc2u.attrs.set 'attr', '1'
				expect(tags).toEqual []

			it '[foo^=bar]', ->
				watcher = doc2div1.watch '[color^=re]'
				watcher.onAdd (tag) ->
					tags.push tag
				watcher.onRemove (tag) ->
					utils.remove tags, tag
				doc2u.attrs.set 'color', 'red'
				expect(tags).toEqual [doc2u]
				doc2u.attrs.set 'color', 'blue'
				expect(tags).toEqual []

			it '[foo$=bar]', ->
				watcher = doc2div1.watch '[color$=ed]'
				watcher.onAdd (tag) ->
					tags.push tag
				watcher.onRemove (tag) ->
					utils.remove tags, tag
				doc2u.attrs.set 'color', 'red'
				expect(tags).toEqual [doc2u]
				doc2u.attrs.set 'color', 'blue'
				expect(tags).toEqual []

			it '[foo*=bar]', ->
				watcher = doc2div1.watch '[color*=rang]'
				watcher.onAdd (tag) ->
					tags.push tag
				watcher.onRemove (tag) ->
					utils.remove tags, tag
				doc2u.attrs.set 'color', 'orange'
				expect(tags).toEqual [doc2u]
				doc2u.attrs.set 'color', 'blue'
				expect(tags).toEqual []

			it '*', ->
				doc2u.parent = null
				watcher = doc2div1.watch '*'
				for node in watcher.nodes
					tags.push node
				watcher.onAdd (tag) ->
					tags.push tag
				watcher.onRemove (tag) ->
					utils.remove tags, tag
				doc2u.parent = doc2div1
				expect(tags).toEqual [doc2b, doc2u, doc2u2]
				doc2u.parent = null
				expect(tags).toEqual [doc2b]

			it '*[foo]', ->
				watcher = doc2div1.watch '*[attr2]'
				watcher.onAdd (tag) ->
					tags.push tag
				watcher.onRemove (tag) ->
					utils.remove tags, tag
				doc2u.attrs.set 'attr2', '2'
				expect(tags).toEqual [doc2u]
				doc2u.attrs.set 'attr2', undefined
				expect(tags).toEqual []

			it 'E > * > F[foo]', ->
				doc2u.parent = null
				watcher = doc2.watch 'div > * > u[color]'
				watcher.onAdd (tag) ->
					tags.push tag
				watcher.onRemove (tag) ->
					utils.remove tags, tag
				doc2u.parent = doc2b
				expect(tags).toEqual [doc2u]
				doc2u.parent = null
				expect(tags).toEqual []

			it 'E > * > F[foo], F[foo]', ->
				doc2div1.parent = null
				doc2div2.parent = null
				watcher = doc2.watch 'div > * > u[color], div[attr]'
				watcher.onAdd (tag) ->
					tags.push tag
				watcher.onRemove (tag) ->
					utils.remove tags, tag
				doc2div1.parent = doc2
				doc2div2.parent = doc2
				expect(tags).toEqual [doc2u, doc2div2]
				doc2div1.parent = null
				doc2div2.parent = null
				expect(tags).toEqual []

			it '&[foo]', ->
				doc2u.parent = null
				watcher = doc2u.watch '&[color]'
				for node in watcher.nodes
					tags.push node
				watcher.onAdd (tag) ->
					tags.push tag
				watcher.onRemove (tag) ->
					utils.remove tags, tag
				doc2u.parent = doc2b
				expect(tags).toEqual [doc2u]
				doc2u.attrs.set 'color', undefined
				expect(tags).toEqual []

	it 'visible property is editable', ->
		expect(p.visible).toBeTruthy()
		p.visible = false
		expect(p.visible).toBeFalsy()
		p.visible = true

	describe 'Observer', ->

		it 'observing attr changes works properly', ->

			value = args = null
			elem = Element.fromHTML('<b a="1"></b>').cloneDeep()
			tag = elem.children[0]

			tag.onAttrsChange (name, oldVal) ->
				value = @attrs.get name
				args = [@, arguments...]

			tag.attrs.set 'a', 2

			expect(args).toEqual [tag, 'a', '1']
			expect(value).toBe 2

		it 'observing visibility changes works properly', ->

			value = args = null
			elem = Element.fromHTML('<b></b>').cloneDeep()
			tag = elem.children[0]

			tag.onVisibleChange ->
				value = @visible
				args = [@, arguments...]

			tag.visible = false

			expect(args).toEqual [tag, true, undefined]
			expect(value).toBe false

		it 'observing text changes works properly', ->

			text = args = null
			elem = Element.fromHTML('<b>a</b>').cloneDeep()
			tag = elem.children[0].children[0]

			tag.onTextChange ->
				text = @text
				args = [@, arguments...]

			tag.text = 'b'

			expect(args).toEqual [tag, 'a', undefined]
			expect(text).toBe 'b'

		it 'observing parent changes works properly', ->

			value = args = null
			elem = Element.fromHTML('<a></a><b></b>').cloneDeep()
			tag1 = elem.children[0]
			tag2 = elem.children[1]

			tag2.onParentChange ->
				value = @parent
				args = [@, arguments...]

			tag2.parent = tag1

			expect(args).toEqual [tag2, elem, undefined]
			expect(value).toBe tag1

		it 'disconnect() works as expected', ->

			ok = true
			elem = Element.fromHTML('<b></b>').cloneDeep()
			tag = elem.children[0]

			listener = -> ok = false
			tag.onVisibleChange listener
			tag.onVisibleChange.disconnect listener

			tag.visible = false

			expect(ok).toBeTruthy()
