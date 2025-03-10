local PACK_ID = require("constants").packId

local player_compat = require "content_compat/player_compat"

local blocks_callbacks = { }

function blocks_callbacks:new(server)
	local obj = { }

    self.__index = self
    setmetatable(obj, self)

    self.teamwiseServer = server
    self.server = server.server

	return obj	
end

function blocks_callbacks:send_packet_to_players_in_loaded_area(x, z, packetId, packetData, except)
	local iterator = is_array(self.teamwiseServer.handlers) and ipairs or pairs

    for clientId, handler in iterator(self.teamwiseServer.handlers) do
        if not table.has(except, clientId) then
            local x, _, z = player.get_pos(player_compat.get_player_id(clientId))

            if handler.chunksManager:is_in_loaded_area(x, z) then
                self.server:send_packet(clientId, packetId, packetData)
            end
        end
    end
end

function blocks_callbacks:block_changed(x, y, z, id, states, noupdate)
	self:send_packet_to_players_in_loaded_area(x, z, PACK_ID..":packet_block_changed",
		{
			position = { x, y, z },
			blockId = id,
			states = states
		}
	)
end

function blocks_callbacks:block_changed_by_player(x, y, z, id, states, playerId)
	self:send_packet_to_players_in_loaded_area(x, z, PACK_ID..":packet_block_changed_by_player",
		{
			clientId = player_compat.get_client_id(playerId),
			position = { x, y, z },
			blockId = id,
			states = states
		}
	)
end

function blocks_callbacks:block_states_changed(x, y, z, states)
	self:send_packet_to_players_in_loaded_area(x, z, PACK_ID..":packet_block_states_changed",
		{
			position = { x, y, z },
			states = states
		}
	)
end

function blocks_callbacks:block_field_changed(x, y, z, name, value, index)
	self:send_packet_to_players_in_loaded_area(x, z, PACK_ID..":packet_block_field_changed",
		{
			position = { x, y, z },
			name = name,
			value = value,
			index = index
		}
	)
end

function blocks_callbacks:block_rotation_changed(x, y, z, rotation)
	self:send_packet_to_players_in_loaded_area(x, z, PACK_ID..":packet_block_rotation_changed",
		{
			position = { x, y, z },
			rotation = rotation
		}
	)
end

return blocks_callbacks