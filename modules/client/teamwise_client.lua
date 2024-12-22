local PACK_ID = require("constants").packId

local constants = require "constants"
local client = require "packet_api:client"
local players_data = require "players_data"

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
	self.client:disconnect(cause)
end

function teamwise_client:on_disconnected(cause)
	self.handler:on_disconnected(cause)
end

function teamwise_client:is_connected()
	return self.client:can_send_packets()
end

function teamwise_client:start(address, settings)
    local obj = { }

    self.__index = self
    setmetatable(obj, self)

    self.playersData = players_data:new()

    self.settings =
    {
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
    	function(cause)
    		self:on_disconnected(cause)
    	end
    )

    self.handler = client_handler:new(self)

    return obj
end

return teamwise_client