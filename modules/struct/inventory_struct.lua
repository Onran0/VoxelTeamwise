local inventory_struct = { }

function inventory_struct.serialize(inventoryId, buffer)
	local slots = { }

	for i = 1, inventory.size(inventoryId) do
		table.insert(slots, i - 1)
	end

	inventory_struct.serialize_selected_slots(inventoryId, slots, buffer)
end

function inventory_struct.serialize_selected_slots(inventoryId, selectedSlots, buffer)
	buffer:put_uint16(#selectedSlots)

	for i = 1, #selectedSlots do
		buffer:put_uint16(selectedSlots[i])

		local item, count = inventory.get(inventoryId, selectedSlots[i])

		buffer:put_uint16(item)
		buffer:put_byte(count)
	end
end

function inventory_struct.deserialize(buffer)
	local slots = { }

	for i = 1, buffer:get_uint16() do
		local slotId = buffer:get_uint16()
		local item = buffer:get_uint16()
		local count = buffer:get_byte()

		slots[slotId] =
		{
			item = item,
			count = count
		}
	end

	return slots
end

function inventory_struct.to_inventory_struct(invid)
	local slots = { }

	for i = 1, inventory.size(invid) do
		local slotId = i - 1
		local item, count = inventory.get(invid, slotId)

		slots[slotId] =
		{
			item = item,
			count = count
		}
	end

	return slots
end

function inventory_struct.push(slots, inventoryId)
	for index, slot in pairs(slots) do
		inventory.set(inventoryId, index, slot.item, slot.count)
	end
end

function inventory_struct.deserialize_and_push(buffer, inventoryId)
	local slots = inventory_struct.deserialize(buffer)

	inventory_struct.push(slots, inventoryId)

	return slots
end

function inventory_struct.get_changed_slots(oldInventory, newInventory)
    local changedSlots = { }

    for slotId, slotData in pairs(newInventory) do
         local oldSlotData = oldInventory[slotId]

         if not oldSlotData or oldSlotData.item ~= slotData.item or oldSlotData.count ~= slotData.count then
            table.insert(changedSlots, slotId)
        end
    end

    return changedSlots
end

return inventory_struct