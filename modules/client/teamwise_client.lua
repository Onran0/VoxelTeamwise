local constants = require "constants"

local PACK_ID = constants.packId

local client = require "packet_api:client"
local players_data = require "players_data"
local player_compat = require "content_compat/player_compat"

local teamwise_client = { }

function teamwise_client:log(...)
    print("[voxel teamwise client]", ...)
end

function teamwise_client:update()
	self.client:update()
	self.handler:update()
end

function teamwise_client:tick()
	self.handler:tick()
end

function teamwise_client:disconnect(cause)
    if self:is_connected() then
        self.client:add_to_send_queue(PACK_ID..":packet_disconnect")
        self.client:send_packets()
    end

	self.client:disconnect(cause)
    require("voxel_teamwise").close_client()
end

function teamwise_client:on_connected()
    self.client:add_to_send_queue(PACK_ID..":packet_handshake",
        {
            protocolVersion = constants.protocolVersion,
            nickname = self.settings.nickname
        }
    )
end

function teamwise_client:on_disconnected(cause)
    player_compat.remove_all()
	self:log("disconnected: "..cause)
end

function teamwise_client:is_connected()
	return self.client:can_send_packets()
end

function teamwise_client.save_connect_settings(address, settings)
    file.write(constants.internalDirectoryPath..constants.client.reconnectSettingsFile, json.tostring(
        {
            address = address,
            settings = settings
        }
    ))
end

function teamwise_client:start(address, settings)
    local obj = { }

    self.__index = self
    setmetatable(obj, self)

    self.playersData = players_data:new()

    self.address = address

    self.settings =
    {
        nickname = "Player-"..math.random(0, 999999),
        port = constants.defaultPort
    }

    if settings then
        for key, value in pairs(settings) do
            self.settings[key] = value
        end
    end

    self.client = client:connect(address, self.settings.port,
    	function(client, packetId, packetData)
    		self.handler:handle_packet(packetId, packetData)
    	end,
    	function(client, cause)
    		self:on_disconnected(cause)
    	end,
        function(client)
            self:on_connected()
        end
    )

    self.handler = client_handler:new(self)

    player.set_name(hud.get_player(), self.nickname)

    return obj
end

return teamwise_client