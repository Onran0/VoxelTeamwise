local buffer_ext = require "util/buffer_ext"

local packet_block_states_updated = { }

function packet_block_states_updated.write(data, buffer)
	buffer:put_uint16(data.states)
	buffer_ext.put_block_pos(buffer, data.position)
end

function packet_block_states_updated.read(buffer)
	local data = { }

	data.states = buffer:get_uint16()
	data.position = buffer_ext.get_block_pos(buffer)

	return data
end

return packet_block_states_updated