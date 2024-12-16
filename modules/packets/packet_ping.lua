local packet_ping = { }

function packet_ping.write(data, buffer)
	buffer:put_bool(data.fromClientToServer)
end

function packet_ping.read(buffer)
	return
	{
		fromClientToServer = buffer:get_bool()
	}
end

return packet_ping