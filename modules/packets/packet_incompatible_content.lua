local packet_incompatible_content = { }

local MISSING_ON_SERVER = 0
local MISSING_ON_CLIENT = 1
local DIFFERENT_VERSIONS = 2

function packet_incompatible_content.write(packsList, buffer)
	buffer:put_uint16(#packsList)

	for i = 1, #packsList do
		local pack = packsList[i]

		buffer:put_byte(
			pack.missingOnServer and MISSING_ON_SERVER or
			pack.missingOnClient and MISSING_ON_CLIENT or
			DIFFERENT_VERSIONS
		)

		buffer:put_string(pack.id)
		buffer:put_string(pack.version)
	end
end

function packet_incompatible_content.read(buffer)
	local packsList = { }

	for i = 1, buffer:get_uint16() do
		local pack = { }

		local type = buffer:get_byte()

		if type == MISSING_ON_CLIENT then
			pack.missingOnClient = true
		elseif type == MISSING_ON_SERVER then
			pack.missingOnServer = true
		end

		pack.id = buffer:get_string()
		pack.version = buffer:get_string()

		packsList[i] = pack
	end

	return packsList
end

return packet_incompatible_content