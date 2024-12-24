local inventory_struct = require "struct/inventory_struct"

local packet_player_inventory_changed = { }

function packet_player_inventory_changed.write(data, buffer)
	if not data.changedSlots then
		inventory_struct.serialize(data.inventoryId, buffer)
	else
		inventory_struct.serialize_selected_slots(data.inventoryId, data.changedSlots, buffer)
	end
end

function packet_player_inventory_changed.read(buffer)
	return inventory_struct.deserialize(buffer)
end

return packet_player_inventory_changed