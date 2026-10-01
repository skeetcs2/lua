-- A simple, replaceable air-strafer; tune the side choice in Lua.
local enabled = ui.create("checkbox", "lua_strafe_enabled", "Lua air strafe", false)

events.on("create_move", function()
    if ui.get(enabled) then movement.claim("strafe") end
end)

events.on("post_move", function()
    if not ui.get(enabled) then return end
    local state = movement.context()
    if state.on_ground or state.move_type == 7 or state.move_type == 9 then return end

    local velocity = state.velocity
    local speed = math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
    if speed < 1 then return end

    local view_yaw = cmd.get().angles.y
    local velocity_yaw = math.deg(math.atan(velocity.y, velocity.x))
    local delta = (view_yaw - velocity_yaw + 180) % 360 - 180
    cmd.set_movement(0, delta >= 0 and 1 or -1)
end)
