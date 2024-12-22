local server_packets_handler = require "client/handling/server_packets_handler"

local client_handler = { }

function client_handler:new(client)
    local obj = { }

    self.__index = self
    setmetatable(obj, self)

    self.teamwiseClient = client
    self.client = teamwiseClient.client
    self.packetsHandler = server_packets_handler:new(self)

    return obj
end

function client_handler:handle_packet(packetId, packetData)
    if server_packets_handler.handlers[packetId] then
        server_packets_handler.handlers[packetId](packetData)
    end
end

function client_handler:update()
	
end

function client_handler:tick()
	
end

return client_handler