local PACK_ID = require("constants").packId

local voxel_teamwise = require "voxel_teamwise"

local compat_core = require "content_compat/compat_core"

local _console = compat_core.copy_library("console")

local console_compat = { }

function console.execute(prompt)
	local client = voxel_teamwise.get_client()

	if client then
		client.client:add_to_send_queue(PACK_ID..":packet_command", prompt)
	else
		return _console.execute(prompt)
	end
end

return console_compat