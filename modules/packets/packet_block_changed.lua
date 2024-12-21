local buffer_ext = require "util/buffer_ext"

local packet_block_changed = { }

function packet_block_changed.write(data, buffer, isServer)
	buffer_ext.put_block_pos(buffer, data.position)
	buffer:put_uint16(data.blockId)
	buffer:put_uint16(data.states)
end

function packet_block_changed.read(buffer, isServer)
	local data = { }

	data.position = buffer_ext.get_block_pos(buffer)
	data.blockId = buffer:get_uint16()
	data.states = buffer:get_uint16()

	return data
end

return packet_block_changed