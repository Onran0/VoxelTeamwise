local packet_content_info = { }

function packet_content_info.write(packsList, buffer)
	buffer:put_uint16(#packsList)

	for i = 1, #packsList do
		local pack = packsList[i]

		buffer:put_string(pack.id)
		buffer:put_string(pack.version)
	end
end

function packet_content_info.read(buffer)
	local packsList = { }

	for i = 1, buffer:get_uint16() do
		local pack = { }
		
		pack.id = buffer:get_string()
		pack.version = buffer:get_string()

		packsList[i] = pack
	end

	return packsList
end

return packet_content_info