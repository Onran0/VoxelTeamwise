local packet_kick = { }

function packet_kick.write(reason, buffer)
	buffer:put_string(reason)
end

function packet_kick.read(buffer)
	return buffer:get_string()
end

return packet_kick