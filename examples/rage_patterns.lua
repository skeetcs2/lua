-- API v2. Opt-in replacement of head/body/leg points. Native firing gates remain.
local enabled = ui.create("checkbox", "enabled", "Custom rage points", false)
local choices = {"Native", "Rings", "Spiral"}
local head = ui.create("combo", "head", "Head pattern", 2, choices)
local body = ui.create("combo", "body", "Body pattern", 1, choices)
local legs = ui.create("combo", "legs", "Leg pattern", 1, choices)
local head_scale = ui.create("slider", "head_scale", "Head scale", 85, 0, 100)
local body_scale = ui.create("slider", "body_scale", "Body scale", 65, 0, 100)
local leg_scale = ui.create("slider", "leg_scale", "Leg scale", 65, 0, 100)
local phase = ui.create("slider", "phase", "Pattern rotation", 0, -180, 180)
local ring_count = ui.create("slider", "rings", "Ring count", 3, 1, 8)
local cached, cached_key = {}, ""

local function region(index)
    if index == 0 then return 1 end
    if index >= 2 and index <= 6 then return 2 end
    if index >= 7 and index <= 12 then return 3 end
end

events.on("rage_scan", function(ctx)
    if not ui.get(enabled) then return end
    local modes = {ui.get(head), ui.get(body), ui.get(legs)}
    if modes[1] == 1 and modes[2] == 1 and modes[3] == 1 then return end
    local scales = {ui.get(head_scale), ui.get(body_scale), ui.get(leg_scale)}
    local rings = math.floor(ui.get(ring_count))
    local angle = math.rad(ui.get(phase))
    local key = tostring(rings) .. ":" .. tostring(angle)
    if key ~= cached_key then cached, cached_key = {}, key end
    local points = {}
    local function append(p)
        if #points < 128 then points[#points + 1] = p end
    end
    for _, p in ipairs(ctx.points) do
        local group = region(p.hitbox)
        if not group or modes[group] == 1 then append(p) end
    end
    for _, hb in ipairs(ctx.hitboxes) do
        local group = region(hb.index)
        if group and modes[group] ~= 1 then
            append({hitbox = hb.index, position = hb.center, center = true})
            local count = ctx.centers_only and 2 or ({16, 8, 4})[group]
            local kind = modes[group] == 2 and "rings" or "spiral"
            local pattern_key = kind .. tostring(count)
            if not cached[pattern_key] then
                cached[pattern_key] = ragebot.pattern(kind, count, rings, angle)
            end
            for _, p in ipairs(ragebot.multipoints(hb.index, cached[pattern_key], scales[group])) do
                append(p)
            end
        end
    end
    return {points = points}
end)
