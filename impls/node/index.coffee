'use strict'

[utils, http] = ['utils', 'http'].map require

pending = {}

exports.Request = require('./request.coffee') pending
exports.Response = require('./response.coffee') pending

exports.init = ->

	# create server
	server = http.createServer()

	# start listening
	server.listen @port, @host

	# on request
	server.on 'request', (serverReq, serverRes) =>

		uid = utils.uid()

		# save in stack
		obj = pending[uid] =
			routing: @
			server: server
			res: @request
				uid: uid
				method: @constructor[serverReq.method]
				uri: serverReq.url.slice 1
				body: null
			serverReq: serverReq
			serverRes: serverRes

		# run immediately if needed
		unless obj.res.req.pending
			exports.Response.send.call obj.res