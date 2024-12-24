local constants = require "constants"
local content = require "util/content"

local login_handler = { }

function login_handler:new(handler)
	local obj = { }

    self.__index = self
    setmetatable(obj, self)

    self.clientHandler = handler
    self.teamwiseServer = handler.teamwiseServer
    self.server = handler.server
    self.clientId = handler.clientId
    self.playersData = handler.playersData
    self.identified = false
    self.contentMatches = false

	return obj
end

function login_handler:handle_handshake(packet)
    if self.clientHandler.loggedIn then
        self.clientHandler:kick("already logged in")
    elseif packet.protocolVersion > constants.protocolVersion then
        self.clientHandler:kick("outdated server")
    elseif packet.protocolVersion < constants.protocolVersion then
        self.clientHandler:kick("outdated client")
    elseif self.teamwiseServer:get_client_id_by_nickname(packet.nickname) then
        self.clientHandler:kick("a client with that name is already logged in")
    else
        local address = self.server:get_client_address(self.clientId)

        if self.teamwiseServer:is_banned_name(packet.nickname) then
            self.clientHandler:kick("banned for the following reason: "..self.teamwiseServer:get_ban_reason_by_name(packet.nickname))
        elseif self.teamwiseServer:is_banned_address(address) then
            self.clientHandler:kick("banned for the following reason: "..self.teamwiseServer:get_ban_reason_by_address(address))
        elseif
            self.teamwiseServer.settings.whiteListEnabled and
            not self.teamwiseServer:is_name_in_white_list(packet.nickname) and
            not self.teamwiseServer:is_address_in_white_list(address)
        then
            self.clientHandler:kick("you are not on the whitelist")
        else
        	self.identified = true

        	self.server:send_packet(self.clientId, PACK_ID..":packet_identified", self.clientId)
        end
    end
end

local function containsPackWithEqualVersion(contentList, pack)
	local id, version = pack.id, pack.version

	for i = 1, #contentList do
		local pack = contentList[i]

		if pack.id == id then
			if pack.version == version then
				return true, true
			else
				return true, false, pack.version
			end
		end
	end

	return false, false
end

local function putIncompatibleContent(sourceContentList, targetContentList, dest, targetMissingFieldName)
	for i = 1, #sourceContentList do
		local pack = sourceContentList[i]

		local hasPack, versionEqual, diffVersion = containsPackWithEqualVersion(targetContentList, pack)

		if hasPack then
			if not versionEqual then
				table.insert(dest,
					{
						id = pack.id,
						version = pack.version
					}
				)
			end
		else
			table.insert(dest,
				{
					id = pack.id,
					version = pack.version,
					[targetMissingFieldName] = true
				}
			)
		end
	end
end

function login_handler:handle_content_info(clientContent)
	if not self.identified then
		self.clientHandler:kick("identification first")
	else
		local serverContent = content.get_content_info()

		local isIncompatibleContent = false

		if #serverContent ~= #clientContent then
			isIncompatibleContent = true
		else
			for i = 1, #serverContent do
				local serverPackInfo, clientPackInfo = serverContent[i], clientContent[i]

				if
					serverPackInfo.id ~= clientPackInfo.id or
					serverPackInfo.version ~= clientPackInfo.version
				then
					isIncompatibleContent = true
					break
				end
			end
		end

		if isIncompatibleContent then
			local incompatibleContent = { }

			putIncompatibleContent(serverContent, clientContent, incompatibleContent, "missingOnClient")
			putIncompatibleContent(clientContent, serverContent, incompatibleContent, "missingOnServer")

		    self.server:send_packet(self.clientId, PACK_ID..":packet_incompatible_content", incompatibleContent)
		    self.server:close_connection(self.clientId, "incompatible content")
		else
			self.contentMatches = true

			self.server:send_packet(self.clientId, PACK_ID..":packet_indices_sync", content.get_indices())
		end
	end
end

function login_handler:on_indices_synced()
	if not self.identified then
		self.clientHandler:kick("identification first")
	elseif not self.contentMatches then
		self.clientHandler:kick("send content info first")
	else
	    self.clientHandler.loggedIn = true

	    local nickname = packet.nickname

	    self.teamwiseServer:load_player_data(nickname)

	    local position = self.playersData:get(nickname, "position", self.teamwiseServer.globalData.defaultSpawnpoint)
	    local rotation = self.playersData:get(nickname, "rotation", { 0, 0, 0 })
	    local inventory = self.playersData:get(nickname, "inventory", { })

	    player_compat.spawn_player(
	        self.clientId,
	        nickname,
	        position,
	        rotation,
	        inventory
	    )

	    local pid = self.clientHandler:get_player_id()

	    local selectedItemId = player_compat.get_selected_item_id(pid)

	    self.server:send_packet_to_all(PACK_ID..":packet_player_joined",
	        {
	            clientId = self.clientId,
	            nickname = packet.nickname,
	            position = position,
	            rotation = rotation,
	            selectedItemId = selectedItemId
	        }
	    )

	    local clients = self.server:get_all_clients_ids()

	    for i = 1, #clients do
	    	local clientId = clients[i]

	    	if self.clientId ~= clientId then
	    		local playerId = player_compat.get_player_id(clientId)

	    		self.server:send_packet(self.clientId, PACK_ID..":packet_player_joined",
	    			{
	    				clientId = clientId,
	    				nickname = player.get_name(playerId),
	    				position = { player.get_pos(playerId) },
	    				rotation = { player.get_rot(playerId) },
	    				selectedItemId = player_compat.get_selected_item_id(playerId)
	    			}
	    		)
	    	end
	    end

	    self.clientHandler:synchronize_inventory(inventory)

	    self.clientHandler:on_logged_in()
	end
end

return login_handler