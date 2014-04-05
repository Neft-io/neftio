'use strict'

###
TODO:
	- Db: default database
	- DbAddonsSchema: do not require `created` and `updated` in schema
	- DbAddons: parse timestamps into Date
###

[utils] = ['utils'].map require
[Schema, Routing, View] = ['schema', 'routing', 'view'].map require
[Db, _, _, _] = ['db', 'db-implementation', 'db-schema', 'db-addons'].map require
[_, _, _, _, _, AppModel] = ['model', 'model-db', 'model-client', 'model-linkeddata',
                             'model-view', './model.coffee'].map require

Db = Db.Impl()

`//<development>`
require('db/log.coffee') Db
`//</development>`

App =
	config:
		name: 'Sample TODO App'
	routing: new Routing
		protocol: 'http'
		port: 3000
		host: 'localhost'
		language: 'en'
	Schema: Schema
	Model: null
	Db: Db
	View: View

App.Model = AppModel App

# load views
views = require './build/views.coffee'
View.fromJSON path, json for path, json of views

# load models
models = require './build/models.coffee'
model App for name, model of models