local MAX_UINT16 = 2^16-1
local MAX_UINT32 = 2^32-1

local MAX_INT16 = 2^15-1
local MIN_INT16 = -(2^15)
local MAX_INT32 = 2^31-1
local MIN_INT32 = -(2^31)

local buffer_ext = { }

function buffer_ext.put_chunk_pos(buffer, pos)
	buffer_ext.put_sint16(buffer, pos[1])
	buffer_ext.put_sint16(buffer, pos[2])
end

function buffer_ext.put_block_pos(buffer, pos)
	buffer:put_sint32(buffer, pos[1])
	buffer:put_sint32(buffer, pos[2])
	buffer:put_sint32(buffer, pos[3])
end

function buffer_ext.get_chunk_pos(buffer)
	return { buffer:get_sint16(buffer), buffer:get_sint16(buffer) }
end

function buffer_ext.get_block_pos(buffer)
	return { buffer:get_sint32(buffer), buffer:get_sint32(buffer), buffer:get_sint32(buffer) }
end

function buffer_ext.put_vec3f(buffer, vec)
	buffer:put_single(vec[1])
	buffer:put_single(vec[2])
	buffer:put_single(vec[3])
end

function buffer_ext.get_vec3f(buffer)
	return { buffer:get_single(), buffer:get_single(), buffer:get_single() }
end

function buffer_ext.put_vec3d(buffer, vec)
	buffer:put_double(vec[1])
	buffer:put_double(vec[2])
	buffer:put_double(vec[3])
end

function buffer_ext.get_vec3d(buffer)
	return { buffer:get_double(), buffer:get_double(), buffer:get_double() }
end

function buffer_ext.obtain_buffer(buffer)
	for name, fn in pairs(buffer_ext) do
		if name ~= "obtain_buffer" then buffer[name] = fn end
	end
end

return buffer_ext