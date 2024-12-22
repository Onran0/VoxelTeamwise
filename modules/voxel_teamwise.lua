local PACK_ID = require("constants").packId

local player_compat = require "content_compat/player_compat"
local block_compat = require "content_compat/block_compat"

local teamwise_server = require "server/teamwise_server"
local teamwise_client = require "client/teamwise_client"

local voxel_teamwise = { }

local client, server

local clientAndServerError = "client and server on the same voxel core instance are not supported"

function voxel_teamwise.get_client() return client end

function voxel_teamwise.get_server() return server end

function voxel_teamwise.close_server()
	if not server then error "server is not started" end

	server:close_server()

	local status, result = pcall(events.emit, PACK_ID..":server.closed", server)

	if not status then print(result) end

	sever = nil
end

function voxel_teamwise.close_client()
	if not client then error "client is not started" end

	client:disconnect()

	local status, result = pcall(events.emit, PACK_ID..":client.closed", client)

	if not status then print(result) end

	client = nil
end

function voxel_teamwise.start_server(settings)
	if server then error "server already started" end

	if client then error(clientAndServerError) end

	server = teamwise_server:start(settings)

	player_compat.set_players_data(server.playersData)
	block_compat.set_callbacks(require("server/callbacks/blocks_callbacks"):new(server))

	events.emit(PACK_ID..":server.started", server)
end

function voxel_teamwise.start_client(address, settings)
	if client then error "client already started" end

	if server then error(clientAndServerError) end

	client = teamwise_client:start(address, settings)

	player_compat.set_players_data(client.playersData)
	block_compat.set_callbacks(require("client/callbacks/blocks_callbacks"):new(client))

	events.emit(PACK_ID..":client.started", client)
end

function voxel_teamwise.close_client_or_server()
	if client then
		voxel_teamwise.close_client()
	elseif server then
		voxel_teamwise.close_server()
	end
end

return voxel_teamwise