-- API v2. Replace native ranking, retaining native scanning and shot machinery.
local enabled = ui.create("checkbox", "enabled", "Custom rage selection", false)
local direct = ui.create("checkbox", "direct", "Prefer direct hits", true)
local body = ui.create("checkbox", "body", "Prefer lethal body hits", true)
local hold_fire = ui.create("checkbox", "hold_fire", "Observe only (cancel shots)", true)
local queries = 0
events.on("pre_rage", function() queries = 0 end)

events.on("rage_targets", function(ctx)
    if not ui.get(enabled) then return end
    local order = {}
    for i in ipairs(ctx.targets) do order[#order + 1] = i end
    table.sort(order, function(a, b)
        return ctx.targets[a].health < ctx.targets[b].health
    end)
    return {order = order}
end)

events.on("rage_select", function(ctx)
    if not ui.get(enabled) then return end
    if queries >= 24 then return end -- Leave room for other queries in this script.
    local order, scores = {}, {}
    for i, hit in ipairs(ctx.hits) do
        local score = hit.damage - hit.fov * 0.5
        if ui.get(direct) and not hit.penetrated then score = score + 40 end
        if ui.get(body) and hit.hitbox >= 1 and hit.hitbox <= 12 and hit.damage >= hit.health then
            score = score + 200
        end
        order[#order + 1], scores[i] = i, score
    end
    table.sort(order, function(a, b) return scores[a] > scores[b] end)
    local best, best_score = 0, -math.huge
    for rank = 1, math.min(4, #order, 24 - queries) do
        local index = order[rank]
        local chance = ragebot.hitchance(index)
        queries = queries + 1
        local score = scores[index] + chance
        if chance >= ctx.required_hitchance and score > best_score then
            best, best_score = index, score
        end
    end
    return {index = best}
end)

events.on("rage_fire", function()
    if ui.get(enabled) and ui.get(hold_fire) then return {cancel = true} end
end)
