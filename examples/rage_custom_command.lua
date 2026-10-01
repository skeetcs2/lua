-- API v2 demonstration of command takeover. Off by default.
-- This implements its own basic visible aim/attack strategy, not native
-- backtrack, hide-shots, prediction, autostop or no-spread correction.
-- Disable conflicting legit/anti-aim features for an isolated test.
local enabled = ui.create("checkbox", "enabled", "Custom command strategy", false)
local minimum = ui.create("slider", "damage", "Minimum damage", 40, 1, 100)
local required = ui.create("slider", "chance", "Required probability", 70, 0, 100)
local maximum_fov = ui.create("slider", "fov", "Maximum FOV", 10, 1, 180)
local fire = ui.create("checkbox", "fire", "Request attack", false)

events.on("pre_rage", function()
    if not ui.get(enabled) then return end
    ragebot.claim_command()
    local ctx, me = combat.context(), entity.local_player()
    if not ctx.valid or not me or not me.alive then return end
    if not combat.can_shoot() then return end
    local view = cmd.get().angles
    local players = {}
    for _, player in ipairs(entity.players(true)) do
        local angles = math.calc_angle(ctx.eye, player.origin)
        local fov = math.calc_fov(view, angles)
        if fov <= ui.get(maximum_fov) then players[#players + 1] = {player = player, fov = fov} end
    end
    table.sort(players, function(a, b) return a.fov < b.fov end)
    local best, best_damage
    for i = 1, math.min(3, #players) do
        local id = players[i].player.id
        local snapshot = combat.hitboxes(id)
        if snapshot then
            for _, hb in ipairs(snapshot.hitboxes) do
                if hb.index == 0 or hb.index == 3 then
                    local hit = combat.damage(id, hb.center) -- Current pose, no backtrack commit.
                    if hit and hit.damage >= ui.get(minimum) then
                        local chance = combat.hitchance(id, hb.center, hb.index, snapshot.tick)
                        if chance and chance >= ui.get(required) and (not best_damage or hit.damage > best_damage) then
                            best, best_damage = hb.center, hit.damage
                        end
                    end
                end
            end
        end
    end
    if not best then return end
    local angle = math.calc_angle(ctx.eye, best)
    local punch = combat.aim_punch() or {x = 0, y = 0, z = 0}
    angle.x = math.max(-89, math.min(89, angle.x - punch.x))
    angle.y = math.normalize_angle(angle.y - punch.y)
    angle.z = 0
    cmd.set_angles(angle, true)
    if ui.get(fire) then cmd.set_button(buttons.attack, true) end
end)
