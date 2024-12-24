local voxel_teamwise = require "voxel_teamwise"
local base_commands = require "server/base_commands"

function on_hud_open()
	base_commands.add_commands()

	console.add_command(
		"start-server port:int",
		"Launches Voxel Teamwise Server",
		function(args)
			local settings =
			{
				port = args[1]
			}

			voxel_teamwise.start_server(settings)

			return "voxel teamwise server successfully launched"
		end
	)

	console.add_command(
		"connect address:str port:int nickname:str",
		"Connects to the Voxel Teamwise server",
		function(args)
			local address, port, nickname = unpack(args)

			local settings =
			{
				port = port,
				nickname = nickname
			}

			voxel_teamwise.start_client(address, settings)

			return "client started"
		end
	)
end