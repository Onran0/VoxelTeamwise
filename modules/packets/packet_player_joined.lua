local buffer_ext = require "util/buffer_ext"

local packet_player_joined = { }

function packet_player_joined.write(data, buffer)
	buffer:put_uint16(data.clientId)
	buffer:put_string(data.nickname)
	buffer_ext.put_vec3f(data.position)
	buffer_ext.put_vec3f(data.rotation)
	buffer:put_bool(data.isSelf)
end

function packet_player_joined.read(buffer)
	local clientId = buffer:get_uint16()
	local nickname = buffer:get_string()
	local position = buffer_ext.get_vec3f()
	local rotation = buffer_ext.get_vec3f()
	local isSelf = buffer:get_bool()

	return
	{
		clientId = clientId,
		nickname = nickname,
		position = position,
		rotation = rotation,
		isSelf = isSelf
	}
end

return packet_player_joined