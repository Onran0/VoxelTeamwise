local buffer_ext = require "util/buffer_ext"

local packet_player_selected_slot_changed = { }

function packet_player_selected_slot_changed.write(slot, buffer)
	buffer:put_byte(slot)
end

function packet_player_selected_slot_changed.read(buffer)
	return buffer:get_byte()
end

return packet_player_selected_slot_changed