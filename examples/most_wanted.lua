-- Track: %LOCALAPPDATA%/skeet/muzon; font: %LOCALAPPDATA%/skeet/fonts.
local track = "Nine_Thou_Grant_Mohrman_Superstars_Remix_Game_Version_Clean.mp3"
local enabled = ui.create("checkbox", "most_wanted_enabled", "Most Wanted", true)
local volume = ui.create("slider", "most_wanted_volume", "Music volume", 50, 0, 100)

local attempted, playing, last_volume = false, false, -1
local font, font_attempted
local pending_error

local function release_font()
    render.builtin_font("esp", nil)
    render.builtin_font("keybinds", nil)
    render.builtin_font("watermark", nil)
end

events.on("paint", function()
    if not ui.get(enabled) then
        if playing then audio.stop() end
        attempted, playing, last_volume, pending_error = false, false, -1, nil
        release_font()
        return
    end

    if not font_attempted then
        font = render.setup_font("fonts/nfsmw.ttf", 14)
        font_attempted = true
        if not font then client.log("Most Wanted: fonts/nfsmw.ttf not found or invalid") end
    end
    if font then
        render.builtin_font("esp", font)
        render.builtin_font("keybinds", font)
        render.builtin_font("watermark", font)
    else
        release_font()
    end

    if not attempted then
        local error_text
        playing, error_text = audio.play(track, true)
        attempted = true
        if not playing then pending_error = "Most Wanted: " .. (error_text or "cannot play MP3") end
        return
    end
    if pending_error then client.log(pending_error); pending_error = nil end
    if playing and ui.get(volume) ~= last_volume then
        last_volume = ui.get(volume)
        if not audio.volume(last_volume) then client.log("Most Wanted: volume control failed") end
    end
end)

events.on("shutdown", function()
    if playing then audio.stop() end
    release_font()
end)
