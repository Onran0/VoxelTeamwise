local voxel_teamwise = require "voxel_teamwise"

local commands_api = { }

local invokerPid, isInvokerOperator

function commands_api.get_invoker_player_id()
	return invokerId
end

function commands_api.is_invoker_operator()
	return isInvokerOperator == true
end

function commands_api.set_invoker_player_id(_invokerPid)
	invokerPid = _invokerPid
	isInvokerOperator = voxel_teamwise:get_server():is_operator(player.get_name(invokerPid))
end

function commands_api.reset_invoker_info()
	invokerPid, isInvokerOperator = false, false
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

return commands_api