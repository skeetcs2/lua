-- Movement-aware anti-aim yaw patterns. Enable the built-in anti-aim first.
local enabled = ui.create("checkbox", "aa_profiles", "AA: movement profiles", false)
local mode = ui.create("combo", "aa_mode", "Yaw pattern", 1,
    {"Sine", "Static", "Triangle", "Step jitter", "Spin", "Random pulse"})
local standing = ui.create("slider", "aa_standing", "Standing yaw", 35, -180, 180)
local moving = ui.create("slider", "aa_moving", "Moving yaw", 15, -180, 180)
local airborne = ui.create("slider", "aa_airborne", "Airborne yaw", 75, -180, 180)
local crouching = ui.create("slider", "aa_crouching", "Crouching yaw", -35, -180, 180)
local sway = ui.create("slider", "aa_sway", "Pattern range", 18, 0, 180)
local speed = ui.create("slider", "aa_speed", "Pattern speed", 2, 0.1, 10)

local last_random_step, random_offset = -1, 0

local function release_aa()
    settings.override("anti aim", "rotation", nil)
end

local function yaw_offset(t, pattern, amount, rate)
    local phase = t * rate
    if pattern == 2 then return 0 end -- Static
    if pattern == 1 then return math.sin(phase) * amount end
    if pattern == 3 then -- Triangle wave
        local fraction = (phase / (2 * math.pi)) % 1
        return (1 - 4 * math.abs(fraction - 0.5)) * amount
    end
    if pattern == 4 then -- Alternating left/right
        return (math.floor(phase) % 2 == 0 and -1 or 1) * amount
    end
    if pattern == 5 then -- Full rotation
        return ((phase * 60) % 360 - 180) * amount / 180
    end
    -- Random pulse: one new value per step, not on every frame.
    local step = math.floor(phase)
    if step ~= last_random_step then
        last_random_step = step
        random_offset = (math.random() * 2 - 1) * amount
    end
    return random_offset
end

events.on("create_move", function()
    local me = entity.local_player()
    if not ui.get(enabled) or not me or not me.alive or
       not settings.get("anti aim", "anti aim") then
        release_aa()
        return
    end

    local base
    if (me.flags & 1) == 0 then
        base = ui.get(airborne)
    elseif (me.flags & 2) ~= 0 then
        base = ui.get(crouching)
    else
        local v = me.velocity
        local horizontal_speed = math.sqrt(v.x * v.x + v.y * v.y)
        base = horizontal_speed > 20 and ui.get(moving) or ui.get(standing)
    end

    local offset = yaw_offset(client.time(), ui.get(mode), ui.get(sway), ui.get(speed))
    settings.override("anti aim", "rotation", base + offset)
end)

events.on("shutdown", release_aa)
