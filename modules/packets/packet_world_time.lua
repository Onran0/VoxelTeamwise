local packet_world_time = { }

function packet_world_time.write(time, buffer)
	buffer:put_float32(time)
end

function packet_world_time.read(buffer)
	return buffer:get_float32()
end

return packet_world_time