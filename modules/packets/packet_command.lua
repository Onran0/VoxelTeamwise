local packet_command = { }

function packet_command.write(command, buffer)
	buffer:put_string(command)
end

function packet_command.read(buffer)
	return buffer:get_string()
end

return packet_command