local constants = require "constants"

local PACK_ID = constants.packId

local tables_util = require "util/tables_util"
local content = require "util/content"
local teamwise_packets_registry = require "packets/teamwise_packets_registry"
local block = require("content_compat/compat_core").get_original("block")
local player_compat = require "content_compat/player_compat"
local inventory_compat = require "content_compat/inventory_compat"
local inventory_struct = require "util/inventory_struct"

local server_packets_handler = { }

function server_packets_handler:new(handler)
	local obj = { }

    self.__index = self
    setmetatable(obj, self)

    self.clientHandler = handler
    self.teamwiseClient = handler.teamwiseClient
    self.client = handler.client
    self.playersData = handler.playersData

	return obj
end

function server_packets_handler:handle_packet_identified(clientId)
	self.clientHandler.clientId = clientId
	self.clientId = clientId
	self.teamwiseClient.clientId = clientId

	self.client:add_to_send_queue(PACK_ID..":packet_content_info", content.get_content_info())
end

function server_packets_handler:handle_packet_incompatible_content(packsList)
	self.teamwiseClient:disconnect("incompatible content")

	for i = 1, #packsList do
		local incompatiblePack = packsList[i]

		local str

		if incompatiblePack.missingOnClient then
			str = "pack '"..incompatiblePack.id.."' missing on client"
		elseif incompatiblePack.missingOnServer then
			str = "pack '"..incompatiblePack.id.."' missing on server"
		else
			str = "different pack '"..incompatiblePack.id.."' version. client: '"..
			pack.get_info(incompatiblePack.id).version.."', server: '"..incompatiblePack.version.."'"
		end

		self.teamwiseClient:log(str)
	end
end

function server_packets_handler:handle_packet_indices_sync(serverIndices)
	if tables_util.equals(content.get_indices_table(), serverIndices) then
		self.clientHandler.loggedIn = true
		self.client:add_to_send_queue(PACK_ID..":packet_indices_synced")
		self.clientHandler:on_logged_in()
	else
		self.teamwiseClient:disconnect("different indices")
		self.clientHandler:synchronize_indices(serverIndices)
	end
end

function server_packets_handler:handle_packet_ping(packet) self.clientHandler.pingHandler:handle_ping(packet) end

function server_packets_handler:handle_packet_kick(reason)
	self.clientHandler.commonDisconnect = true
	self.teamwiseClient:log("kicked out for the reason:"..reason)
	self.teamwiseClient:disconnect("kicked out for the reason: "..reason)
end

function server_packets_handler:handle_packet_player_joined(packet)
	if packet.clientId == self.clientId then
		local pid = self.clientHandler:get_player_id()

		player_compat.set_local_player_client_id(clientId)
		inventory_compat.set_local_player_id(pid)

		player.set_pos(pid, unpack(packet.position))
		player.set_rot(pid, unpack(packet.rotation))
	else
		local pid = player_compat.spawn_player(packet.clientId, packet.nickname, packet.position, packet.rotation, { })

		player_compat.set_selected_item_id(pid, packet.selectedItemId)

		console.log(name.." joined the game")
	end
end

function server_packets_handler:handle_packet_player_leave(packet)
	local pid = player_compat.get_player_id(packet.clientId)

	local name = player.get_name(pid)

	console.log(name.." left the game"..(packet.dueToError and " due to error" or ''))

	player_compat.remove_player(pid)

	self.playersData:on_disconnected(name)
end

function server_packets_handler:handle_packet_player_selected_item_changed(packet)
	player_compat.set_selected_item_id(player_compat.get_player_id(packet.clientId), packet.itemId)
end

function server_packets_handler:handle_packet_player_transform(packet)
	local pid = player_compat.get_player_id(packet.clientId)

	if packet.position then player.set_pos(pid, unpack(packet.position)) end
	if packet.rotation then player.set_rot(pid, unpack(packet.rotation)) end
end

function server_packets_handler:handle_packet_chat(message)
	console.log(message)
end

function server_packets_handler:handle_packet_player_inventory_changed(changedSlots)
	local pid = self.clientHandler:get_player_id()

	inventory_struct.push(changedSlots, player.get_inventory(pid))

	self.clientHandler.oldInventory = self.playersData:get(player.get_name(pid), "inventory")
end

function server_packets_handler:handle_packet_world_time(time)
	world.set_day_time(time)
end

function server_packets_handler:handle_packet_chunk(packet)
	local x, z = unpack(packet.position)

	world.set_chunk_data(
		x, z,
		packet.chunkData,
		true
	)
end

function server_packets_handler:handle_packet_block_changed(packet)
	local x, y, z = unpack(packet.position)

	block.set(x, y, z, packet.blockId, packet.states)
end

function server_packets_handler:handle_packet_block_changed_by_player(packet)
	local x, y, z = unpack(packet.position)

	block.place(x, y, z, packet.blockId, packet.states, player_compat.get_player_id(packet.clientId))
end

function server_packets_handler:handle_packet_block_states_changed(packet)
	local x, y, z = unpack(packet.position)

	block.set_states(x, y, z, packet.states)
end

function server_packets_handler:handle_packet_block_rotation_changed(packet)
	local x, y, z = unpack(packet.position)

	block.set_rotation(x, y, z, packet.rotation)
end

function server_packets_handler:handle_packet_block_field_changed(packet)
	local x, y, z = unpack(packet.position)

	block.set_field(x, y, z, packet.name, packet.value, packet.index)
end

function server_packets_handler.add_handler(packetId, handler)
	server_packets_handler.handlers[packetId] = handler
end

function server_packets_handler.add_base_handlers()
	local handlers = { }

	for _, packetName in ipairs(teamwise_packets_registry.get_packets()) do
	    handlers[PACK_ID..":"..packetName] = server_packets_handler["handle_"..packetName]
	end

	server_packets_handler.handlers = handlers
end

return server_packets_handler