local constants = require "constants"

local server = require "packet_api:server"

local client_handler = require "server/handling/client_handler"
local players_data = require "players_data"

local function bjsonReader(path) return bjson.frombytes(file.read_bytes(path)) end
local function bjsonWriter(path, table) file.write_bytes(path, bjson.tobytes(table)) end

local function jsonReader(path) return json.parse(file.read(path)) end
local function jsonWriter(path, table) return file.write(path, json.tostring(table)) end

local teamwise_server = { }

function teamwise_server:start(settings)
    local obj = { }

    self.__index = self
    setmetatable(obj, self)

    self.playersData = players_data:new()
    self.handlers = { }

    self.settings =
    {
        port = constants.defaultPort,
        chunksLoadingDistance = 5,
        whiteListEnabled = false,
        serverDataDirectory = pack.shared_file(PACK_ID, "server")
    }

    if settings then
        for key, value in pairs(settings) do
            self.settings[key] = value
        end
    end

    file.mkdirs(self.settings.serverDataDirectory)

    self:load_all_data()

    if not self.globalData.defaultSpawnpoint then
        self.globalData.defaultSpawnpoint = { player.get_spawnpoint(hud.get_player()) }
    end

    self.server = server:open(self.settings.port,
    	function(...)
    		return self:on_connected(...)
    	end,
       	function(...)
    		self:on_disconnected(...)
    	end
    )

    return obj
end

function teamwise_server:log(...)
    print("[voxel teamwise server]", ...)
end

function teamwise_server:send_packet_to_all_except(packetId, packetData, except)
    for _, clientId in ipairs(self.server:get_all_clients_ids()) do
        if not table.has(except, clientId) then self.server:send_packet(clientId, packetId, packetData) end
    end
end

function teamwise_server:on_connected(server, clientId)
	self:log("client connected to the server. id: "..clientid..", address: "..self.server:get_client_address(clientId))

    self.handlers[clientId] = client_handler:new(self, clientId)

    return
    function(server, packetId, packetData)
        if client_handler.handlers[packetId] then
            local handler = self.handlers[clientId]

            local success, isValid, kickReason = pcall(client_handler.validate_packet, handler, packetId, packetData)

            if not success then
                self:log("failed to check packet: ", isValid)
            elseif isValid then
                local packetHandler = client_handler.handlers[packetId]

                if packetHandler then success, error = pcall(packetHandler, handler, packetData)
                else
                    isValid = false
                    kickReason = "client packet sent to server"
                end
            end

            if not success then
                self:log("an error occurred while processing packet '"..packetId.."' from player "..self:get_nickname(clientId).." (client id: "..clientId.." ) :", error)
                handler:kick("internal server error", true)
            elseif not isValid then
                self:log("received invalid packet '"..packetId.."' from player "..self:get_nickname(clientId).." (client id: "..clientId.." ) :", error)
                handler:kick("invalid packet: "..kickReason, true)
            end
        else
            self:log("unknown packet:", packetId)
        end
    end
end

function teamwise_server:get_ban_reason_by_name(name)
    return self.banList.names[name].reason
end

function teamwise_server:get_ban_reason_by_address(address)
    return self.banList.addresses[address].reason
end

function teamwise_server:is_banned_name(name)
    return self.banList.names[name] ~= nil
end

function teamwise_server:is_banned_address(address)
    return self.banList.addresses[address] ~= nil
end

function teamwise_server:ban_name(name, reason)
    if not self.banList.names[name] then
        self.banList.names[name] = { reason = reason }
    end
end

function teamwise_server:ban_address(address, reason)
    if not self.banList.addresses[address] then
        self.banList.addresses[address] = { reason = reason }
    end
end

function teamwise_server:unban_name(name)
    self.banList.names[name] = nil
end

function teamwise_server:unban_address(address)
    self.banList.addresses[address] = nil
end

function teamwise_server:add_name_to_white_list(name)
    if not table.has(self.whiteList.names, name) then
        table.insert(self.whiteList.names, name)
    end
end

function teamwise_server:add_address_to_white_list(address)
    if not table.has(self.whiteList.addresses, address) then
        table.insert(self.whiteList.addresses, address)
    end
end

function teamwise_server:is_name_in_white_list(name)
    return table.has(self.whiteList.names, name)
end

function teamwise_server:is_address_in_white_list(address)
    return table.has(self.whiteList.addresses, address)
end

function teamwise_server:remove_name_from_white_list(name)
    for i = 1, #self.whiteList.names do
        if self.whiteList.names[i] == name then table.remove(self.whiteList.names, i) break end
    end
end

function teamwise_server:remove_address_from_white_list(address)
    for i = 1, #self.whiteList.addresses do
        if self.whiteList.addresses[i] == address then table.remove(self.whiteList.addresses, i) break end
    end
end

function teamwise_server:get_server_file(subpath)
    return self.settings.serverDataDirectory..'/'..subpath
end

function teamwise_server:save_data(writer, path, property)
    writer(self:get_server_file(path), self[property]))
end

function teamwise_server:load_data(reader, path, property, def)
    local path = self:get_server_file(path)

    if file.exists(path) then self[property] = reader(path)
    else self[property] = def or { } end
end

function teamwise_server:save_player_data(name)
    if self.playersData.data[name] then
        local folder = self:get_server_file(constants.server.playersDataFolder)

        if not file.exists(folder) then file.mkdirs(folder) end

        file.write_bytes(
            self:get_server_file(folder..'/'..playerName..'.vcbjson'),
            bjson.tobytes(self.playersData.data[name])
        )
    end
end

function teamwise_server:save_players_data()
    local folder = self:get_server_file(constants.server.playersDataFolder)

    if not file.exists(folder) then file.mkdirs(folder) end

    for playerName, playerData in pairs(self.playersData.data) do
        self:save_player_data(name)
    end
end

function teamwise_server:load_players_data()
    local folder = self:get_server_file(constants.server.playersDataFolder)

    if file.exists(folder) then
        for _, playerDataFile in ipairs(file.list(folder)) do
            local playerName = playerDataFile:match("([^/\\]+)%.%w+$")

            self.playersData.data[playerName] = bjson.frombytes(file.read_bytes(playerDataFile))
        end
    end
end

function teamwise_server:get_client_id_by_nickname(nickname)
    for _, clientId in ipairs(self.server:get_all_clients_ids()) do
        if self:get_nickname(clientId) == nickname then return clientId end
    end
end

function teamwise_server:get_nickname(clientId)
    return player.get_name(player_compat.get_player_id(clientId))
end

function teamwise_server:destroy_handler(handler)
    self.handlers[handler.clientId] = nil
end

function teamwise_server:on_disconnected(server, clientId, cause)
    local name = self:get_nickname(clientId)

    self.handlers[clientId]:on_disconnected(cause)

    self:save_player_data(name)

    self.playersData:on_disconnected()

    self:destroy_handler(clientId)
end

function teamwise_server:update()
    self.server:update()

    for _, clientId in ipairs(self.server:get_all_clients_ids()) do
        self.handlers[clientId]:update()
    end
end

function teamwise_server:ban_by_name(name)
    table.insert(self.banListFile, { type = "name", name = name })
end

function teamwise_server:ban_by_address(address)
    table.insert(self.banListFile, { type = "address", address = address })
end

function teamwise_server:load_all_data()
    self:load_data(bjsonReader, constants.server.globalDataFile, "globalData")

    self:load_data(jsonReader, constants.server.banListFile, "banList",
        {
            names = { },
            addresses = { }
        }
    )

    self:load_data(jsonReader, constants.server.whiteListFile, "whiteList",
        {
            names = { },
            addresses = { }
        }
    )

    self:load_players_data()
end

function teamwise_server:save_all_data()
    self:save_data(bjsonWriter, constants.server.globalDataFile, "globalData")
    self:save_data(jsonWriter, constants.server.banListFile, "banList")
    self:save_data(jsonWriter, constants.server.whiteListFile, "whiteList")
    self:save_players_data()
end

function teamwise_server:close()
    self:save_all_data()
    self.server:close()
end

return teamwise_server