local packet_player_leave = { }

function packet_player_leave.write(data, buffer)
	buffer:put_uint16(data.clientId)
	buffer:put_bool(data.dueToError)
end

function packet_player_leave.read(buffer)
	local clientId, dueToError = buffer:get_uint16(), buffer:get_bool()

	return
	{
		clientId = clientId,
		dueToError = dueToError
	}
end

return packet_player_leave