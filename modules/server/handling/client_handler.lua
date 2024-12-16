local player_compat = require "content_compat/player_compat"

local client_chunks_manager = require "server/handling/client_chunks_manager"
local client_packets_handler = require "server/handling/client_packets_handler"
local ping_handler = require "server/handling/ping_handler"

local teamwise_packets_registry = require "packets/teamwise_packets_registry"

local client_handler = { }

function client_handler:new(teamwiseServer, clientId)
	local obj = { }

    self.__index = self
    setmetatable(obj, self)

    self.teamwiseServer = teamwiseServer
    self.server = teamwiseServer.server
    self.clientId = clientId
    self.playersData = teamwiseServer.playersData
    self.commonDisconnect = false
    self.loggedIn = false
    self.chunksManager = client_chunks_manager:new(self)
    self.pingHandler = ping_handler:new(self)
    self.packetsHandler = client_packets_handler:new(self)

	return obj
end

function client_handler:get_ping()
    return self.pingHandler:get_ping()
end

function client_handler:update()
    self:pingHandler:update()
    self.chunksManager:update()
end

function client_handler:get_player_id()
    return player_compat.get_player_id(self.clientId)
end

function client_handler:get_nickname()
    return player.get_name(self:get_player_id())
end

function client_handler:on_disconnected(cause)
    player_compat.remove_player(self.clientId)

    self.server:send_packet_to_all(PACK_ID..":packet_player_leave",
        {
            clientId = self.clientId,
            isError = not self.commonDisconnect
        }
    )
end

function client_handler:kick(reason, byError)
    self.commonDisconnect = not byError
    self.server:send_packet(self.clientId, PACK_ID..":packet_kick", reason)
    self.server:close_connection(self.clientId, "kicked: "..reason)
end

function client_handler:send_packet_to_players_in_loaded_area(packetId, packetData, except)
    for _, clientId in ipairs(self.server:get_all_clients_ids()) do
        if not table.has(except, clientId) then
            local x, _, z = player.get_pos(self:get_player_id())

            if self.chunksManager:is_in_loaded_area(x, z) then
                self.server:send_packet(clientId, packetId, packetData)
            end
        end
    end
end

function client_handler:__add_properties_listener()

end

function client_handler.on_logged_in()
    self.teamwiseServer:log("client with id "..self.clientId.." successfully logged in as "..self:get_nickname())

    self:__add_properties_listener()
end

return client_handler