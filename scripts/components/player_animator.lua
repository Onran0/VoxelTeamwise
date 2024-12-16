local math_util = require "util/math_util"
local player_compat = require "content_compat/player_compat"

local tsf = entity.transform
local body = entity.rigidbody
local rig = entity.skeleton

local itemid = 0
local prevBodyAngle = 0
local prevHeadAngle = 0

local headIndex = rig:index("head")
local itemIndex = rig:index("item")

local cid, pid = ARGS and ARGS[1] or -1

local function refresh_item_model(id)
    itemid = id
    rig:set_model(itemIndex, item.model_name(itemid))
    rig:set_matrix(itemIndex, mat4.rotate({0, 1, 0}, -80))
end

local function refresh_velocity(destPos)
    body:set_vel(math_util.lerp_vectors(tsf:get_pos(), destPos))
end

local function refresh_rotations(head, body)
    body = math_util.lerp_number(prevBodyAngle, body, 0.2)

    tsf:set_rot(mat4.rotate({0, 1, 0}, body))
    
    prevBodyAngle = body


    head = math_util.lerp_number(prevHeadAngle, head, 0.2)

    rig:set_matrix(headIndex, mat4.rotate({1, 0, 0}, head)) 
    
    prevHeadAngle = head
end

function on_render()
    if cid == -1 then
        entity:despawn()
        return
    elseif not pid then
        pid = player_compat.get_player_id(cid)
    end

    local id = player_compat.get_item_in_hands(pid)

    if id ~= itemid then
        refresh_item_model(id)
    end

    local pos, rot = player.get_pos(pid), player.get_rot(pid)

    refresh_velocity(pos)
    refresh_rotations(rot)
end