local voxel_teamwise = require "voxel_teamwise"
local commands_api = require "server/api/commands_api"

local base_commands = { }

local teamwiseServer

function base_commands.add_commands()
	console.add_command(
		"players-list",
		"Shows a list of connected players",
		function(args)
			local teamwiseServer = voxel_teamwise:get_server()

			local clients = teamwiseServer.server:get_all_clients_ids()

		    if #clients > 0 then
		    	local text = "Connected players: "

		    	for i = 1, #clients do
		    		text = text..teamwiseServer:get_nickname(clients[i])..", "
		    	end

		    	text = text:sub(1, #text - 2)

		    	return text
		    else return "There are no players connected to the server" end
		end
	)

 	-----									Operator commands						-----

	-- Commands for issuing/removing operator status

	console.add_command(
		"kick nickname:str reason:str",
		"Kicks a player from the server",
		commands_api.wrap_operator_command(
			function(args)
				local teamwiseServer = voxel_teamwise:get_server()

				local cid = teamwiseServer:get_client_id_by_nickname(args[1])

				if not cid then
					return "player with nickname '"..args[1].."' is not connected to the server at the moment"
				end

				teamwiseServer.handlers[cid]:kick(args[2])

				return "player with the nickname '"..args[1].."' was successfully kicked from the server for the following reason: "..args[2]
			end
		)
	)

	console.add_command(
		"op nickname:str",
		"Assigns operator status to the player",
		commands_api.wrap_operator_command(
			function(args)
				local teamwiseServer = voxel_teamwise:get_server()

				if teamwiseServer.opsManager:is_operator(args[1]) then
					return "player with nickname '"..args[1].."' already has operator status"
				end

				teamwiseServer.opsManager:assign_operator_status(args[1])

				return "player with the nickname '"..args[1].."' has been successfully assigned the operator status"
			end
		)
	)

	console.add_command(
		"deop nickname:str",
		"Removes the operator status from the player",
		commands_api.wrap_operator_command(
			function(args)
				local teamwiseServer = voxel_teamwise:get_server()

				if not teamwiseServer.opsManager:is_operator(args[1]) then
					return "player with nickname '"..args[1].."' does not have operator status"
				end

				teamwiseServer.opsManager:remove_operator_status(args[1])

				return "operator status was successfully removed from the player with the nickname '"..args[1].."'"
			end
		)
	)

	-- Whitelist Commands

	console.add_command(
		"whitelist-add nickname:str",
		"Adds a player by nickname to the whitelist",
		commands_api.wrap_operator_command(
			function(args)
				local teamwiseServer = voxel_teamwise:get_server()

				if teamwiseServer.whitelistManager:has_name(args[1]) then
					return "player with nickname '"..args[1].."' is already in the whitelist"
				end

				teamwiseServer.whitelistManager:add_name(args[1])

				return "player with nickname '"..args[1].."' was successfully added to the whitelist"
			end
		)
	)

	console.add_command(
		"whitelist-add-ip ip:str",
		"Adds a player by IP to the whitelist",
		commands_api.wrap_operator_command(
			function(args)
				local teamwiseServer = voxel_teamwise:get_server()

				if teamwiseServer.whitelistManager:has_address(args[1]) then
					return "IP address "..args[1].." is already in the whitelist"
				end

				teamwiseServer.whitelistManager:add_address(args[1])

				return "IP address "..args[1].." was successfully added to the whitelist"
			end
		)
	)

	console.add_command(
		"whitelist-remove nickname:str",
		"Removes a player from the whitelist by nickname",
		commands_api.wrap_operator_command(
			function(args)
				local teamwiseServer = voxel_teamwise:get_server()

				if not teamwiseServer.whitelistManager:has_name(args[1]) then
					return "player with nickname '"..args[1].."' is not in the whitelist"
				end

				teamwiseServer.whitelistManager:remove_name(args[1])

				return "player with nickname '"..args[1].."' was successfully removed from the whitelist"
			end
		)
	)

	console.add_command(
		"whitelist-remove-ip ip:str",
		"Removes a player from the whitelist by IP",
		commands_api.wrap_operator_command(
			function(args)
				local teamwiseServer = voxel_teamwise:get_server()

				if not teamwiseServer.whitelistManager:has_address(args[1]) then
					return "IP address "..args[1].." is not in the whitelist"
				end

				teamwiseServer.whitelistManager:remove_address(args[1])

				return "IP address "..args[1].." was successfully removed from the whitelist"
			end
		)
	)

	-- Ban and Unban

	console.add_command(
		"ban nickname:str reason:str",
		"Bans a player by nickname",
		commands_api.wrap_operator_command(
			function(args)
				local teamwiseServer = voxel_teamwise:get_server()

				if teamwiseServer.bansManager:is_banned_name(args[1]) then
					return "player with nickname '"..args[1].."' is already banned"
				end

				teamwiseServer.bansManager:ban_name(args[1], args[2])

				return "player with nickname '"..args[2].."' successfully banned for the following reason: "..args[2]
			end
		)
	)

	console.add_command(
		"ban-ip ip:str reason:str",
		"Bans a player by IP",
		commands_api.wrap_operator_command(
			function(args)
				local teamwiseServer = voxel_teamwise:get_server()

				if teamwiseServer.bansManager:is_banned_address(args[1]) then
					return "IP address "..args[1].." is already banned"
				end

				teamwiseServer.bansManager:ban_address(args[1], args[2])

				return "IP address "..args[1].." was successfully banned for the following reason: "..args[2]
			end
		)
	)

	local unbanNameFunction =
	commands_api.wrap_operator_command(
		function(args)
			local teamwiseServer = voxel_teamwise:get_server()

			if not teamwiseServer.bansManager:is_banned_name(args[1]) then
				return "player with nickname '"..args[1].."' is not banned"
			end

			teamwiseServer.bansManager:unban_name(args[1])

			return "player with nickname '"..args[1].."' was successfully unbanned"
		end
	)

	local unbanIPFunction =
	commands_api.wrap_operator_command(
		function(args)
			local teamwiseServer = voxel_teamwise:get_server()

			if not teamwiseServer.bansManager:is_banned_address(args[1]) then
				return "IP address "..args[1].." is not banned"
			end

			teamwiseServer.bansManager:unban_address(args[1])

			return "IP address "..args[1].." was successfully unbanned"
		end
	)

	local unbanNameDesc    = "Unbans a player by nickname"
	local unbanIPDesc      = "Unbans a player by IP"
	local unbanNameScheme  = " nickname:str"
	local unbanIPScheme    = " ip:str"

	console.add_command(
		"unban"..unbanNameScheme,
		unbanNameDesc,
		unbanNameFunction
	)

	console.add_command(
		"unban-ip"..unbanIPScheme,
		unbanIPDesc,
		unbanIPFunction
	)

	console.add_command(
		"pardon"..unbanNameScheme,
		unbanNameDesc,
		unbanNameFunction
	)

	console.add_command(
		"pardon-ip"..unbanIPScheme,
		unbanIPDesc,
		unbanIPFunction
	)
end

return base_commands