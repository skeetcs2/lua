-- Read-only ragebot dashboard. It never modifies aim, settings or commands.
-- Rage shots come from native ragebot shot IDs; misses mean no hurt event
-- matched the confirmed shot within the API timeout.
local enabled = ui.create("checkbox", "rage_info_enabled", "Ragebot info window", true)
local text_size = ui.create("slider", "rage_info_text_size", "Text size", 16, 12, 24)
local nearby_range = ui.create("slider", "rage_info_nearby_range", "Nearby range (units)", 1200, 300, 3000)
local reset_each_round = ui.create("checkbox", "rage_info_round_reset", "Reset stats each round", false)
local accent = ui.create("color", "rage_info_accent", "Accent color", {130, 210, 255, 255})

local weapon_groups = {[1] = "pistol", [2] = "smg", [3] = "rifle",
    [4] = "shotgun", [5] = "sniper", [6] = "lmg"}
local x = storage.get("rage_info_x", 54)
local y = storage.get("rage_info_y", 115)
local dragging, grab_x, grab_y = false, 0, 0
local font, loaded_size = nil, nil
local combat_info, last_sample = nil, -100
local kills, deaths, commands, shots = 0, 0, 0, 0
local hits, misses, unconfirmed, hurt_events = 0, 0, 0, 0
local tracked = {}
local last_shot = nil

local function reset_stats()
    kills, deaths, commands, shots = 0, 0, 0, 0
    hits, misses, unconfirmed, hurt_events = 0, 0, 0, 0
    tracked = {}
    last_shot = nil
end

events.on("rage_shot", function(shot)
    local status, id = shot.status, shot.id
    last_shot = {id = id, status = status, target = shot.target_id,
        hitbox = shot.hitbox, damage = shot.expected_damage}
    if status == "command" then
        tracked[id] = "command"
        commands = commands + 1
    elseif status == "fired" and tracked[id] == "command" then
        tracked[id] = "fired"
        shots = shots + 1
    elseif tracked[id] and (status == "hit" or status == "miss" or status == "unconfirmed") then
        if status == "hit" then hits = hits + 1
        elseif status == "miss" then misses = misses + 1
        else unconfirmed = unconfirmed + 1 end
        tracked[id] = nil
    end
end)

events.on("game_event", function(event)
    if event.name == "round_start" then
        if ui.get(reset_each_round) then reset_stats() end
    elseif event.name == "player_hurt" and event.attacker == 0
        and event.userid ~= nil and event.userid ~= 0 then
        hurt_events = hurt_events + 1
    elseif event.name == "player_death" then
        if event.userid == 0 then deaths = deaths + 1 end
        if event.attacker == 0 and event.userid ~= nil and event.userid ~= 0 then
            kills = kills + 1
        end
    end
end)

events.on("post_rage", function()
    local now = client.time()
    if now - last_sample < 0.15 then return end
    last_sample = now
    combat_info = combat.context()
    if combat_info and combat_info.valid then
        combat_info.can_shoot = combat.can_shoot()
    end
end)

local function yes_no(value)
    return value and "ON" or "OFF"
end

local function number_or_dash(value)
    if type(value) ~= "number" then return "-" end
    return tostring(math.floor(value + 0.5))
end

events.on("paint", function()
    if not ui.get(enabled) then dragging = false; return end

    -- Only four font sizes may be loaded, staying within the session font cap.
    local size = math.floor((ui.get(text_size) + 2) / 4) * 4
    if size ~= loaded_size then
        loaded_size = size
        font = render.setup_font("Excalifont-Regular.ttf", size)
    end

    local me = entity.local_player()
    local enemies = entity.players(true) -- Native API returns living enemies only.
    local nearby, nearest = 0, nil
    if me and me.origin then
        local radius = ui.get(nearby_range)
        for _, enemy in ipairs(enemies) do
            local p = enemy.origin
            if p then
                local dx, dy, dz = p.x - me.origin.x, p.y - me.origin.y, p.z - me.origin.z
                local d2 = dx * dx + dy * dy + dz * dz
                if d2 <= radius * radius then nearby = nearby + 1 end
                if not nearest or d2 < nearest then nearest = d2 end
            end
        end
    end

    local rage_on = settings.get("ragebot", "enabled")
    local group = me and me.alive and combat_info and combat_info.valid
        and weapon_groups[combat_info.weapon_type] or nil
    local config = group and "ragebot - " .. group or nil
    local hc = config and settings.get(config, "hit chance") or nil
    local min_damage = config and settings.get(config, "min damage") or nil
    local max_fov = config and settings.get(config, "max fov") or nil
    local head_scale = config and settings.get(config, "head scale") or nil
    local body_scale = config and settings.get(config, "body scale") or nil
    local weapon = me and entity.weapon(me.id) or nil
    local unresolved = 0
    for _ in pairs(tracked) do unresolved = unresolved + 1 end
    local accuracy = shots > 0 and math.floor(hits * 100 / shots + 0.5) or 0
    local fps = client.frametime() > 0 and math.floor(1 / client.frametime() + 0.5) or 0
    local info = me and me.alive and combat_info and combat_info.valid and combat_info or nil
    local lines = {
        "RAGE: " .. yes_no(rage_on) .. "  |  GROUP: " .. (group or "-"),
        "HEALTH: " .. number_or_dash(me and me.health) ..
            "  |  ARMOR: " .. number_or_dash(me and me.armor),
        "WEAPON ID: " .. number_or_dash(weapon and weapon.item_id) ..
            "  |  AMMO: " .. number_or_dash(weapon and weapon.ammo),
        "ENEMIES ALIVE: " .. #enemies,
        "ENEMIES NEAR " .. ui.get(nearby_range) .. "u: " .. nearby,
        "NEAREST ENEMY: " .. (nearest and (math.floor(math.sqrt(nearest)) .. "u") or "-"),
        "KILLS: " .. kills .. "  |  DEATHS: " .. deaths,
        "COMMANDS: " .. commands .. "  |  FIRED: " .. shots,
        "HITS: " .. hits .. "  |  MISSES*: " .. misses,
        "UNCONFIRMED: " .. unconfirmed .. "  |  PENDING: " .. unresolved,
        "LAST SHOT: " .. (last_shot and ("#" .. last_shot.id .. " " .. last_shot.status) or "-"),
        "TARGET / HITBOX / EST DMG: " .. (last_shot and
            (last_shot.target .. " / " .. last_shot.hitbox .. " / " ..
                number_or_dash(last_shot.damage)) or "-"),
        "HURT EVENTS: " .. hurt_events .. "  |  HIT RATE: " .. accuracy .. "%",
        "HITCHANCE: " .. number_or_dash(hc) ..
            "  |  MIN DAMAGE: " .. number_or_dash(min_damage),
        "MAX FOV: " .. number_or_dash(max_fov) ..
            "  |  HEAD/BODY: " .. number_or_dash(head_scale) .. "/" .. number_or_dash(body_scale),
        "NO SPREAD: " .. yes_no(settings.get("ragebot", "no spread")) ..
            "  |  AUTO SCOPE: " .. yes_no(settings.get("ragebot", "auto scope")),
        "CAN SHOOT: " .. (info and yes_no(info.can_shoot) or "-"),
        "SPREAD: " .. (info and string.format("%.4f", info.spread) or "-") ..
            "  |  INACCURACY: " .. (info and string.format("%.4f", info.inaccuracy) or "-"),
        "SCOPED: " .. (info and yes_no(info.scoped) or "-") ..
            "  |  RANGE: " .. number_or_dash(info and info.range),
        "TICK: " .. number_or_dash(info and info.tick) .. "  |  FPS: " .. fps,
    }

    local pad, header, row_h = 12, 34, size + 5
    local width = 280
    for _, line in ipairs(lines) do
        local measured = render.measure_text(line, font)
        if measured + pad * 2 > width then width = measured + pad * 2 end
    end
    local height = header + pad * 2 + row_h * #lines
    local screen_w, screen_h = render.screen_size()
    width = math.min(width, screen_w)
    x = math.max(0, math.min(x, math.max(0, screen_w - width)))
    y = math.max(0, math.min(y, math.max(0, screen_h - height)))

    if ui.is_menu_opened() then
        local mouse = ui.mouse_state()
        if mouse.clicked and mouse.x >= x and mouse.x <= x + width
            and mouse.y >= y and mouse.y <= y + header then
            dragging = true
            grab_x, grab_y = mouse.x - x, mouse.y - y
        end
        if dragging then
            if mouse.down then
                x = math.max(0, math.min(screen_w - width, mouse.x - grab_x))
                y = math.max(0, math.min(screen_h - height, mouse.y - grab_y))
            else
                dragging = false
                storage.set("rage_info_x", x)
                storage.set("rage_info_y", y)
            end
        end
    elseif dragging then
        dragging = false
        storage.set("rage_info_x", x)
        storage.set("rage_info_y", y)
    end

    render.rect(x, y, width, height, {14, 19, 28, 228}, true)
    render.rect(x, y, width, height, {83, 96, 111, 255})
    render.rect(x, y, width, header, {28, 38, 53, 255}, true)
    render.rect(x, y + header - 2, width, 2, ui.get(accent), true)
    render.text(x + pad, y + 7, "RAGEBOT INFO", ui.get(accent), font)
    local row_y = y + header + pad
    for _, line in ipairs(lines) do
        render.text(x + pad, row_y, line, {235, 240, 247, 255}, font)
        row_y = row_y + row_h
    end
end)
