local compat_core = require "content_compat/compat_core"
local inventory_compat = require "content_compat/inventory_compat"
local math_util = require "util/math_util"

local MAX_BLOCK_TOUCH_DISTANCE = 16

local _player = compat_core.copy_library("player")

local player_compat = { }

local runtimePlayersData = { }

local playersList = { }

local cidToPid = { }
local pidToCid = { }

local localPlayerCid

local playersData

function player_compat.spawn_player(clientId, name, position, rotation, inventory)
	local entity =
	entities.spawn(
		PACK_ID..":player",
		position,
		{ [PACK_ID.."__player_animator"] = { clientId } }
	)

	entity.transform:set_rot(math_util.rotation_matrix(rotation))

	return player_compat.add_player(clientId, entity:get_uid(), name, inventory)
end

function player_compat.add_player(clientId, entityId, name, inventory)
	if not entityId then error "player without entity" end

	local pid = clientId + 0x02

	cidToPid[clientId] = pid
	pidToCid[pid] = clientId

	runtimePlayersData[pid] =
	{
		entityId = entityId,
		inventoryId = inventory_compat.create_player_inventory(pid, inventory),
		name = name
	}

	table.insert(playersList, pid)

	return pid
end

function player_compat.remove_player(pid)
	entities.get(runtimePlayersData[pid].entityId):despawn()

	cidToPid[pidToCid[pid]] = nil
	pidToCid[pid] = nil

	inventory_compat.remove_player_inventory(pid)

	runtimePlayersData[pid] = nil

	for i = 1, #playersList do
		if playersList[i] == pid then
			table.remove(playersList, i)
			i = i - 1
		end
	end
end

function player_compat.remove_all()
	localPlayerCid = nil

	for _, pid in ipairs(playersList) do
		player_compat.remove_player(pid)
	end
end

local noEmit = false

local function setClientDataProperty(nickname, key, value)
	if playersData then
		playersData:set(nickname, key, value, noEmit)
	end
end

local function getClientDataProperty(nickname, key)
	if playersData then
		return playersData:get(nickname, key)
	end
end

function player_compat.set_enabled_emit(emit)
	noEmit = not emit
end

function player_compat.get_players_list() return playersList end

function player_compat.set_local_player_client_id(clientId) localPlayerCid = clientId end

function player_compat.get_player_id(clientId)
	return clientId ~= localPlayerCid and cidToPid[clientId] or hud.get_player()
end

function player_compat.get_client_id(playerId)
	return playerId == hud.get_player() and localPlayerCid or pidToCid[playerId]
end

function player_compat.has_player(playerId) return runtimePlayersData[playerId] ~= nil end

function player_compat.set_players_data(_playersData) playersData = _playersData end

function player_compat.get_selected_slot(playerId)
	return getClientDataProperty(player.get_name(playerId), "selectedSlot")
end

function player_compat.set_selected_slot(playerId, selectedSlot)
	playersData:set(player.get_name(playerId), "selectedSlot", selectedSlot)
end

function player_compat.set_selected_item_id(playerId, itemId)
	playersData:set(player.get_name(playerId), "selectedItem", itemId)
end

function player_compat.get_selected_item_id(playerId)
	local slotId = player_compat.get_selected_slot(playerId)

	if not slotId then return playersData:get(player.get_name(playerId), "selectedItem", 0)
	else
		local itemId = inventory.get(player.get_inventory(playerId), slotId)

		return itemId
	end
end


-- Player library functions redefine


function player.get_inventory(playerId)
	if player_compat.has_player(playerId) then
		return runtimePlayersData[playerId].inventoryId, getClientDataProperty(player.get_name(playerId), "selectedSlot")
	else return _player.get_inventory(playerId) end
end

function player.get_selected_block(playerId)
	if player_compat.has_player(playerId) then
		local raycastResult = block.raycast({ player.get_pos(playerId) }, { player.get_rot(playerId) }, MAX_BLOCK_TOUCH_DISTANCE)

		if raycastResult then return unpack(raycastResult.iendpoint) end
	else return _player.get_selected_block(playerId) end
end

function player.get_selected_entity(playerId)
	if player_compat.has_player(playerId) then
		local raycastResult = entities.raycast({ player.get_pos(playerId) }, { player.get_rot(playerId) }, MAX_BLOCK_TOUCH_DISTANCE)

		if raycastResult and raycastResult.entity then return raycastResult.entity end
	else return _player.get_selected_entity(playerId) end
end

function player.get_spawnpoint(playerId)
	if player_compat.has_player(playerId) then return unpack(getClientDataProperty(player.get_name(playerId), "spawnpoint"))
	else return _player.get_spawnpoint(playerId) end
end

function player.set_spawnpoint(playerId, x, y, z)
	if player_compat.has_player(playerId) then
		setClientDataProperty(player.get_name(playerId), "spawnpoint", { x, y, z })
	else _player.set_spawnpoint(playerId, x, y, z) end
end

function player.get_pos(playerId)
	if player_compat.has_player(playerId) then return unpack(entities.get(player.get_entity(playerId)).transform:get_pos())
	else return _player.get_pos(playerId) end
end

function player.set_pos(playerId, x, y, z)
	if player_compat.has_player(playerId) then
		entities.get(player.get_entity(playerId)).transform:set_pos({ x, y, z })

		setClientDataProperty(player.get_name(playerId), "position", { x, y, z })
	else _player.set_pos(playerId, x, y, z) end
end

function player.get_vel(playerId)
	if player_compat.has_player(playerId) then return unpack(entities.get(player.get_entity(playerId)).rigidbody:get_vel())
	else return _player.get_vel(playerId) end
end

function player.set_vel(playerId, x, y, z)
	if player_compat.has_player(playerId) then
		entities.get(player.get_entity(playerId)).rigidbody:set_vel({ x, y, z })

		setClientDataProperty(player.get_name(playerId), "velocity", { x, y, z })
	else _player.set_vel(playerId, x, y, z) end
end

function player.get_rot(playerId)
	if player_compat.has_player(playerId) then
		return unpack(getClientDataProperty(player.get_name(playerId), "rotation"))
	else return _player.get_rot(playerId) end
end

function player.set_rot(playerId, x, y, z)
	if player_compat.has_player(playerId) then
		local camera = player.get_camera(playerId)

		if camera then cameras.get(camera):set_rot(math_util.rotation_matrix({ x, y, z }))

		setClientDataProperty(player.get_name(playerId), "rotation", { x, y, z })
	else _player.set_pos(playerId, x, y, z) end
end

function player.get_dir(playerId)
	if player_compat.has_player(playerId) then
		local camera = player.get_camera(playerId)

		return camera and cameras.get(camera):get_front() or { 0, 0, 0 }
	else return _player.get_dir(playerId) end
end

function player.is_flight(playerId)
	if player_compat.has_player(playerId) then return getClientDataProperty(player.get_name(playerId), "flight")
	else return _player.is_flight(playerId) end
end

function player.set_flight(playerId, flight)
	if player_compat.has_player(playerId) then setClientDataProperty(player.get_name(playerId), "flight", flight)
	else _player.set_flight(playerId, flight) end
end

function player.is_noclip(playerId)
	if player_compat.has_player(playerId) then return getClientDataProperty(player.get_name(playerId), "noclip")
	else return _player.is_noclip(playerId) end
end

function player.set_noclip(playerId, noclip)
	if player_compat.has_player(playerId) then
		setClientDataProperty(player.get_name(playerId), "noclip", noclip)
	else _player.set_noclip(playerId, noclip) end
end

function player.is_infinite_items(playerId)
	if player_compat.has_player(playerId) then return getClientDataProperty(player.get_name(playerId), "infiniteItems")
	else return _player.is_infinite_items(playerId) end
end

function player.set_infinite_items(playerId, infiniteItems)
	if player_compat.has_player(playerId) then
		setClientDataProperty(player.get_name(playerId), "infiniteItems", infiniteItems)
	else _player.set_infinite_items(playerId, infiniteItems) end
end

function player.is_instant_destruction(playerId)
	if player_compat.has_player(playerId) then return getClientDataProperty(player.get_name(playerId), "instantDestruction")
	else return _player.is_instant_destruction(playerId) end
end

function player.set_instant_destruction(playerId, instantDestruction)
	if player_compat.has_player(playerId) then
		setClientDataProperty(player.get_name(playerId), "instantDestruction", instantDestruction)
	else _player.set_instant_destruction(playerId, instantDestruction) end
end

function player.get_name(playerId)
	if player_compat.has_player(playerId) then return runtimePlayersData[playerId].name
	else return _player.get_name(playerId) end
end

function player.set_name(playerId, name)
	if player_compat.has_player(playerId) then runtimePlayersData[playerId].name = name
	else _player.set_name(playerId, name) end
end

function player.get_entity(playerId)
	if player_compat.has_player(playerId) then return runtimePlayersData[playerId].entityId
	else return _player.get_entity(playerId) end
end

function player.get_camera(playerId)
	if player_compat.has_player(playerId) then return runtimePlayersData[playerId].camera
	else return _player.get_camera(playerId) end
end

function player.set_camera(playerId, cameraId)
	if player_compat.has_player(playerId) then runtimePlayersData[playerId].camera = cameraId
	else _player.set_camera(playerId, cameraId) end
end

return player_compat