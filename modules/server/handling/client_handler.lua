local player_compat = require "content_compat/player_compat"

local client_chunks_manager = require "server/handling/client_chunks_manager"
local login_handler = require "server/handling/login_handler"
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
    self.packetsHandler = require("server/handling/client_packets_handler"):new(self)
    self.loginHandler = login_handler:new(self)

	return obj
end

function client_handler:get_ping()
    return self.pingHandler:get_ping()
end

function client_handler:tick()
    self.server:send_packet(self.clientId, PACK_ID..":packet_world_time", world.get_day_time())

    self.pingHandler:tick()

    local pid = self:get_player_id()

    local pos, rot = player.get_pos(pid), player.get_rot(pid)

    if
        pos ~= self.prevPos or
        rot ~= self.prevRot
    then
        self:send_packet_to_players_in_loaded_area(PACK_ID..":packet_player_transform",
            {
                clientId = self.clientId,
                position = pos ~= self.prevPos and pos,
                rotation = rot ~= self.prevRot and rot
            }
        )

        self.prevPos = pos
        self.prevRot = rot
    end
end

function client_handler:update()
    self.chunksManager:update()
end

function client_handler:get_player_id()
    if not self.playerId then
        self.playerId = player_compat.get_player_id(self.clientId)
    end
    
    return self.playerId
end

function client_handler:get_nickname()
    return player.get_name(self:get_player_id())
end

function client_handler:on_disconnected(cause)
    if self.loggedIn then
        player_compat.remove_player(self:get_player_id())

        self.server:send_packet_to_all(PACK_ID..":packet_player_leave",
            {
                clientId = self.clientId,
                dueToError = not self.commonDisconnect
            }
        )

        self.teamwiseServer:log(
            "player '"..self:get_nickname().."' disconnected from the server"..
            (not self.commonDisconnect and " due to error" or '')
        )
    end
end

function client_handler:kick(reason, byError)
    self.commonDisconnect = not byError
    self.server:send_packet(self.clientId, PACK_ID..":packet_kick", reason)
    self.server:close_connection(self.clientId, "kicked: "..reason)
end

function client_handler:send_packet_to_players_in_loaded_area(packetId, packetData, except, includeSelf)
    if not includeSelf then table.insert(except, self.clientId) end

    for _, clientId in ipairs(self.server:get_all_clients_ids()) do
        if not table.has(except, clientId) then
            local x, _, z = player.get_pos(player_compat.get_player_id(clientId))

            if self.chunksManager:is_in_loaded_area(x, z) then
                self.server:send_packet(clientId, packetId, packetData)
            end
        end
    end
end

function client_handler.on_logged_in()
    local nickname = self:get_nickname()

    self.teamwiseServer:log(
        '['..self.server:get_client_address(self.clientId).."] '"..nickname..
        "' successfully joined the game and was spawned at coordinates { "..position[1]..
        ', '..position[2]..', '..position[3]..' }'
    )

    self.playersData:add_property_listener(nickname, "position",
        function(position)
            self.server:send_packet(self.clientId, PACK_ID..":packet_player_transform",
                {
                    clientId = self.clientId,
                    position = position
                }
            )
        end
    )

    self.playersData:add_property_listener(nickname, "rotation",
        function(rotation)
            self.server:send_packet(self.clientId, PACK_ID..":packet_player_transform",
                {
                    clientId = self.clientId,
                    rotation = rotation
                }
            )
        end
    )
end

return client_handler