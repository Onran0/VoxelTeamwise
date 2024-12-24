local constants = require "constants"

local PACK_ID = constants.packId

local inventory_struct = require "struct/inventory_struct"
local ping_handler = require "client/handling/ping_handler"
local server_packets_handler = require "client/handling/server_packets_handler"

local client_handler = { }

function client_handler:new(teamwiseClient)
    local obj = { }

    self.__index = self
    setmetatable(obj, self)

    self.teamwiseClient = teamwiseClient
    self.client = teamwiseClient.client
    self.commonDisconnect = false
    self.playersData = teamwiseClient.playersData
    self.packetsHandler = server_packets_handler:new(self)
    self.pingHandler = = ping_handler:new(self)

    return obj
end

function client_handler:handle_packet(packetId, packetData)
    if server_packets_handler.handlers[packetId] then
        server_packets_handler.handlers[packetId](packetData)
    end
end

function client_handler:get_player_id()
    return hud.get_player()
end

function client_handler:get_nickname()
    return player.get_name(self:get_player_id())
end

function client_handler:get_ping()
    return self.pingHandler:get_ping()
end

function client_handler:update()
	
end

function client_handler:tick()
	self.pingHandler:tick()

    self:synchronize_selected_slot()
    self:synchronize_inventory()
end

function client_handler:synchronize_selected_slot()
    local _, slotId = player.get_inventory(self:get_player_id())

    if self.oldSlotId ~= slotId then
        self.oldSlotId = slotId

        self.client:add_to_send_queue(PACK_ID..":packet_player_selected_slot_changed", slotId)
    end
end

function client_handler:synchronize_inventory()
    local inventory = self.playersData:get(self:get_nickname(), "inventory")

    if self.oldInventory ~= inventory then
        local changedSlots = inventory_struct.get_changed_slots(self.oldInventory, inventory)

        local inventoryId = player.get_inventory(self:get_player_id())

        self.client:add_to_send_queue(PACK_ID..":packet_player_inventory_changed",
            {
                inventoryId = inventoryId,
                changedSlots = changedSlots
            }
        )

        self.oldInventory = inventory
    end
end

function client_handler:synchronize_indices(serverIndices)
    file.write("world:indices.json", json.tostring(serverIndices))

    require("client/teamwise_client").save_connect_settings(self.teamwiseClient.address, self.teamwiseClient.settings)

    core.reopen_world()
end

function client_handler:on_logged_in() end

return client_handler