local packet_chat = { }

function packet_chat.write(message, buffer)
	buffer:put_string(message)
end

function packet_chat.read(buffer)
	return buffer:get_string()
end

return packet_chat