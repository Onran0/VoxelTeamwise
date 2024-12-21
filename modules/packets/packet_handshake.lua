local packet_handshake = { }

function packet_handshake.write(data, buffer)
	buffer:put_uint32(data.protocolVersion)
	buffer:put_string(data.nickname)
end

function packet_handshake.read(buffer)
	local protocolVersion, nickname = buffer:get_uint32(), buffer:get_string()

	return
	{
		protocolVersion = protocolVersion,
		nickname = nickname
	}
end

return packet_handshake