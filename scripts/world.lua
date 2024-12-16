local deffered_calls = require "util/deffered_calls"
local client_packets_handler = require "server/handling/client_packets_handler"
local teamwise_packets_registry = require "packets/teamwise_packets_registry"

local client, server

function on_block_placed(x, y, z, playerId)
	if client then client:on_block_placed(x, y, z, playerId) end
	if server then server:on_block_placed(x, y, z, playerId) end
end

function on_block_broken(x, y, z, playerId)
	if client then client:on_block_broken(x, y, z, playerId) end
	if server then server:on_block_broken(x, y, z, playerId) end
end

function on_world_open()
	teamwise_packets_registry.register_packets()
	client_packets_handler.add_base_handlers()

	events.on(
		PACK_ID..":server.started",
		function(newServer) server = newServer end
	)

	events.on(
		PACK_ID..":client.started",
		function(newClient) client = newClient end
	)

	events.on(
		PACK_ID..":server.closed",
		function() server = nil end
	)

	events.on(
		PACK_ID..":client.closed",
		function() client = nil end
	)
end

function on_world_tick()
	deffered_calls.process()
	if client then client:update() end
	if server then server:update() end
end