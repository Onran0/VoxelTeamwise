local PACK_ID = require("constants").packId

local player_compat = require "content_compat/player_compat"

local blocks_callbacks = { }

function blocks_callbacks:new(client)
	local obj = { }

    self.__index = self
    setmetatable(obj, self)

    self.teamwiseClient = client
    self.client = client.client

	return obj	
end

function blocks_callbacks:block_changed_by_player(x, y, z, id, states, playerId)
	self.client.add_to_send_queue(PACK_ID..":packet_block_changed_by_player",
		{
			position = { x, y, z },
			blockId = id,
			states = states
		}
	)
end

return blocks_callbacks