-- Independent first-person arms and weapon materials.
local arms = ui.create("checkbox", "flat_arms", "Flat hands", false)
local weapon = ui.create("checkbox", "flat_weapon", "Flat weapon", false)
local hue = ui.create("slider", "flat_weapon_speed", "Color speed", 1, 0.1, 5)
local arm_mat = chams.create_material(1.0, {255, 235, 200, 255})
local weapon_mat = chams.create_material(1.4, {180, 220, 255, 255})

local function clear()
    chams.set("arms", nil)
    chams.set("weapon", nil)
end

events.on("paint", function()
    if ui.get(arms) then
        chams.set("arms", arm_mat, {245, 185, 135, 235})
    else
        chams.set("arms", nil)
    end
    if ui.get(weapon) then
        local t = client.time() * ui.get(hue)
        local r = math.floor(120 + 110 * math.sin(t))
        local b = math.floor(120 + 110 * math.sin(t + 2.1))
        chams.set("weapon", weapon_mat, {r, 180, b, 235})
    else
        chams.set("weapon", nil)
    end
end)

events.on("shutdown", clear)
