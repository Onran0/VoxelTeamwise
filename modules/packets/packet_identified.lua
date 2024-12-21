--[[

This packet is sent to the client from the server to
inform it of a successful login, passing its clientId
and the indices of the blocks and items.

--]]


local packet_identified = { }

function packet_identified.write(data, buffer)
	buffer:put_uint16(data.clientId)
	local bytes = bjson.tobytes(data.indices, true)

	buffer:put_uint32(#bytes)
	buffer:put_bytes(bytes)
end

function packet_identified.read(buffer)
	local data = { }

	data.clientId = buffer:get_uint16()
	data.indices = bjson.from_bytes(buffer:get_bytes(buffer:get_uint32()))

	return data
end

return packet_identified