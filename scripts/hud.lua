local voxel_teamwise = require "voxel_teamwise"
local base_commands = require "server/base_commands"

function on_hud_open()
	base_commands.add_commands()

	console.add_command(
		"start-server port:int",
		"Launches Voxel Teamwise Server",
		function(args)
			local port = args[1]

			local settings =
			{
				port = port
			}

			voxel_teamwise.start_server(settings)

			return "voxel teamwise server successfully launched"
		end
	)
end