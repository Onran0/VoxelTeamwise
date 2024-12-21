local packets_registry = "packet_api:packets_registry"

local teamwise_packets_registry = { }

local packets = { }

function teamwise_packets_registry.get_packets()
	if #packets == 0 then
		for _, packetFile in ipairs(file.list(PACK_ID..":modules/packets")) do
			if packetFile:starts_with("packet") then table.insert(packets, packetFile:sub(1, #packetFile - 4)) end
		end
	end

	return packets
end

function teamwise_packets_registry.register_packets()
	for _, packetName in ipairs(packets) do
		packets_registry.register_packet(
			PACK_ID..':'..packetName,
			require(PACK_ID..":packets/"..packetName)
		)
	end
end

return teamwise_packets_registry