local buffer_ext = require "util/buffer_ext"

local packet_block_placed = { }

function packet_block_placed.write(data, buffer, isServer)
	if isServer then buffer:put_uint16(data.clientId) end

	buffer:put_uint16(data.blockId)
	buffer:put_uint16(data.states)
	buffer_ext.put_block_pos(buffer, data.position)
end

function packet_block_placed.read(buffer, isServer)
	local data = { }

	if not isServer then data.clientId = buffer:get_uint16() end

	data.blockId = buffer:get_uint16()
	data.states = buffer:get_uint16()
	data.position = buffer_ext.get_block_pos(buffer)

	return data
end

return packet_block_placed