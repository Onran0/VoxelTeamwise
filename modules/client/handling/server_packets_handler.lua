local constants = require "constants"

local PACK_ID = constants.packId

local server_packets_handler = { }

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