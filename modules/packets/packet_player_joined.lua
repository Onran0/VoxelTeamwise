local buffer_ext = require "util/buffer_ext"

local packet_player_joined = { }

function packet_player_joined.write(data, buffer)
	buffer:put_uint16(data.clientId)
	buffer:put_string(data.nickname)
	buffer_ext.put_vec3f32(buffer, data.position)
	buffer_ext.put_vec3f32(buffer, data.rotation)
	buffer:put_uint16(data.selectedItemId)
end

function packet_player_joined.read(buffer)
	local clientId = buffer:get_uint16()
	local nickname = buffer:get_string()
	local position = buffer_ext.get_vec3f32(buffer)
	local rotation = buffer_ext.get_vec3f32(buffer)
	local selectedItemId = buffer:get_uint16()

	return
	{
		clientId = clientId,
		nickname = nickname,
		position = position,
		rotation = rotation,
		selectedItemId = selectedItemId
	}
end

return packet_player_joined