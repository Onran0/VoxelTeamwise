local buffer_ext = require "util/buffer_ext"

local BOOL_TYPE = 0
local INT_TYPE = 1
local NUMBER_TYPE = 2
local STRING_TYPE = 3

local packet_block_field_changed = { }

function packet_block_field_changed.write(data, buffer)
	buffer_ext.put_block_pos(buffer, data.position)
	
	buffer:put_string(data.name)

	buffer:put_uint32(data.index)

	local valueType = type(data.value)

	if valueType == "boolean" then
		buffer:put_byte(BOOL_TYPE)
		buffer:put_bool(data.value)
	elseif valueType == "string" then
		buffer:put_byte(STRING_TYPE)
		buffer:put_string(data.value)
	elseif valueType == "number" then
		if math.type(data.value) == "integer" then
			buffer:put_byte(INT_TYPE)
			buffer:put_sint32(data.value)
		else
			buffer:put_byte(NUMBER_TYPE)
			buffer:put_float32(data.value)
		end
	else error("unknown field value type: "..valueType) end
end

function packet_block_field_changed.read(buffer)
	local data = { }

	data.position = buffer_ext.get_block_pos(buffer)
	
	data.name = buffer:get_string()

	data.index = buffer:get_uint32()

	local valueType = buffer:get_byte()

	if valueType == BOOL_TYPE then
		data.value = buffer:get_bool()
	elseif valueType == STRING_TYPE then
		data.value = buffer:get_string()
	elseif valueType == INT_TYPE then
		data.value = buffer:get_sint32()
	elseif valueType == NUMBER_TYPE then
		data.value = buffer:get_float32()
	else error("unknown field value type index: "..valueType) end

	return data
end

return packet_block_field_changed