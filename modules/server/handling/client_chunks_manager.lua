local chunk_util = require "util/chunk_util"

local client_chunks_manager = { }

function client_chunks_manager:new(handler)
	local obj = { }

    self.__index = self
    setmetatable(obj, self)

    self.clientHandler = handler
    self.currentChunk = { }
    self.loadedChunks = { }
    self.teamwiseServer = handler.temwiseServer
    self.server = handler.temwiseServer.server

	return obj
end

function client_chunks_manager:update()
    local cx, cz = chunk_util.block_position_to_chunk_position(player.get_pos(self.clientHandler:get_player_id()))

    self.currentChunk[1], self.currentChunk[2] = cx, cz

    local chunks, nodes = chunk_util.get_chunks_positions_in_radius(cx, cz, self.teamwiseServer.settings.chunksLoadingDistance)

    for i = 1, #self.loadedChunks do
        local chunkPos = self.loadedChunks[i]

        if not nodes[chunk_util.get_hash_of_chunk_position(chunkPos[1], chunkPos[2])] then
            self:unload_chunk_for_client(chunkPos[1], chunkPos[2])
        end
    end

    for i = 1, #chunks do
        local cx, cz = chunks[i][1], chunks[i][2]

        if not self:is_chunk_loaded_for_client(cx, cz) then
            self:load_chunk_for_client(cx, cz)
        end
    end
end

function client_chunks_manager:is_in_loaded_area(x, z)
    return chunk_util.is_block_position_inside_chunks(x, z, self.loadedChunks)
end

function client_chunks_manager:is_chunk_loaded_for_client(cx, cz)
    return self.loadedChunks[chunk_util.get_hash_of_chunk_position(cx, cz)] ~= nil
end

function client_chunks_manager:unload_chunk_for_client(cx, cz)
    self.loadedChunks[chunk_util.get_hash_of_chunk_position(cx, cz)] = nil
end

function client_chunks_manager:load_chunk_for_client(cx, cz)
    self.loadedChunks[chunk_util.get_hash_of_chunk_position(cx, cz)] = { cx, cz }
    self.server:send_packet(self.clientId, PACK_ID..":packet_chunk",
        {
            position = { cx, cz },
            chunkData = world.get_chunk_data(cx, cz, true)
        }
    )
end

return client_chunks_manager