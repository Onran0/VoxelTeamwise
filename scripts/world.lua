local compat_core,
	  player_compat,
	  inventory_compat,
	  block_compat
	  =
	  require "content_compat/compat_core",
	  require "content_compat/player_compat",
	  require "content_compat/inventory_compat",
	  require "content_compat/block_compat"

local deffered_calls = require "util/deffered_calls"
local client_packets_handler = require "server/handling/client_packets_handler"
local teamwise_packets_registry = require "packets/teamwise_packets_registry"

local client, server

local installedPacks

function on_world_open()
	installedPacks = packs.get_installed()

	for i = 1, #installedPacks do
		if installedPacks[i] == PACK_ID then
			table.remove(installedPacks, i)
			break
		end
	end

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
		function()
			server = nil
			core.close_world(true)
		end
	)

	events.on(
		PACK_ID..":client.closed",
		function()
			client = nil
			core.close_world(true)
		end
	)
end

function on_world_quit()
	compat_core.restore_all_libraries()
	voxel_teamwise.close_client_or_server()
end

function on_world_tick(tps)
	tps = tps or 20

	deffered_calls.process()
	
	if client then client:update() client:tick(tps) end
	if server then server:update() server:tick(tps) end

	local players = player_compat.get_players_list()

	for i = 1, #players do
		local playerId = players[i]

		for j = 1, #installedPacks do
			local status, error = pcall(events.emit, installedPacks[j]..":.playertick", playerId, tps)

			if not status then
				print(error)
			end
		end
	end
end