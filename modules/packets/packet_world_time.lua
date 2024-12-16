local packet_world_time = { }

function packet_world_time.write(time, buffer)
	buffer:put_single(time)
end

function packet_world_time.read(buffer)
	return buffer:get_single()
end

return packet_world_time