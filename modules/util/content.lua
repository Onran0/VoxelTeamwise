local content = { }

local indices, contentInfo

function content.get_indices_table()
	if not indices then
		indices = json.parse(file.read("world:indices.json"))
	end

	return indices
end

function content.get_content_info()
	if not contentInfo then
		contentInfo = { }

		local packs = pack.get_installed()

		for i = 1, #packs do
			local info = pack.get_info(packs[i])

			contentInfo[i] = { id = info.id, version = info.version }
		end
	end

	return contentInfo
end

return content