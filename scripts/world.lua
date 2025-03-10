local compat_core,
	  player_compat,
	  inventory_compat,
	  block_compat,
	  console_compat
	  =
	  require "content_compat/compat_core",
	  require "content_compat/player_compat",
	  require "content_compat/inventory_compat",
	  require "content_compat/block_compat",
	  require "content_compat/console_compat"

local constants = require "constants"

local deffered_calls = require "util/deffered_calls"
local client_packets_handler = require "server/handling/client_packets_handler"
local teamwise_packets_registry = require "packets/teamwise_packets_registry"
local voxel_teamwise = require "voxel_teamwise"

local client, server

local installedPacks

function on_world_open()
	installedPacks = pack.get_installed()

	table.remove(installedPacks, table.index(installedPacks, PACK_ID))

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

	if not file.exists(constants.internalDirectoryPath) then
		file.mkdirs(constants.internalDirectoryPath)
	else
		local reconnectSettingsPath = constants.internalDirectoryPath..constants.client.reconnectSettingsFiles

		if file.exists(reconnectSettingsPath) then
			local reconnectSettings = json.parse(file.read(reconnectSettingsPath))

			file.remove(reconnectSettingsPath)

			voxel_teamwise.start_client(reconnectSettings.address, reconnectSettings.settings)
		end
	end
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