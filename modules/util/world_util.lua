local world_util = { }

function world_util.has_world(name)
	return table.has(world.get_list(), name)
end

function world_util.get_world_name()
	local path = file.resolve("world:"):replace('\\', '/')

	local lastSlashIndex = -1

	for i = 1, #path do
		if path:sub(i, i) == '/' then
			lastSlashIndex = i
		end
	end

	if lastSlashIndex == -1 then return path
	else return path:sub(lastSlashIndex + 1)
end

return world_util