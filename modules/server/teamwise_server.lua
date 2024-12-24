local PACK_ID = require("constants").packId

local constants = require "constants"
local server = require "packet_api:server"
local client_handler = require "server/handling/client_handler"
local players_data = require "players_data"
local whitelist_manager = require "server/whitelist_manager"
local bans_manager = require "server/bans_manager"
local ops_manager = require "server/ops_manager"

local teamwise_server = { }

function teamwise_server:log(...)
    print("[voxel teamwise server]", ...)
end

function teamwise_server:is_running()
    return self.isRunning
end

function teamwise_server:get_server_file(subpath)
    return self.settings.serverDataDirectory..'/'..subpath
end

function teamwise_server:get_client_id_by_nickname(nickname)
    for _, clientId in ipairs(self.server:get_all_clients_ids()) do
        if self:get_nickname(clientId) == nickname then return clientId end
    end
end

function teamwise_server:get_nickname(clientId)
    return player.get_name(player_compat.get_player_id(clientId))
end

function teamwise_server:close_server()
    self:save_all_data()
    self.isRunning = false
    self.server:close_server()
    require("voxel_teamwise").close_server()
end

function teamwise_server:update()
    self.server:update()

    for _, clientId in ipairs(self.server:get_all_clients_ids()) do
        self.handlers[clientId]:update()
    end
end

function teamwise_server:tick()
    for _, clientId in ipairs(self.server:get_all_clients_ids()) do
        self.handlers[clientId]:tick()
    end
end

function teamwise_server:send_packet_to_all_except(packetId, packetData, except)
    for _, clientId in ipairs(self.server:get_all_clients_ids()) do
        if not table.has(except, clientId) then self.server:send_packet(clientId, packetId, packetData) end
    end
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

    for playerName, _ in pairs(self.playersData.data) do
        self:save_player_data(playerName)
    end
end

function teamwise_server:load_player_data(name)
    local folder = self:get_server_file(constants.server.playersDataFolder)

    if file.exists(folder) then
        local path = self:get_server_file(folder..'/'..name..'.vcbjson')

        if file.exists(path) then
            self.playersData.data[playerName] = bjson.frombytes(file.read_bytes(path))
        end
    end
end

function teamwise_server:load_all_data()
    local globalDataPath = self:get_server_file(constants.server.globalDataFile)

    self.globalData = file.exists(globalDataPath) and bjson.frombytes(file.read_bytes(globalDataPath)) or { }

    self.whitelistManager:load_data(self:get_server_file(constants.server.whiteListFile))
    self.bansManager:load_data(self:get_server_file(constants.server.banListFile))
    self.opsManager:load_data(self:get_server_file(constants.server.opsListFile))
end

function teamwise_server:save_all_data()
    file.write_bytes(self:get_server_file(constants.server.globalDataFile), bjson.tobytes(self.globalData))

    self.whitelistManager:save_data(self:get_server_file(constants.server.whiteListFile))
    self.bansManager:save_data(self:get_server_file(constants.server.banListFile))
    self.opsManager:save_data(self:get_server_file(constants.server.opsListFile))

    self:save_players_data()
end

function teamwise_server:on_disconnected(server, clientId, cause)
    local name = self:get_nickname(clientId)

    self.handlers[clientId]:on_disconnected(cause)

    self:save_player_data(name)

    self.playersData:on_disconnected(name)

     self.handlers[clientId] = nil
end

function teamwise_server:on_connected(server, clientId)
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

function teamwise_server:start(settings)
    local obj = { }

    self.__index = self
    setmetatable(obj, self)

    self.playersData = players_data:new()
    self.whitelistManager = whitelist_manager:new(self)
    self.bansManager = bans_manager:new(self)
    self.opsManager = ops_manager:new(self)

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

    sself.isRunning = true

    return obj
end

return teamwise_server