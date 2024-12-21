local players_data = { }

function players_data:new()
	local obj = { }

	self.__index = self
    setmetatable(obj, self)
    self.data = { }
    self.listeners = { }
    self.listenersByName = { }

	return obj
end

function players_data:get(nickname, key, def)
	if self.data[nickname] then return self.data[nickname][key] or def
	else return def end
end

local function emit(listeners, key, value, nickname)
	for i = 1, #listeners do
		local listener = listeners[i]

		if listener[1] == key then
			local status, error = pcall(listener[2], value, nickname)

			if not status then
				print(error)
			end
		end
	end
end

function players_data:set(nickname, key, value, noEmit)
	if not self.data[nickname] then self.data[nickname] = { } end

	self.data[nickname][key] = value

	if not noEmit then
		if self.listenersByName[nickname] then
			emit(self.listenersByName[nickname], key, value, nickname)
		end

		emit(self.listeners, key, value, nickname)
	end

	return value
end

function players_data:has_player_data(nickname)
	return self.data[nickname] ~= nil
end

function players_data:add_property_listener(nickname, key, listener)
	if nickname then
		if not self.listenersByName[nickname] then
			self.listenersByName[nickname] = { }
		end

		table.insert(self.listenersByName[nickname], { key, listener })
	else
		table.insert(self.listeners, { key, listener })
	end
end

function players_data:on_disconnected(nickname)
	self.data[nickname] = nil
	self.listenersByName[nickname] = nil
end

return players_data