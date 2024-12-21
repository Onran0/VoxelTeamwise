local player_compat = require "content_compat/player_compat"
local voxel_teamwise = require "voxel_teamwise"

local commands_api = { }

----------                       Internal Code                       ----------

local _console_log = console.log

local invokerPid, invokerCid, isInvokerOperator

local function argsToText(...)
	local text = ''

	local args = { ... }

	for i = 1, #args do
		local value = args[i]

		if not value then value = ''
		elseif type(value) ~= "string" then value = tostring(value) end

        if i ~= 1 then 
            text = text..' '..value
        else
            text = text..value
        end
	end

	return text
end

local function consoleLog(...)
	commands_api.chat_to_invoker(...)
end

function commands_api.set_invoker_player_id(_invokerPid)
	invokerPid = _invokerPid
	invokerCid = player_compat.get_client_id(invokerPid)
	isInvokerOperator = voxel_teamwise:get_server().opsManager:is_operator(player.get_name(invokerPid))
end

function commands_api.reset_invoker_info()
	invokerPid, invokerCid, isInvokerOperator = nil, nil, nil
end

function commands_api.override_console_functions()
	console.log = consoleLog
end

function commands_api.restore_console_functions()
	console.log = _console_log
end


----------                            API                            ----------

function commands_api.get_invoker_client_id()
	return invokerCid
end

function commands_api.get_invoker_player_id()
	return invokerPid
end

function commands_api.is_invoker_operator()
	return isInvokerOperator == true or command.is_invoker_server()
end

function commands_api.is_invoker_server()
	return invokerPid == nil
end

function commands_api.chat_to_invoker(...)
	voxel_teamwise:get_server().server:send_packet(invokerCid, PACK_ID..":packet_chat", argsToText(...))
end

function commands_api.chat_to_all(...)
	voxel_teamwise:get_server().server:send_packet_to_all(PACK_ID..":packet_chat", argsToText(...))
end

function commands_api.wrap_operator_command(func)
	return
	function(...)
		if commands_api.is_invoker_operator() then
			return command(...)
		else
			return "you must be an operator to use this command"
		end
	end
end

function commands_api.wrap_server_command(func)
	return
	function(...)
		if commands_api.is_invoker_server() then
			return command(...)
		else
			return "this command can only be used from the server"
		end
	end
end

return commands_api