-- Animate the native quick-peek circle and its return/retrack color.
-- This changes colors only; it does not enable or activate autopeek.
local enabled = ui.create("checkbox", "rgb_autopeek_enabled", "RGB autopeek colors", false)
local speed = ui.create("slider", "rgb_autopeek_speed", "RGB speed", 1, 0.1, 5)
local applied = false

local function color(time, offset)
    local phase = time * ui.get(speed)
    local function channel(shift)
        return math.floor(127.5 + 127.5 * math.sin(phase + shift + offset))
    end
    return {channel(0), channel(2 * math.pi / 3), channel(4 * math.pi / 3), 255}
end

local function release()
    if not applied then return end
    settings.override("peek assistance", "quick peek color", nil)
    settings.override("peek assistance", "retracting color", nil)
    applied = false
end

events.on("paint", function()
    if not ui.get(enabled) then release(); return end
    local now = client.time()
    settings.override("peek assistance", "quick peek color", color(now, 0))
    settings.override("peek assistance", "retracting color", color(now, math.pi))
    applied = true
end)

events.on("shutdown", release)
