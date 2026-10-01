local enabled = ui.create("checkbox", "enabled", "Lua jump", false)
events.on("post_move", function()
    if not ui.get(enabled) or not client.key_down(0x20) then return end
    local me = entity.local_player()
    if me and me.alive then
        cmd.set_button(buttons.jump, (me.flags & 1) ~= 0)
    end
end)
