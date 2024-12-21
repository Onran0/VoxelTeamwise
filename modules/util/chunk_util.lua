local chunk_util = { }

local cam
local oldCameraId

local function sign(n) return n < 0 and -1 or 1 end

function chunk_util.block_position_to_chunk_position(x, z)
	return
	bit.rshift(math.abs(x), 4) * sign(x),
	bit.rshift(math.abs(z), 4) * sign(z)
end

function chunk_util.load_chunk_at_block(x, z)
	chunk_util.load_chunk(chunkPosition.block_position_to_chunk_position(x, z))
end

function chunk_util.load_chunk(cx, cz)
	if not cam then cam = cameras.get(PACK_ID..":chunks_load_camera") end

	local playerId = hud.get_player()

	oldCameraId = player.get_camera(playerId)

	player.set_camera(playerId, cam:get_index())
end

function chunk_util.unload_chunk()
	if cam then
		player.set_camera(hud.get_player(), oldCameraId)
	end
end

function chunk_util.get_neighbor_chunks_positions(cx, cz)
	return
	{
		{ cx + 1, cz },
		{ cx, cz + 1 },
		{ cx - 1, cz },
		{ cx, cz - 1 }
	}
end

function chunk_util.get_hash_of_chunk_position(cx, cz)
	return cx * 64 + cz
end

function chunk_util.get_chunks_positions_in_radius(cx, cz, radius)
	local nodes =
	{
		[chunk_util.get_hash_of_chunk_position(cx, cz)] = { cx, cz }
	}

	local chunks = { { cx, cz } }

	for i = 1, math.abs(radius) do
		for _, chunkPosition in pairs(nodes) do
			local neighbors = chunk_util.get_neighbor_chunks_positions(chunkPosition[1], chunkPosition[2])

			for j = 1, #neighbors do
				local neighbor = neighbors[j]

				local cx, cz = neighbor[1], neighbor[2]

				local pos = { cx, cz }

				local hash = chunk_util.get_hash_of_chunk_position(cx, cz)

				if not nodes[hash] then
					nodes[hash] = pos
					table.insert(chunks, pos)
				end
			end
		end
	end

	return chunks, nodes
end

function chunk_util.is_block_position_inside_chunks(x, z, chunks)
    x, z = chunk_util.block_position_to_chunk_position(x, z)

    for i = 1, #chunks do
        if x == chunks[i][1] and z == chunks[i][2] then return true end
    end

    return false
end

return chunk_util