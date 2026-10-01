-- API showcase: copy to the Lua folder, enable it, then use its controls.
-- HUD is on by default. Movement is opt-in.

local hud = ui.create("checkbox", "show_hud", "Show API dashboard", true)
local caption = ui.create("text", "caption", "Dashboard title", "LUA LAB")
local accent = ui.create("color", "accent", "Accent color", {110, 200, 255, 255})
local rainbow = ui.create("checkbox", "rainbow", "Animated accent", true)
local esp = ui.create("checkbox", "esp", "Enemy screen markers", false)
local probe = ui.create("checkbox", "probe", "Estimate head damage", false)
local movement = ui.create("checkbox", "movement", "Hold SHIFT: sway movement", false)
local sway = ui.create("slider", "sway", "Movement strength", 35, 0, 100)

local rounds = storage.get("showcase_rounds", 0)
local hits = storage.get("showcase_hits", 0)
local damage, last_probe = nil, -100

local function rgba(a)
    if not ui.get(rainbow) then
        local c = ui.get(accent)
        return {c[1], c[2], c[3], a}
    end
    local t = client.time() * 2
    local function ch(shift)
        return math.floor(130 + 125 * (0.5 + 0.5 * math.sin(t + shift)))
    end
    return {ch(0), ch(2.0944), ch(4.1888), a}
end

events.on("game_event", function(event)
    if event.name == "round_start" then
        rounds = rounds + 1
        storage.set("showcase_rounds", rounds)
        damage = nil
    elseif event.name == "player_hurt" then
        hits = hits + 1 -- All damage events, not necessarily damage dealt by you.
        storage.set("showcase_hits", hits)
    end
end)

events.on("pre_rage", function()
    if not ui.get(probe) or client.time() - last_probe < 0.4 then return end
    last_probe = client.time()
    damage = nil
    local context = combat.context()
    if not context or not context.valid then return end
    local enemies = entity.players(true)
    local target = enemies[1]
    if not target then return end
    local head = entity.bone(target.id, 7)
    if not head then return end
    local result = combat.damage(target.id, head)
    if result then damage = math.floor(result.damage) end
end)

events.on("post_move", function()
    if not ui.get(movement) or not client.key_down(0x10) then return end
    local me = entity.local_player()
    if me and me.alive then
        cmd.set_movement(0, math.sin(client.time() * 4) * ui.get(sway) / 100, 0)
    end
end)

events.on("paint", function()
    local now = client.time()
    if ui.get(hud) then
        local x, y, w, h = 28, 118, 285, 111
        render.rect_filled_fade(x, y, w, h,
            {15, 20, 31, 225}, {24, 31, 47, 225},
            {10, 13, 21, 225}, {17, 24, 34, 225})
        render.rect(x, y, w, h, rgba(240))
        render.rect(x + 1, y + 1, w - 2, 3, rgba(255))
        render.text(x + 12, y + 12, ui.get(caption), {245, 247, 255, 255})
        render.arc(x + w - 26, y + 23, 11, 0, now % 6.2832, rgba(255), 2)
        local me = entity.local_player()
        local hp = me and me.health or "-"
        local ammo = "-"
        if me then
            local weapon = entity.weapon(me.id)
            if weapon then ammo = weapon.ammo end
        end
        render.text(x + 12, y + 35, "HP: " .. hp .. "   Ammo: " .. ammo,
            {220, 230, 240, 255})
        render.text(x + 12, y + 55, "Rounds: " .. rounds .. "   Hurt events: " .. hits,
            {220, 230, 240, 255})
        render.text(x + 12, y + 75,
            "Head damage: " .. (damage and tostring(damage) or "-"),
            {220, 230, 240, 255})
        local pulse = math.floor((math.sin(now * 4) + 1) * 0.5 * (w - 24))
        render.rect(x + 12, y + 98, pulse, 2, rgba(220))
    end

    if ui.get(esp) then
        local enemies = entity.players(true)
        for i = 1, math.min(#enemies, 4) do
            local enemy = enemies[i]
            if enemy.alive and enemy.origin then
                local sx, sy = render.world_to_screen(enemy.origin)
                if sx then
                    render.arc(sx, sy, 8, 0, 6.2832, rgba(220), 2)
                    render.text(sx + 12, sy - 7, enemy.name or "enemy", rgba(255))
                end
            end
        end
    end
end)

client.log("API showcase ready; movement is disabled by default")
