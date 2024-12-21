local client_packets_handler = { }

local PACK_ID = "voxel_teamwise"

local allowedPacketsBeforeLogin =
{
	PACK_ID..":packet_handshake",
    PACK_ID..":packet_content_info",
	PACK_ID..":packet_ping"
}

local constants = require "constants"

local player_compat = require "content_compat/player_compat"

local chunk_util = require "util/chunk_util"

local teamwise_packets_registry = require "packets/teamwise_packets_registry"

function client_packets_handler:new(handler)
	local obj = { }

    self.__index = self
    setmetatable(obj, self)

    self.clientHandler = handler
    self.teamwiseServer = handler.teamwiseServer
    self.server = handler.server
    self.clientId = handler.clientId
    self.playersData = handler.playersData
    self.commonDisconnect = false
    self.chunksManager = handler.chunksManager
    self.loginHandler = handler.loginHandler

	return obj
end

function client_packets_handler:check_packet_for_validity(packetId, packet)
    if not self.clientHandler.loggedIn and not table.has(allowedPacketsBeforeLogin, packetId) then
        return false, "sending packets before logging in"
    else return true end
end

function client_packets_handler:handle_packet_ping(packet) self.clientHandler.pingHandler:handle_ping(packet) end

function client_packets_handler:handle_packet_handshake(packet)
    self.loginHandler:handle_handshake(packet)
end

function client_packets_handler:handle_packet_content_info(packet)
    self.loginHandler:handle_content_info(packet)
end

function client_packets_handler:handle_packet_disconnect()
    self.clientHandler.commonDisconnect = true
    self.server:close_connection(self.clientId, "client disconnected")
end

function client_packets_handler:handle_packet_chat(message)
	self.server:send_packet_to_all(
        PACK_ID..":packet_chat",
        '['..self.teamwiseServer:get_nickname(self.clientId)..'] '..message
    )
end

function client_packets_handler:handle_packet_block_states_updated(packet)
	chunk_util.load_chunk(unpack(self.chunksManager.currentChunk))

    block.set_states(packet.position[1], packet.position[2], packet.position[3], packet.states)

    chunk_util.unload_chunk()
    
    self.clientHandler:send_packet_to_players_in_loaded_area(PACK_ID..":packet_block_states_update", packet)
end

function client_packets_handler:handle_packet_block_changed_by_player(packet)
    local x, y, z = packet.position[1], packet.position[2], packet.position[3]

    chunk_util.load_chunk(unpack(self.chunksManager.currentChunk))

    if packet.blockId == 0 then
        block.destruct(x, y, z, self.clientHandler:get_player_id())
    else
        block.place(x, y, z, packet.blockId, packet.states, self.clientHandler:get_player_id())
    end

    chunk_util.unload_chunk()
end

function client_packets_handler:handle_packet_player_transform(packet)
    if packet.position then
        player.set_pos(self.clientHandler:get_player_id(), unpack(packet.position))
    end

    if packet.rotation then
        player.set_rot(self.clientHandler:get_player_id(), unpack(packet.rotation))
    end
end

function client_packets_handler:handle_packet_selected_slot_changed(slot)
    local pid = self.clientHandler:get_player_id()

    player_compat.set_selected_slot(pid, slot)

    self.server:send_packet_to_all(PACK_ID..":packet_player_selected_item_changed",
        {
            clientId = self.clientId,
            itemId = player_compat.get_selected_item_id(pid)
        }
    )
end

function client_packets_handler.add_handler(packetId, handler)
	client_packets_handler.handlers[packetId] = handler
end

function client_packets_handler.add_base_handlers()
	local handlers = { }

	for _, packetName in ipairs(teamwise_packets_registry.get_packets()) do
	    handlers[PACK_ID..":"..packetName] = client_packets_handler["handle_"..packetName]
	end

	client_packets_handler.handlers = handlers
end

return client_packets_handler