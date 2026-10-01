-- Set zero pitch while autopeek is active.
local enabled = ui.create("checkbox", "aa_zero_peek", "Zero pitch on autopeek", false)

events.on("finalize_command", function()
    if not ui.get(enabled) or
       not settings.get("peek assistance", "quick peek") or
       not settings.get("peek assistance", "autopeek activate") then return end
    local me = entity.local_player()
    if not me or not me.alive then return end
    local angles = cmd.get().angles
    cmd.set_angles({x = 0, y = angles.y, z = 0})
end)
