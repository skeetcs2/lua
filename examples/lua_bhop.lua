-- Replace only the built-in bhop while this checkbox is enabled.
local enabled = ui.create("checkbox", "lua_bhop_enabled", "Lua bhop", false)

events.on("create_move", function()
    if ui.get(enabled) then movement.claim("bhop") end
end)

events.on("post_move", function()
    if not ui.get(enabled) or not client.key_down(0x20) then return end
    local state = movement.context()
    cmd.set_button(buttons.jump, state.on_ground)
end)
