local packet_login = { }

function packet_login.write(data, buffer)
	buffer:put_uint32(data.protocolVersion)
	buffer:put_string(data.nickname)
end

function packet_login.read(buffer)
	local protocolVersion, nickname = buffer:get_uint32(), buffer:get_string()

	return
	{
		protocolVersion = protocolVersion,
		nickname = nickname
	}
end

return packet_login