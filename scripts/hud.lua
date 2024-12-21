local base_commands = require "server/base_commands"

function on_hud_open()
	base_commands.add_commands()
end