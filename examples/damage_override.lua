local enabled = ui.create("checkbox", "enabled", "Rifle damage override", false)
local damage = ui.create("slider", "damage", "Minimum damage", 60, 1, 130)
events.on("pre_rage", function()
    if ui.get(enabled) then
        settings.override("ragebot - rifle", "min damage", math.floor(ui.get(damage)))
    else
        settings.override("ragebot - rifle", "min damage", nil)
    end
end)
-- The override is also released automatically on Disable/error.
