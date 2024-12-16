local MAX_BLOCK_TOUCH_DISTANCE = 16

local inventory_compat = require "content_compat/inventory_compat"

local math_util = require "util/math_util"

local player_compat = { }

local playersData = { }
local playersList = { }

local cidToPid = { }
local pidToCid = { }

local clientsData

function player_compat.spawn_player(clientId, nickname, position, rotation, inventory, data)
	local entity =
	entities.spawn(
		PACK_ID..":player",
		position,
		{ [PACK_ID.."__player_animator"] = { clientId } }
	)

	entity.transform:set_rot(math_util.euler_to_mat4(rotation))

	if not data then data = { } end

	data.name = nickname

	return player_compat.add_player(clientId, entity:get_uid(), data)
end

function player_compat.add_player(clientId, entityId, data)
	if not entityId then error "player without entity" end

	local pid = clientId + 0x02

	data.entityId = entityId

	cidToPid[clientId] = pid
	pidToCid[pid] = clientId

	local playerData =
	{
		entityId = entityId,
		flight = false,
		instantDestruction = true,
		spawnpoint = { 0, 0, 0 },
		selectedSlot = 0
	}

	if data then
		for key, value in pairs(data) do
			playerData[key] = value
		end
	end

	playerData.inventoryId = inventory_compat.create_player_inventory(pid, data.inventoryFiller)

	playersData[pid] = data

	table.insert(playersList, pid)

	return pid
end

function player_compat.remove_player(pid)
	entities.get(playersData[pid]):despawn()

	cidToPid[pidToCid[pid]] = nil
	pidToCid[pid] = nil

	inventory_compat.remove_player_inventory(pid)

	playersData[pid] = nil

	for i = 1, #playersList do
		if playersList[i] == pid then
			table.remove(playersList, i)
			i = i - 1
		end
	end
end

function player_compat.remove_all()
	for _, pid in ipairs(playersList) do
		player_compat.remove_player(pid)
	end
end

local noEmit = false

local function setClientDataProperty(nickname, key, value)
	if clientsData then
		clientsData:set(nickname, key, value, noEmit)
	end
end

function player_compat.set_enabled_emit(emit)
	noEmit = not emit
end

function player_compat.get_players_list() return playersList end

function player_compat.get_player_id(clientId) return cidToPid[clientId] end

function player_compat.has_player(playerId) return playersData[playerId] ~= nil end

function player_compat.set_clients_data(_clientsData) return clientsData = _clientsData end

function player_compat.get_selected_slot(playerId) return playersData[playerId].selectedSlot end

function player_compat.set_selected_slot(playerId, selectedSlot)
	playersData[playerId].selectedSlot = selectedSlot
	clientsData:set(player.get_name(playerId), "selectedSlot", selectedSlot)
end

local __player_get_pos = player.get_pos
local __player_set_pos = player.set_pos
local __player_get_vel = player.get_vel
local __player_set_vel = player.set_vel
local __player_get_rot = player.get_rot
local __player_set_rot = player.set_rot
local __player_get_inventory = player.get_inventory
local __player_is_flight = player.is_flight
local __player_set_flight = player.set_flight
local __player_is_noclip = player.is_noclip
local __player_set_noclip = player.set_noclip
local __player_is_infinite_items = player.is_infinite_items
local __player_set_infinite_items = player.set_infinite_items
local __player_is_instant_destruction = player.is_instant_destruction
local __player_set_instant_destruction = player.set_instant_destruction
local __player_set_name = player.set_name
local __player_get_name = player.get_name
local __player_get_entity = player.get_entity
local __player_get_spawnpoint = player.get_spawnpoint
local __player_set_spawnpoint = player.set_spawnpoint
local __player_get_selected_block = player.get_selected_block
local __player_get_selected_entity = player.get_selected_entity

function player.get_inventory(playerId)
	if player_compat.has_player(playerId) then
		local playerData = playersData[playerId]

		return playerData.inventoryId, playerData.selectedSlot
	else return __player_get_inventory(playerId) end
end

function player.get_selected_block(playerId)
	if player_compat.has_player(playerId) then
		local raycastResult = block.raycast({ player.get_pos(playerId) }, { player.get_rot(playerId) }, MAX_BLOCK_TOUCH_DISTANCE)

		if raycastResult then return unpack(raycastResult.iendpoint) end
	else return __player_get_selected_block(playerId) end
end

function player.get_selected_entity(playerId)
	if player_compat.has_player(playerId) then
		local raycastResult = entities.raycast({ player.get_pos(playerId) }, { player.get_rot(playerId) }, MAX_BLOCK_TOUCH_DISTANCE)

		if raycastResult and raycastResult.entity then return raycastResult.entity end
	else return __player_get_selected_entity(playerId) end
end

function player.get_spawnpoint(playerId)
	if player_compat.has_player(playerId) then
		local spawnpoint = playersData[playerId].spawnpoint

		return spawnpoint[1], spawnpoint[2], spawnpoint[3]
	else return __player_get_spawnpoint(playerId) end
end

function player.set_spawnpoint(playerId, x, y, z)
	if player_compat.has_player(playerId) then
		local spawnpoint = playersData[playerId].spawnpoint

		spawnpoint[1], spawnpoint[2], spawnpoint[3] = x, y, z

		setClientDataProperty(player.get_name(playerId), "spawnpoint", { x, y, z })
	else __player_set_spawnpoint(playerId, x, y, z) end
end

function player.get_pos(playerId)
	if player_compat.has_player(playerId) then return unpack(entities.get(playersData[playerId].entityId).transform:get_pos())
	else return __player_get_pos(playerId) end
end

function player.set_pos(playerId, x, y, z)
	if player_compat.has_player(playerId) then
		entities.get(playersData[playerId].entityId).transform:set_pos({ x, y, z })

		setClientDataProperty(player.get_name(playerId), "position", { x, y, z })
	else __player_set_pos(playerId, x, y, z) end
end

function player.get_vel(playerId)
	if player_compat.has_player(playerId) then return unpack(entities.get(playersData[playerId].entityId).rigidbody:get_vel())
	else return __player_get_vel(playerId) end
end

function player.set_vel(playerId, x, y, z)
	if player_compat.has_player(playerId) then
		entities.get(playersData[playerId].entityId).rigidbody:set_vel({ x, y, z })

		setClientDataProperty(player.get_name(playerId), "velocity", { x, y, z })
	else __player_set_vel(playerId, x, y, z) end
end

function player.get_rot(playerId)
	if player_compat.has_player(playerId) then return unpack(entities.get(playersData[playerId].entityId).transform:get_rot())
	else return __player_get_rot(playerId) end
end

function player.set_rot(playerId, x, y, z)
	if player_compat.has_player(playerId) then
		entities.get(playersData[playerId].entityId).transform:set_rot({ x, y, z })

		setClientDataProperty(player.get_name(playerId), "rotation", { x, y, z })
	else __player_set_pos(playerId, x, y, z) end
end

function player.is_flight(playerId)
	if player_compat.has_player(playerId) then return playersData[playerId].flight
	else return __player_is_flight(playerId) end
end

function player.set_flight(playerId, flight)
	if player_compat.has_player(playerId) then
		playersData[playerId].flight = flight

		setClientDataProperty(player.get_name(playerId), "flight", flight)
	else __player_set_flight(playerId, flight) end
end

function player.is_noclip(playerId)
	if player_compat.has_player(playerId) then return playersData[playerId].noclip
	else return __player_is_noclip(playerId) end
end

function player.set_noclip(playerId, noclip)
	if player_compat.has_player(playerId) then
		playersData[playerId].noclip = noclip
		setClientDataProperty(player.get_name(playerId), "noclip", noclip)
	else __player_set_noclip(playerId, noclip) end
end

function player.is_infinite_items(playerId)
	if player_compat.has_player(playerId) then return playersData[playerId].infiniteItems
	else return __player_is_infinite_items(playerId) end
end

function player.set_infinite_items(playerId, infiniteItems)
	if player_compat.has_player(playerId) then
		playersData[playerId].infiniteItems = infiniteItems

		setClientDataProperty(player.get_name(playerId), "infiniteItems", infiniteItems)
	else __player_set_infinite_items(playerId, infiniteItems) end
end

function player.is_instant_destruction(playerId)
	if player_compat.has_player(playerId) then return playersData[playerId].instantDestruction
	else return __player_is_instant_destruction(playerId) end
end

function player.set_instant_destruction(playerId, instantDestruction)
	if player_compat.has_player(playerId) then
		playersData[playerId].instantDestruction = instantDestruction
		setClientDataProperty(player.get_name(playerId), "instantDestruction", instantDestruction)
	else __player_set_instant_destruction(playerId, instantDestruction) end
end

function player.get_name(playerId)
	if player_compat.has_player(playerId) then return playersData[playerId].name
	else return __player_get_name(playerId) end
end

function player.set_name(playerId, name)
	if player_compat.has_player(playerId) then playersData[playerId].name = name
	else __player_set_name(playerId, name) end
end

function player.get_entity(playerId)
	if player_compat.has_player(playerId) then return playersData[playerId].entityId
	else return __player_get_entity(playerId) end
end

return player_compat