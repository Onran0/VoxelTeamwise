local buffer_ext = require "util/buffer_ext"

local packet_block_rotation_changed = { }

function packet_block_rotation_changed.write(data, buffer)
	buffer_ext.put_block_pos(buffer, data.position)
	buffer:put_byte(data.rotation)
end

function packet_block_rotation_changed.read(buffer)
	local data = { }

	data.position = buffer_ext.get_block_pos(buffer)
	data.rotation = buffer:get_byte()

	return data
end

return packet_block_rotation_changed