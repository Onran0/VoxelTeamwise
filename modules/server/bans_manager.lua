local bans_manager = { }

function bans_manager:new(server)
    local obj = { }

    self.__index = self
    setmetatable(obj, self)

    self.server = server
    self.data = { names = { }, addresses = { } }

    return obj
end

function bans_manager:load_data(path)
	if file.exists(path) then
		self.data = json.parse(file.read(path))
	end
end

function bans_manager:save_data(path)
	file.write(path, json.tostring(self.data))
end

local function ban(tbl, key, reason)
    if not tbl[key] then
        tbl[key] = { reason = reason }
        return true
    else return false end
end

local function unban(tbl, key)
    if tbl[key] then
        tbl[key] = nil
        return true
    else return false end
end

local function isBanned(tbl, key)
    return tbl[key] ~= nil
end

local function getBanReason(tbl, key)
    if isBanned(tbl, key) then return tbl[key].reason end
end

function bans_manager:ban_name(name, reason)
    if ban(self.data.names, name, reason) then
        local cid = self.server:get_client_id_by_nickname(name)

        if cid then
            self.server.handlers[cid]:kick("banned for the following reason: "..name)
        end

        self.server:log("player with the nickname '"..name.."' was banned for the following reason: "..reason)
    end
end

function bans_manager:ban_address(address, reason)
    if ban(self.data.addresses, address, reason) then
        self.server:log("IP address "..address.." was banned for the following reason: "..reason)
    end
end

function bans_manager:unban_name(names)
    if unban(self.data.names, name) then
        self.server:log("player with nickname '"..name.."' was unbanned")
    end
end

function bans_manager:unban_address(address)
    if unban(self.data.addresses, address) then
        self.server:log("IP address "..address.." was unbanned")
    end
end

function bans_manager:is_banned_name(name)
    return isBanned(self.data.names, name)
end

function bans_manager:is_banned_address(address)
    return isBanned(self.data.addresses, address)
end

function bans_manager:get_ban_reason_by_name(name)
    return getBanReason(self.data.names, name)
end

function bans_manager:get_ban_reason_by_address(address)
    return getBanReason(self.data.addresses, address)
end

return bans_manager