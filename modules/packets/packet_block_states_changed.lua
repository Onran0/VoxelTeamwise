local buffer_ext = require "util/buffer_ext"

local packet_block_states_changed = { }

function packet_block_states_changed.write(data, buffer)
	buffer_ext.put_block_pos(buffer, data.position)
	buffer:put_uint16(data.states)
end

function packet_block_states_changed.read(buffer)
	local data = { }

	data.position = buffer_ext.get_block_pos(buffer)
	data.states = buffer:get_uint16()

	return data
end

return packet_block_states_changed