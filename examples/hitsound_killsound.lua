-- Put hitsound.mp3 in %LOCALAPPDATA%/skeet/sounds.
-- Both hit and kill use the same local file. A kill takes priority over its hit.
local hit_enabled = ui.create("checkbox", "hitsound_enabled", "Hitsound", false)
local kill_enabled = ui.create("checkbox", "killsound_enabled", "Killsound", false)
local volume = ui.create("slider", "hitkill_volume", "Sound volume", 70, 0, 100)

local sound = "sounds/hitsound.mp3"
local pending_hit_at = nil
local warned_missing = false

local function play()
    local ok, reason = audio.play(sound, false)
    if ok then
        audio.volume(ui.get(volume))
        warned_missing = false
    elseif not warned_missing then
        client.log("Hit/kill sound: " .. (reason or "cannot play sounds/hitsound.mp3"))
        warned_missing = true
    end
end

events.on("game_event", function(event)
    if event.attacker ~= 0 or event.userid == nil or event.userid == 0 then return end
    if event.name == "player_death" then
        pending_hit_at = nil
        if ui.get(kill_enabled) then play() end
    elseif event.name == "player_hurt" and ui.get(hit_enabled) then
        -- Wait briefly: a lethal hit also produces player_death.
        pending_hit_at = client.time() + 0.08
    end
end)

events.on("paint", function()
    if pending_hit_at and client.time() >= pending_hit_at then
        pending_hit_at = nil
        if ui.get(hit_enabled) then play() end
    end
end)

events.on("shutdown", function()
    pending_hit_at = nil
    audio.stop()
end)
