local buffer_ext = require "util/buffer_ext"

local packet_player_selected_item_changed = { }

function packet_player_selected_item_changed.write(data, buffer)
	buffer:put_uint16(data.clientId)
	buffer:put_uint16(data.itemId)
end

function packet_player_selected_item_changed.read(buffer)
	local data = { }

	data.clientId = buffer:get_uint16()
	data.itemId = buffer:get_uint16()

	return data
end

return packet_player_selected_item_changed