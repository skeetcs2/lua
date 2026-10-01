-- Animate native enemy chams, including the invisible layer when requested.
local enabled = ui.create("checkbox", "rgb_chams_enabled", "RGB enemy chams", false)
local invisible = ui.create("checkbox", "rgb_chams_invisible", "Include invisible layer", false)
local speed = ui.create("slider", "rgb_chams_speed", "RGB speed", 1, 0.1, 5)
local applied = false

local function release()
    if not applied then return end
    settings.override("chams enemy", "chams", nil)
    settings.override("chams enemy", "primary color", nil)
    settings.override("chams enemy invisible", "chams", nil)
    settings.override("chams enemy invisible", "primary color", nil)
    applied = false
end

events.on("paint", function()
    if not ui.get(enabled) then release(); return end
    local phase = client.time() * ui.get(speed)
    local function channel(offset)
        return math.floor(127.5 + 127.5 * math.sin(phase + offset))
    end
    local color = {channel(0), channel(2.0944), channel(4.1888), 180}
    settings.override("chams enemy", "chams", true)
    settings.override("chams enemy", "primary color", color)
    settings.override("chams enemy invisible", "chams", ui.get(invisible))
    settings.override("chams enemy invisible", "primary color", color)
    applied = true
end)

events.on("shutdown", release)
