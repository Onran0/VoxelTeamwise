--[[

This packet is sent to the client from the server to
inform it of a successful login and passing the indices
of the blocks and items.

--]]


local packet_indices_sync = { }

function packet_indices_sync.write(indices, buffer)
	local bytes = bjson.tobytes(indices)

	buffer:put_uint32(#bytes)
	buffer:put_bytes(bytes)
end

function packet_indices_sync.read(buffer)
	return bjson.from_bytes(buffer:get_bytes(buffer:get_uint32()))
end

return packet_indices_sync