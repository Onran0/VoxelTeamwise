local player_ext = require "player_ext"

local teamwise_server = require "server/teamwise_server"

local voxel_teamwise = { }

local client, server

local clientAndServerError = "client and server on the same voxel core instance are not supported"

function voxel_teamwise.get_client() return client end

function voxel_teamwise.get_server() return server end

function voxel_teamwise.close_server()
	if not server then error "server is not started" end

	server:close()
	events.emit(PACK_ID..":server.closed", server)
end

function voxel_teamwise.close_client()
	if not client then error "client is not started" end

	client:disconnect()
	events.emit(PACK_ID..":client.closed", clint)
end

function voxel_teamwise.start_server(settings)
	if server then error "server already started" end

	if client then error(clientAndServerError) end

	server = teamwise_server:start(settings)

	player_ext.set_clients_data(server.clientsData)

	events.emit(PACK_ID..":server.started", server)
end

function voxel_teamwise.start_client(address, port)
	if client then error "client already started" end

	if server then error(clientAndServerError) end

	error "W.I.P"

	events.emit(PACK_ID..":client.started", client)
end

return voxel_teamwise