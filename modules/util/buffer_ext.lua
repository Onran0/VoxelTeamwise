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

function buffer_ext.put_vec3f32(buffer, vec)
	buffer:put_float32(vec[1])
	buffer:put_float32(vec[2])
	buffer:put_float32(vec[3])
end

function buffer_ext.get_vec3f32(buffer)
	return { buffer:get_float32(), buffer:get_float32(), buffer:get_float32() }
end

function buffer_ext.put_vec3f64(buffer, vec)
	buffer:put_float64(vec[1])
	buffer:put_float64(vec[2])
	buffer:put_float64(vec[3])
end

function buffer_ext.get_vec3f64(buffer)
	return { buffer:get_float64(), buffer:get_float64(), buffer:get_float64() }
end

function buffer_ext.obtain_buffer(buffer)
	for name, fn in pairs(buffer_ext) do
		if name ~= "obtain_buffer" then buffer[name] = fn end
	end
end

return buffer_ext