-- Animate the color of the built-in manual arrows.
-- Enable Manual Arrows and bind Manual Left/Right in the anti-aim menu.
local enabled = ui.create("checkbox", "rgb_manual_arrows_enabled", "RGB arrows", false)
local speed = ui.create("slider", "rgb_manual_arrows_speed", "RGB speed", 1, 0.1, 5)
local applied = false

local function release()
    if not applied then return end
    settings.override("anti aim", "manual arrow color", nil)
    applied = false
end

events.on("paint", function()
    if not ui.get(enabled) then release(); return end
    local phase = client.time() * ui.get(speed)
    local function channel(offset)
        return math.floor(127.5 + 127.5 * math.sin(phase + offset))
    end
    settings.override("anti aim", "manual arrow color",
        {channel(0), channel(2.0944), channel(4.1888), 255})
    applied = true
end)

events.on("shutdown", release)
