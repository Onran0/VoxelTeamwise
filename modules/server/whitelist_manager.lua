local whitelist_manager = { }

function whitelist_manager:new(server)
    local obj = { }

    self.__index = self
    setmetatable(obj, self)

    self.server = server
    self.data = { names = { }, addresses = { } }

    return obj
end

function whitelist_manager:load_data(path)
	if file.exists(path) then
		self.data = json.parse(file.read(path))
	end
end

function whitelist_manager:save_data(path)
	file.write(path, json.tostring(self.data))
end

local function add(list, object)
    if not table.has(list, object) then
        table.insert(list, object)
        return true
    else return false end
end

local function remove(list, object)
    if table.has(list, object) then
        table.remove(list, table.index(list, object))
        return true
    else return false end
end

local function contains(list, object)
    return table.has(list, object)
end

function whitelist_manager:add_name(name)
    if add(self.data.names, name) then
        self.server:log("player with nickname '"..name.."' was added to the whitelist")
    end
end

function whitelist_manager:remove_name(name)
    if remove(self.data.names, name) then
        self.server:log("player with nickname '"..name.."' was removed from the whitelist")
    end
end

function whitelist_manager:add_address(address)
    if add(self.data.addresses, address) then
        self.server:log("IP address "..address.." was added to the whitelist")
    end
end

function whitelist_manager:remove_address(address)
    if remove(self.data.addresses, address) then
        self.server:log("IP address "..address.." was removed from the whitelist")
    end
end

function whitelist_manager:has_name(name)
    return contains(self.data.names, name)
end

function whitelist_manager:has_address(address)
    return contains(self.data.addresses, address)
end

return whitelist_manager