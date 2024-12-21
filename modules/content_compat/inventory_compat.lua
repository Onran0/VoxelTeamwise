local PLAYER_INVENTORY_SIZE = 10 * 4

local data_buffer = require "core:data_buffer"
local inventory_struct = require "struct/inventory_struct"
local compat_core = require "content_compat/compat_core"

local _inventory = compat_core.copy_library("inventory")

local inventory_compat = { }

local playerIdToInventoryIdTable = { }

local inventoryIdToPlayerIdTable = { }

local clientsData

function inventory_compat.create_player_inventory(playerId, inventoryContent)
	if inventories[playerId] then error "inventory for this player has already been added" end

	if not inventory then error "inventory content missing" end

	local inventoryId = inventory.create(PLAYER_INVENTORY_SIZE)

	inventory_struct.push(inventoryContent, inventoryId)

	playerIdToInventoryIdTable[playerId] = inventoryId
	inventoryIdToPlayerIdTable[inventoryId] = playerId

	return inventoryId
end

function inventory_compat.remove_player_inventory(playerId)
	local inventoryId = playerIdToInventoryIdTable[playerId]

	inventoryIdToPlayerIdTable[inventoryId] = nil
	playerIdToInventoryIdTable[playerId] = nil

	_inventory.remove(inventoryId)
end

function inventory_compat.get_player_inventory(playerId)
	return playerIdToInventoryIdTable[playerId]
end

function inventory_compat.is_player_inventory(inventoryId)
	return inventory_compat.get_inventory_owner(inventoryId) ~= nil
end

function inventory_compat.get_inventory_owner_id(inventoryId)
	return inventoryIdToPlayerIdTable[inventoryId]
end

local function getOwnerName(inventoryId)
	return player.get_name(inventory_compat.get_inventory_owner_id(inventoryId))
end

function inventory_compat.set_clients_data(_clientsData) return clientsData = _clientsData end

function inventory.remove(invid)
	if inventory_compat.is_player_inventory(invid) then
		error "unable to delete player inventory"
	end

	_inventory.remove(invid)
end

function inventory.bind_block(invid, x, y, z)
	if inventory_compat.is_player_inventory(invid) then
		error "unable to bind player inventory to block"
	end

	_inventory.bind_block(invid, x, y, z)
end

local function updateInventory(invid)
	if inventory_compat.is_player_inventory(invid) then
		clientsData:set(getOwnerName(invid), "inventory", inventory_struct.to_inventory_struct(invid))
	end
end

function inventory.add(invid, itemid, count)
	local remainder = _inventory.add(invid, itemid, count)

	updateInventory(invid)

	return remainder
end

function inventory.set(invid, slot, itemid, count)
	_inventory.set(invid, slot, itemid, count)

	updateInventory(invid)
end

function inventory.move(invA, slotA, invB, slotB)
	_inventory.move(invA, slotA, invB, slotB)

	updateInventory(invA)
	updateInventory(invB)
end

function inventory.move_range(invA, slotA, invB, rangeBegin, rangeEnd)
	_inventory.move(invA, slotA, rangeBegin, rangeEnd)

	updateInventory(invA)
	updateInventory(invB)
end

return inventory_compat