-- Animate the native enemy glow color. The script enables enemy glow only
-- while its checkbox is on and releases both overrides when turned off.
local enabled = ui.create("checkbox", "rgb_glow_enabled", "RGB enemy glow", false)
local speed = ui.create("slider", "rgb_glow_speed", "RGB speed", 1, 0.1, 5)
local applied = false

local function color(time)
    local phase = time * ui.get(speed)
    local function channel(offset)
        return math.floor(127.5 + 127.5 * math.sin(phase + offset))
    end
    return {channel(0), channel(2 * math.pi / 3), channel(4 * math.pi / 3), 90}
end

local function release()
    if not applied then return end
    settings.override("glow enemy", "glow", nil)
    settings.override("glow enemy", "color", nil)
    applied = false
end

events.on("paint", function()
    if not ui.get(enabled) then release(); return end
    settings.override("glow enemy", "glow", true)
    settings.override("glow enemy", "color", color(client.time()))
    applied = true
end)

events.on("shutdown", release)
