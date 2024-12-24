local packet_command = { }

function packet_command.write(prompt, buffer)
	buffer:put_string(prompt)
end

function packet_command.read(buffer)
	return buffer:get_string()
end

return packet_command