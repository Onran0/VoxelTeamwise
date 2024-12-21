local compat_core = require "content_compat/compat_core"

local _block = compat_core.copy_library("block")

local block_compat = { }

local callbacks

function block_compat.set_callbacks(_callbacks)
	callbacks = _callbacks
end

local function callback(name, ...)
	callbacks[name](callbacks, ...)
end

function block.set(x, y, z, id, states, noupdate)
	callback("block_changed", x, y, z, id, states, noupdate)

	_block.set(x, y, z, id, states, noupdate)
end

function block.set_states(x, y, z, states)
	callback("block_states_changed", x, y, z, states)

	_block.set_states(x, y, z, states)
end

function block.set_field(x, y, z, name, value, index)
	callback("block_field_changed", x, y, z, name, value, index)

	_block.set_field(x, y, z, name, value, index)
end

function block.set_rotation(x, y, z, rotation)
	callback("block_rotation_changed", x, y, z, rotation)

	_block.set_rotation(x, y, z, rotation)
end

function block.place(x, y, z, id, states, playerId)
	callback("block_changed_by_player", x, y, z, id, states, playerId)

	_block.place(x, y, z, id, states, playerId)
end

function block.destruct(x, y, z, playerId)
	callback("block_changed_by_player", x, y, z, 0, 0, playerId)

	_block.destruct(x, y, z, playerId)
end

return block_compat