local buffer_ext = require "util/buffer_ext"

local packet_player_transform = { }

function packet_player_transform.write(data, buffer, isServer)
	if isServer then buffer:put_uint16(data.clientId) end

	local dirtyBits = bit.bor(data.position and POSITION or 0, data.rotation and ROTATION or 0)

	buffer:put_byte(dirtyBits)
	
	if data.position then buffer_ext.put_vec3f32(buffer, data.position) end

	if data.rotation then buffer_ext.put_vec3f32(buffer, data.rotation) end
end

function packet_player_transform.read(buffer, isServer)
	local data = { }

	if not isServer then data.clientId = buffer:get_uint16() end

	local dirtyBits = buffer:get_byte()

	if bit.band(dirtyBits, POSITION) ~= 0 then
		data.position = buffer_ext.get_vec3f32(buffer)
	end

	if bit.band(dirtyBits, ROTATION) ~= 0 then
		data.rotation = buffer_ext.get_vec3f32(buffer)
	end

	return data
end

return packet_player_transform