--[[

This packet is sent to the client from the server to
inform it of a successful login and passing its clientId

--]]


local packet_identified = { }

function packet_identified.write(clientId, buffer)
	buffer:put_uint16(clientId)
end

function packet_identified.read(buffer)
	return buffer:get_uint16()
end

return packet_identified