'use strict'

module.exports = (impl) ->
	{Types} = impl
	{Grid} = Types

	create: (id, target) ->
		Grid.create id, target

		target.type = 'Grid'
		target.columns = 1

	getColumnSpacing: impl.getGridRowSpacing

	setColumnSpacing: impl.setGridRowSpacing