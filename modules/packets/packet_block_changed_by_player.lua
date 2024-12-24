local buffer_ext = require "util/buffer_ext"

local packet_block_changed_by_player = { }

function packet_block_changed_by_player.write(data, buffer, isServer)
	if isServer then buffer:put_uint16(data.clientId) end
	buffer_ext.put_block_pos(buffer, data.position)
	buffer:put_uint16(data.blockId)
	buffer:put_uint16(data.states)
end

function packet_block_changed_by_player.read(buffer, isServer)
	local data = { }

	if not isServer then data.clientId = buffer:get_uint16() end
	data.position = buffer_ext.get_block_pos(buffer)
	data.blockId = buffer:get_uint16()
	data.states = buffer:get_uint16()

	return data
end

return packet_block_changed_by_player