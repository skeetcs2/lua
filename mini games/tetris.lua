-- Tetris mini-game for Skeet Lua API v2.
-- Arrow keys: left/right, down = soft drop, up = rotate.
-- P = pause, R = new game. Drag the title bar with the menu open.

local visible = ui.create("checkbox", "tetris_visible", "Tetris window", true)
local size = ui.create("slider", "tetris_size", "Window size (%)", 100, 65, 160)
local accent = ui.create("color", "tetris_accent", "Window accent", {128, 210, 255, 255})

local board_w, board_h = 10, 20
local colors = {
    {75, 218, 235, 255}, -- I
    {244, 214, 91, 255}, -- O
    {180, 120, 239, 255}, -- T
    {113, 221, 141, 255}, -- S
    {242, 111, 118, 255}, -- Z
    {110, 150, 248, 255}, -- J
    {255, 174, 99, 255}, -- L
}
local shapes = {
    {{0, 1}, {1, 1}, {2, 1}, {3, 1}},
    {{1, 0}, {2, 0}, {1, 1}, {2, 1}},
    {{1, 0}, {0, 1}, {1, 1}, {2, 1}},
    {{1, 0}, {2, 0}, {0, 1}, {1, 1}},
    {{0, 0}, {1, 0}, {1, 1}, {2, 1}},
    {{0, 0}, {0, 1}, {1, 1}, {2, 1}},
    {{2, 0}, {0, 1}, {1, 1}, {2, 1}},
}

local board, bag, piece, next_kind
local score, lines, best = 0, 0, storage.get("tetris_best", 0)
local paused, game_over = false, false
local x = storage.get("tetris_x", 80)
local y = storage.get("tetris_y", 90)
local dragging, grab_x, grab_y = false, 0, 0
local last_fall = client.time()
local keys = {}

local function cells(kind, rotation)
    local result = {}
    for i, block in ipairs(shapes[kind]) do
        local px, py = block[1], block[2]
        for _ = 1, rotation do px, py = 3 - py, px end
        result[i] = {px, py}
    end
    return result
end

local function empty_row()
    local row = {}
    for col = 1, board_w do row[col] = 0 end
    return row
end

local function draw_kind()
    if #bag == 0 then
        for kind = 1, #shapes do bag[kind] = kind end
        for i = #bag, 2, -1 do
            local j = math.random(i)
            bag[i], bag[j] = bag[j], bag[i]
        end
    end
    return table.remove(bag)
end

local function fits(kind, px, py, rotation)
    for _, block in ipairs(cells(kind, rotation)) do
        local col, row = px + block[1] + 1, py + block[2] + 1
        if col < 1 or col > board_w or row > board_h then return false end
        if row >= 1 and board[row][col] ~= 0 then return false end
    end
    return true
end

local function spawn()
    piece = {kind = next_kind, x = 3, y = -1, rotation = 0}
    next_kind = draw_kind()
    if not fits(piece.kind, piece.x, piece.y, piece.rotation) then
        game_over = true
    end
end

local function new_game()
    board, bag = {}, {}
    for row = 1, board_h do board[row] = empty_row() end
    score, lines, paused, game_over = 0, 0, false, false
    next_kind = draw_kind()
    spawn()
    last_fall = client.time()
end

local function record_score()
    if score > best then
        best = score
        storage.set("tetris_best", best)
    end
end

local function lock_piece()
    local above_top = false
    for _, block in ipairs(cells(piece.kind, piece.rotation)) do
        local col, row = piece.x + block[1] + 1, piece.y + block[2] + 1
        if row < 1 then
            above_top = true
        else
            board[row][col] = piece.kind
        end
    end
    if above_top then game_over = true; record_score(); return end

    local cleared, row = 0, board_h
    while row >= 1 do
        local full = true
        for col = 1, board_w do
            if board[row][col] == 0 then full = false; break end
        end
        if full then
            table.remove(board, row)
            table.insert(board, 1, empty_row())
            cleared = cleared + 1
        else
            row = row - 1
        end
    end
    if cleared > 0 then
        local level = 1 + math.floor(lines / 10)
        score = score + ({0, 100, 300, 500, 800})[cleared + 1] * level
        lines = lines + cleared
        record_score()
    end
    spawn()
end

local function step_down()
    if fits(piece.kind, piece.x, piece.y + 1, piece.rotation) then
        piece.y = piece.y + 1
        return true
    end
    lock_piece()
    return false
end

local function rotate()
    if piece.kind == 2 then return end -- O does not need rotation.
    local turn = (piece.rotation + 1) % 4
    for _, offset in ipairs({0, -1, 1, -2, 2}) do
        if fits(piece.kind, piece.x + offset, piece.y, turn) then
            piece.x, piece.rotation = piece.x + offset, turn
            return
        end
    end
end

-- Returns an initial press, then repeated presses while a key is held.
local function key_press(vk, now, repeat_delay, repeat_interval)
    local state = keys[vk] or {down = false, next_time = 0}
    local down = client.key_down(vk)
    local pressed = false
    if down then
        if not state.down then
            pressed = true
            state.next_time = now + (repeat_delay or 0)
        elseif repeat_interval and now >= state.next_time then
            pressed = true
            state.next_time = now + repeat_interval
        end
    end
    state.down = down
    keys[vk] = state
    return pressed, down
end

local function draw_block(px, py, cell, kind, alpha)
    local c = colors[kind]
    render.rect(px + 1, py + 1, cell - 2, cell - 2,
        {c[1], c[2], c[3], alpha or 255}, true)
end

new_game()

events.on("paint", function()
    if not ui.get(visible) then dragging = false; last_fall = client.time(); return end

    local now = client.time()
    local screen_w, screen_h = render.screen_size()
    local cell = math.floor(18 * ui.get(size) / 100 + 0.5)
    cell = math.max(8, math.min(cell,
        math.floor((screen_h - 75) / board_h),
        math.floor((screen_w - 48 - 95) / 15)))
    local pad, header, footer, gap = 12, 29, 22, 12
    local sidebar = math.max(95, cell * 5)
    local window_w = pad * 2 + board_w * cell + gap + sidebar
    local window_h = header + pad * 2 + board_h * cell + footer
    local max_x, max_y = math.max(0, screen_w - window_w), math.max(0, screen_h - window_h)
    x, y = math.max(0, math.min(x, max_x)), math.max(0, math.min(y, max_y))

    if ui.is_menu_opened() then
        local mouse = ui.mouse_state()
        if mouse.clicked and mouse.x >= x and mouse.x <= x + window_w
            and mouse.y >= y and mouse.y <= y + header then
            dragging = true
            grab_x, grab_y = mouse.x - x, mouse.y - y
        end
        if dragging then
            if mouse.down then
                x = math.max(0, math.min(max_x, mouse.x - grab_x))
                y = math.max(0, math.min(max_y, mouse.y - grab_y))
            else
                dragging = false
                storage.set("tetris_x", x)
                storage.set("tetris_y", y)
            end
        end
    elseif dragging then
        dragging = false
        storage.set("tetris_x", x)
        storage.set("tetris_y", y)
    end

    local restart = key_press(0x52, now) -- R
    local pause = key_press(0x50, now) -- P
    local left = key_press(0x25, now, 0.18, 0.075)
    local right = key_press(0x27, now, 0.18, 0.075)
    local down, down_held = key_press(0x28, now, 0.08, 0.045)
    local turn = key_press(0x26, now)
    if restart then new_game() end
    if pause and not game_over then paused = not paused; last_fall = now end
    if not dragging and not paused and not game_over then
        if left and fits(piece.kind, piece.x - 1, piece.y, piece.rotation) then piece.x = piece.x - 1 end
        if right and fits(piece.kind, piece.x + 1, piece.y, piece.rotation) then piece.x = piece.x + 1 end
        if turn then rotate() end
        if down then
            if step_down() then score = score + 1; record_score() end
            last_fall = now
        else
            local level = 1 + math.floor(lines / 10)
            local interval = math.max(0.09, 0.7 * 0.84 ^ (level - 1))
            if down_held then interval = math.min(interval, 0.045) end
            if now - last_fall >= interval then step_down(); last_fall = now end
        end
    else
        last_fall = now
    end

    local highlight = ui.get(accent)
    local bx, by = x + pad, y + header + pad
    local sx = bx + board_w * cell + gap
    render.rect(x, y, window_w, window_h, {15, 20, 30, 242}, true)
    render.rect(x, y, window_w, window_h, {84, 100, 120, 255})
    render.rect(x, y, window_w, header, {27, 38, 54, 255}, true)
    render.rect(x, y + header - 2, window_w, 2, highlight, true)
    render.text(x + pad, y + 7, "TETRIS", {246, 248, 255, 255})
    if ui.is_menu_opened() then
        render.text(x + window_w - 105, y + 7, "DRAG HERE", {160, 178, 194, 255})
    end

    render.rect(bx, by, board_w * cell, board_h * cell, {21, 29, 41, 255}, true)
    for col = 1, board_w - 1 do
        local gx = bx + col * cell
        render.line(gx, by, gx, by + board_h * cell, {34, 44, 57, 255})
    end
    for row = 1, board_h - 1 do
        local gy = by + row * cell
        render.line(bx, gy, bx + board_w * cell, gy, {34, 44, 57, 255})
    end
    for row = 1, board_h do
        for col = 1, board_w do
            local kind = board[row][col]
            if kind ~= 0 then draw_block(bx + (col - 1) * cell, by + (row - 1) * cell, cell, kind) end
        end
    end
    if not game_over then
        local ghost_y = piece.y
        while fits(piece.kind, piece.x, ghost_y + 1, piece.rotation) do ghost_y = ghost_y + 1 end
        for _, block in ipairs(cells(piece.kind, piece.rotation)) do
            local col = piece.x + block[1]
            local row = ghost_y + block[2]
            if row >= 0 then
                render.rect(bx + col * cell + 2, by + row * cell + 2,
                    cell - 4, cell - 4, {132, 151, 174, 130})
            end
            row = piece.y + block[2]
            if row >= 0 then draw_block(bx + col * cell, by + row * cell, cell, piece.kind) end
        end
    end
    render.rect(bx, by, board_w * cell, board_h * cell, highlight)

    render.text(sx, by, "SCORE", {160, 180, 198, 255})
    render.text(sx, by + 18, tostring(score), {245, 247, 251, 255})
    render.text(sx, by + 48, "BEST", {160, 180, 198, 255})
    render.text(sx, by + 66, tostring(best), {245, 247, 251, 255})
    render.text(sx, by + 96, "LINES", {160, 180, 198, 255})
    render.text(sx, by + 114, tostring(lines), {245, 247, 251, 255})
    render.text(sx, by + 144, "NEXT", {160, 180, 198, 255})
    local preview = math.max(8, math.floor(cell * 0.7))
    for _, block in ipairs(shapes[next_kind]) do
        draw_block(sx + block[1] * preview, by + 166 + block[2] * preview,
            preview, next_kind)
    end
    if board_h * cell >= 325 then
        render.text(sx, by + 225, "LEFT / RIGHT", {187, 202, 215, 255})
        render.text(sx, by + 243, "UP: ROTATE", {187, 202, 215, 255})
        render.text(sx, by + 261, "DOWN: FALL", {187, 202, 215, 255})
        render.text(sx, by + 279, "P: PAUSE", {187, 202, 215, 255})
        render.text(sx, by + 297, "R: NEW", {187, 202, 215, 255})
    else
        render.text(sx, by + 205, "ARROWS: MOVE", {187, 202, 215, 255})
        render.text(sx, by + 224, "P / R", {187, 202, 215, 255})
    end
    if paused or game_over then
        local message = game_over and "GAME OVER  [R]" or "PAUSED  [P]"
        render.rect(bx + 5, by + board_h * cell * 0.5 - 18,
            board_w * cell - 10, 36, {10, 15, 22, 230}, true)
        render.text(bx + 12, by + board_h * cell * 0.5 - 9, message,
            {255, 255, 255, 255})
    end
    render.text(x + pad, y + window_h - footer + 1,
        "ARROWS  P  R",
        {147, 166, 184, 255})
end)
