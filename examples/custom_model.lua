-- Local player model from CS2 game/csgo/characters/models/.
-- Reload this script after adding/removing models to refresh the dropdown.
local catalog = models.list()
local labels = {}
for _, entry in ipairs(catalog) do labels[#labels + 1] = entry.id end
if #labels == 0 then labels[1] = "No compiled models found" end

local enabled = ui.create("checkbox", "custom_model_enabled", "Custom player model", true)
local choice = ui.create("combo", "custom_model_choice", "Player model", 1, labels)
local last_id, last_status = nil, nil

print("Custom models found: " .. #catalog)
if #catalog == 0 then print("Put compiled .vmdl_c files under game/csgo/characters/models/") end

local function select_model()
    local entry = catalog[ui.get(choice)]
    if not ui.get(enabled) or not entry then
        if models.current() then models.clear() end
        last_id, last_status = nil, nil
        return nil
    end
    if entry.id ~= last_id then
        local path = models.set(entry.id)
        print("Model selected: " .. path)
        last_id, last_status = entry.id, nil
    end
    return entry
end

-- Select the first model as soon as Lua is enabled. The paint callback below
-- handles later changes made in the combo and persisted config values.
select_model()

events.on("paint", function()
    local entry = select_model()
    if not entry then return end
    local status, message = models.status()
    if ui.is_menu_opened() then
        local label = status == "ready" and "MODEL: file found" or
            status == "error" and ("MODEL ERROR: " .. (message or "unknown")) or
            "MODEL: idle"
        render.text(35, 70, label,
            status == "error" and {255, 110, 110, 255} or {180, 235, 190, 255})
    end
    if status ~= last_status then
        if status == "ready" then
            print("Model file found: " .. entry.path)
        elseif status == "error" then
            print("Model load failed: " .. (message or "unknown error"))
        end
        last_status = status
    end
end)

events.on("shutdown", function() models.clear() end)
