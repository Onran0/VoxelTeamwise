local buffer_ext = require "util/buffer_ext"

local packet_chunk = { }

function packet_chunk.write(data, buffer)
	buffer_ext.put_chunk_pos(buffer, data.position)
	buffer:put_uint32(#data.chunkData)
	buffer:put_bytes(data.chunkData)
end

function packet_chunk.read(buffer)
	local data = { }

	data.position = buffer_ext.get_chunk_pos(buffer)
	data.chunkData = buffer:get_bytes(buffer:get_uint32())

	return data
end

return packet_chunk