'use strict'

[utils, http] = ['utils', 'http'].map require
expect = require 'expect'

pending = {}

module.exports = (Routing) ->

	Request: require('./request') Routing, pending
	Response: require('./response') Routing, pending

	init: (routing) ->
		expect(routing).toBe.any Routing

		# create server
		server = http.createServer()

		# start listening
		server.listen routing.port, routing.host

		# on request
		server.on 'request', (serverReq, serverRes) ->

			uid = utils.uid()

			# save in the stack
			obj = pending[uid] =
				routing: routing
				server: server
				req: null
				serverReq: serverReq
				serverRes: serverRes

			type = serverReq.headers['x-expected-type']
			type ||= Routing.Request.VIEW_TYPE

			obj.req = routing.createRequest
				uid: uid
				method: Routing.Request[serverReq.method]
				url: serverReq.url.slice 1
				data: undefined
				type: type

	sendRequest: ->
		throw "Not implemented!"