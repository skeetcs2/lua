-- Put the full MP3 in %LOCALAPPDATA%/skeet/muzon.
local track = "Hotline Kavkaz (Confirmed Soundtrack) - Vakhtang Zimmer - Nano Lezginka.mp3"
local enabled = ui.create("checkbox", "nano_lezginka_enabled", "Nano Lezginka", true)
local volume = ui.create("slider", "nano_lezginka_volume", "Music volume", 50, 0, 100)
local attempted, playing, last_volume = false, false, -1
local pending_error

events.on("paint", function()
    if not ui.get(enabled) then
        if playing then audio.stop() end
        attempted, playing, last_volume, pending_error = false, false, -1, nil
        return
    end
    if not audio or not audio.play then
        if not attempted then client.log("Audio API unavailable; rebuild the client") end
        attempted = true
        return
    end
    local level = ui.get(volume)
    if not attempted then
        local error_text
        playing, error_text = audio.play(track, true)
        attempted = true
        if not playing then pending_error = "Nano Lezginka: " .. (error_text or "cannot play MP3") end
        return
    end
    if pending_error then
        client.log(pending_error)
        pending_error = nil
        return
    end
    if playing then
        if level ~= last_volume then
            if not audio.volume(level) then pending_error = "Nano Lezginka: volume control failed" end
            last_volume = level
        end
    end
end)

events.on("shutdown", function()
    if playing then audio.stop() end
end)
