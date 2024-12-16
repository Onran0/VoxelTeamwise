local client_packets_handler = { }

local PACK_ID = "voxel_teamwise"

local allowedPacketsBeforeLogin =
{
	PACK_ID..":packet_login",
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

	return obj
end

function client_packets_handler:check_packet_for_validity(packetId, packet)
    if not self.clientHandler.loggedIn and not table.has(allowedPacketsBeforeLogin, packetId) then
        return false, "sending packets before logging in"
    else return true end
end

function client_packets_handler:handle_packet_ping(packet) self.clientHandler.pingHandler:handle_ping(packet) end

function client_packets_handler:handle_packet_disconnect()
    self.clientHandler.commonDisconnect = true
    self.server:close_connection(self.clientId, "client disconnected")
end

function client_packets_handler:handle_packet_login(packet)
    if self.clientHandler.loggedIn then
        self.clientHandler:kick("already logged in")
    elseif packet.protocolVersion > constants.protocolVersion then
        self.clientHandler:kick("outdated server")
    elseif packet.protocolVersion < constants.protocolVersion then
        self.clientHandler:kick("outdated client")
    elseif self.teamwiseServer:get_client_id_by_nickname(packet.nickname) then
        self.clientHandler:kick("a client with that name is already logged in")
    else
        local address = server:get_client_address(self.clientId)

        if self.teamwiseServer:is_banned_name(packet.nickname) then
            self.clientHandler:kick("banned by name: "..self.teamwiseServer:get_ban_reason_by_name(packet.nickname))
        elseif self.teamwiseServer:is_banned_address(address) then
            self.clientHandler:kick("banned by address: "..self.teamwiseServer:get_ban_reason_by_address(address))
        elseif
            self.teamwiseServer.settings.whiteListEnabled and
            not self.teamwiseServer:is_name_in_white_list(packet.nickname) and
            not self.teamwiseServer:is_address_in_white_list(address)
        then
            self.clientHandler:kick("you are not on the whitelist")
        else
            self.clientHandler.loggedIn = true

            local nickname = packet.nickname

            local position = self.playersData:get(nickname, "position", self.teamwiseServer.globalData.defaultSpawnpoint)
            local rotation = self.playersData:get(nickname, "rotation", { 0, 0, 0 })
            local inventory = self.playersData:get(nickname, "inventory", { })

            player_compat.spawn_player(
                self.clientId,
                nickname,
                position,
                rotation,
                inventory,
                self.playersData:get(nickname, "spawnData")
            )

            local pid = self.clientHandler:get_player_id()

            for _, clientId in ipairs(self.server:get_all_clients_ids()) do
                self.server:send_packet(clientId, PACK_ID..":packet_player_joined",
                    {
                        clientId = self.clientId,
                        nickname = packet.nickname,
                        position = position,
                        rotation = rotation,
                        isSelf = self.clientId == clientId
                    }
                )
            end

            self.clientHandler:on_logged_in()
        end
    end
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

function client_packets_handler:handle_packet_block_placed(packet)
    local x, y, z = packet.position[1], packet.position[2], packet.position[3]

    chunk_util.load_chunk(unpack(self.chunksManager.currentChunk))

    if packet.blockId == 0 then
        block.destruct(x, y, z, self.clientHandler:get_player_id())
    else
        block.place(x, y, z, packet.blockId, packet.states, self.clientHandler:get_player_id())
    end

    chunk_util.unload_chunk()
    
    self.clientHandler:send_packet_to_players_in_loaded_area(PACK_ID..":packet_block_changed",
        {
            clientId = self.clientId,
            blockId = packet.blockId,
            states = packet.states,
            position = packet.position
        }
    )
end

function client_packets_handler:handle_packet_player_transform(packet)
    player_compat.set_enabled_emit(false)

    if packet.position then
        player.set_pos(self.clientHandler:get_player_id(), unpack(packet.position))
    end

    if packet.rotation then
        player.set_rot(self.clientHandler:get_player_id(), unpack(packet.rotation))
    end

    player_compat.set_enabled_emit(true)

    self.clientHandler:send_packet_to_players_in_loaded_area(
        PACK_ID..":packet_player_transform",
        packet,
        { self.clientId }
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