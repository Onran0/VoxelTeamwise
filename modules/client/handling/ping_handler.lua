local PACK_ID = require("constants").packId

local ping_handler = { }

function ping_handler:new(handler)
	local obj = { }

    self.__index = self
    setmetatable(obj, self)

    self.clientHandler = handler
    self.client = handler.client
    self.ping = -1
    self.pingTimer = 0

	return obj
end

function ping_handler:handle_ping(packet)
    if packet.fromClientToServer then
        self.ping = (time.uptime() - self.pingSentTime) * 1000
        self.pingSentTime = nil
    else
        self.client:add_to_send_queue(PACK_ID..":packet_ping", { fromClientToServer = false })
    end
end

function ping_handler:ping()
    if not self.pingSentTime and self.clientHandler.loggedIn then
        self.pingSentTime = time.uptime()
        self.client:add_to_send_queue(PACK_ID..":packet_ping", { fromClientToServer = true })
    end
end

function ping_handler:get_ping()
    return self.ping
end

function ping_handler:tick()
    if self.pingTimer <= 0 then
        self.pingTimer = 15
        self:ping()
    else self.pingTimer = self.pingTimer - 1 end
end

return ping_handler