---@meta
-- IDE declarations only. Do not run this file as a game script.

---@class Vector3
---@field x number
---@field y number
---@field z number

---@alias Color integer[] RGBA, exactly four channels in 0..255.
---@alias EventName 'paint'|'create_move'|'pre_rage'|'post_rage'|'pre_legit'|'post_legit'|'post_move'|'finalize_command'|'frame_stage'|'game_event'|'shutdown'|'rage_targets'|'rage_scan'|'rage_select'|'rage_fire'|'rage_shot'

---@class PlayerSnapshot
---@field id integer Controller index; 0 aliases local player.
---@field name string
---@field health integer
---@field alive boolean
---@field team integer
---@field enemy boolean
---@field origin Vector3
---@field velocity Vector3
---@field flags integer
---@field armor integer

---@class SettingDescriptor
---@field category string
---@field name string
---@field type string
---@field count integer
---@field writable boolean

---@class CommandSnapshot
---@field number integer
---@field tick integer
---@field buttons integer
---@field buttons_changed integer
---@field buttons_scroll integer
---@field history_count integer
---@field forward number
---@field side number
---@field up number
---@field angles Vector3

---@class GameEvent
---@field name string
---@field userid integer? Controller index; 0 is the local player, nil if absent/unresolved.
---@field attacker integer? Controller index; 0 is the local player, nil if absent/unresolved.
---@field position Vector3? Present for bullet_impact only.
---@field dmg_health integer? player_hurt: health damage reported by the event.
---@field damage integer? Alias of dmg_health.
---@field dmg_armor integer? player_hurt: armor damage reported by the event.
---@field health integer? player_hurt: remaining health.
---@field armor integer? player_hurt: remaining armor.
---@field hitgroup integer? player_hurt: native hitgroup, not a bone/hitbox index.
---@field weapon string? player_hurt: event weapon name, copied before the event expires.

---@class RageShotEvent
---@field id integer Unique within the current DLL session.
---@field status 'command'|'fired'|'hit'|'miss'|'unconfirmed'
---@field command_number integer
---@field command_tick integer
---@field target_id integer Intended controller index.
---@field record_tick integer
---@field hitbox integer Actual scanned hitbox index.
---@field requested_hitbox integer
---@field expected_damage number
---@field hitchance number Percentage 0..100.
---@field forced boolean
---@field no_spread boolean
---@field victim_id integer? On hit; equals the intended target in this API version.
---@field reason string? On miss/unconfirmed, e.g. no_hurt_event/no_weapon_fire/session_reset/overflow.

api = { version = 2, lua = 'Lua 5.5', script = '' }
---Catch ordinary Lua/API errors. Budget exhaustion and allocation failures still disable the script.
---No rollback of settings, draws, UI or other side effects. fn receives no arguments; use a closure.
---@param fn fun(): ...
---@param limits? {instructions?: integer, time_ms?: number} Defaults 50000 / 2 ms; shared parent limits still apply.
---@return boolean ok
---@return string? error Traceback on failure; nil on success.
---@return ... results Preserves all fn results, including nils, on success.
function api.protect(fn, limits) end
buttons = { attack=1, jump=2, duck=4, forward=8, back=16, use=32,
    moveleft=512, moveright=1024, attack2=2048, reload=8192, speed=65536,
    zoom=17179869184, score=8589934592, inspect=34359738368 }

events = {}
---@param name EventName
---@param callback fun(event: table): table?
---@overload fun(name: 'rage_scan', callback: fun(context: RageScan): {points: RagePoint[]}?): integer
---@overload fun(name: 'rage_select', callback: fun(context: RageSelection): {index: integer}?): integer
---@overload fun(name: 'game_event', callback: fun(event: GameEvent)): integer
---@overload fun(name: 'rage_shot', callback: fun(event: RageShotEvent)): integer
---@return integer subscription
function events.on(name, callback) end
---@param id integer
---@return boolean removed
function events.off(id) end

settings = {}
---@param category_filter? string
---@return SettingDescriptor[]
function settings.list(category_filter) end
---@param category string
---@param name string
---@return any value
function settings.get(category, name) end
---@param category string
---@param name string
---@param value any
function settings.set(category, name, value) end
---@param category string
---@param name string
---@param value any Pass nil to release this script's override.
function settings.override(category, name, value) end
---@param category string
---@param name string
---@param key? integer Windows virtual key, 0..255.
---@param mode? integer 0 toggle, 1 hold_on, 2 hold_off.
---@return {key: integer, mode: integer, active: boolean}
function settings.bind(category, name, key, mode) end
---@class BindSnapshot
---@field category string
---@field name string
---@field key integer Windows virtual key.
---@field mode integer 0 toggle, 1 hold_on, 2 hold_off.
---@field active boolean Whether the bind is active.
---@field value boolean Current setting value.
---@return BindSnapshot[] Native bound settings plus active scripts' Lua checkbox binds; includes inactive binds.
function settings.binds() end

client = {}
---@param ... any
function client.log(...) end
---@param level 'debug'|'info'|'warning'|'error'
---@param ... any
function client.log_level(level, ...) end
---@class ExecutionStats
---@field phase string
---@field instructions integer Approximate; sampled every 1000 Lua instructions.
---@field api_calls integer Native API entries, including this stats call.
---@field native_work integer API entries plus table conversion work.
---@field time_ms number Elapsed execution time excluding credited audio waits; not CPU/GPU time.
---@field memory_bytes integer Lua allocator usage; excludes graphics caches and native allocations.
---@class ScriptStats: ExecutionStats
---@field invocations integer Completed load/event dispatches since enabling this instance (all handlers together).
---@field protected_errors integer Ordinary errors caught by api.protect since enabling.
---@field last ExecutionStats? Previous completed invocation; nil before the first one.
---@return ScriptStats
function client.stats() end
---@return number seconds Monotonic, not game time.
function client.time() end
---@param vk integer
---@return boolean
function client.key_down(vk) end
---@return integer width
---@return integer height
function client.screen_size() end
---@return number seconds
function client.frametime() end

audio = {}
---@param basename string MP3 basename under %LOCALAPPDATA%/skeet/muzon, or sounds/<basename>.mp3 under %LOCALAPPDATA%/skeet/sounds. 256 bytes..256 MiB.
---@param loop? boolean Repeat until stopped.
---@return boolean ok
---@return string? error
function audio.play(basename, loop) end
---@param percent number Clamped to 0..100.
---@return boolean ok
function audio.volume(percent) end
function audio.stop() end

cmd = {}
---In finalize_command, angles is the staged AA pose; movement remains in its original frame.
---@return CommandSnapshot
function cmd.get() end
---In finalize_command, requests an AA pose without changing attack history or the camera.
---Airborne commands use a fixed 180-degree AA pose and synchronize non-shot input history.
---Attack/use commands retain their aim. Use create_move/pre_rage for custom aiming.
---@param angles Vector3
---@param visible? boolean
function cmd.set_angles(angles, visible) end
---Commit shot angles to base and every input-history entry; suppress AA pose
---for this command. Requires ragebot.claim_command() in pre_rage.
---@param angles Vector3
function cmd.set_shot_angles(angles) end
---@param forward number -1..1
---@param side number -1..1, positive is right.
---@param up? number -1..1
function cmd.set_movement(forward, side, up) end
---@param mask integer
---@param pressed boolean
function cmd.set_button(mask, pressed) end
---Explicitly set held/changed/scroll bits for a button mask. Command callbacks only.
---@param mask integer
---@param held boolean
---@param changed boolean
---@param scroll boolean
function cmd.set_button_state(mask, held, changed, scroll) end
---Mark the current (or a supplied zero-based) input-history entry as primary attack start.
---@param index? integer
---@return boolean ok
function cmd.set_attack_start(index) end
---Append an analog/button subtick step before finalization. At most 64 steps per command.
---@param when number 0..1 exclusive
---@param forward_delta number -2..2
---@param side_delta number -2..2
---@param button? integer
---@param pressed? boolean
---@return boolean ok
function cmd.add_subtick(when, forward_delta, side_delta, button, pressed) end
---Discard current subtick movement steps before rebuilding them.
function cmd.clear_subticks() end
---Set player/render ticks for every input-history entry; command callbacks only.
---@param player_tick integer
---@param render_tick integer
---@param player_fraction? number 0..1 exclusive
---@param render_fraction? number 0..1 exclusive
function cmd.set_history_ticks(player_tick, render_tick, player_fraction, render_fraction) end

movement = {}
---Claim native bhop or both native strafers for the current command; create_move only.
---@param feature 'bhop'|'strafe'
function movement.claim(feature) end
---@return {flags: integer, on_ground: boolean, velocity: Vector3, predicted_velocity: Vector3, origin: Vector3, surface_friction: number, stamina: number, move_type: integer, forward: number, side: number, buttons: integer}
function movement.context() end

entity = {}
---@return PlayerSnapshot?
function entity.local_player() end
---@param enemies_only? boolean
---@return PlayerSnapshot[]
function entity.players(enemies_only) end
---@param id integer
---@return PlayerSnapshot?
function entity.get(id) end
---@param id integer
---@param bone_index integer 0..127
---@return Vector3?
function entity.bone(id, bone_index) end
---@param id integer
---@return {x: number, y: number, w: number, h: number}?
function entity.bounds(id) end
---@return {id: integer, class_hash: integer, origin: Vector3}[]
function entity.items() end
---@param id integer
---@return {item_id: integer, ammo: integer, reloading: boolean}?
function entity.weapon(id) end

combat = {}
---@return {valid: boolean, weapon_type: integer, item_id: integer, tick: integer, time: number, spread: number, inaccuracy: number, scoped: boolean, range: number, eye: Vector3}
function combat.context() end
---@return {item_id: integer, is_revolver: boolean, client_tick: integer, tick_base: integer, ready_tick: integer, next_primary_tick: integer, next_secondary_tick: integer, ammo: integer, reloading: boolean, can_start_primary: boolean, postponed_primary_ready: boolean}?
function combat.weapon_state() end
---Return native spread correction for the supplied aim/tick, or nil if no solution.
---@param aim Vector3
---@param tick? integer
---@param hidden_shot? boolean
---@return Vector3?
function combat.spread_correction(aim, tick, hidden_shot) end
---Sample the current weapon's native spread for an exact command angle/tick.
---@param angles Vector3
---@param tick? integer
---@return {seed: integer, x: number, y: number}?
function combat.spread_sample(angles, tick) end
---@param target_id integer
---@param world_point Vector3
---@return {damage: number, hitbox: integer, hitgroup: integer, penetrated: boolean}?
---@param record_tick? integer Must still be an available non-future record.
function combat.damage(target_id, world_point, record_tick) end
---@return boolean
---@param ignore_next_attack? boolean Still checks reload/ammo; useful while an R8 cock is already held.
function combat.can_shoot(ignore_next_attack) end
---@return Vector3?
function combat.aim_punch() end
---@param target_id integer
---@return {tick: integer, time: number, origin: Vector3, velocity: Vector3, ducked: boolean, extrapolated: boolean}[]
function combat.records(target_id) end

trace = {}
---@param start Vector3
---@param finish Vector3
---@param skip_player_id? integer
---@return {fraction: number, end_pos: Vector3, normal: Vector3, all_solid: boolean}
function trace.line(start, finish, skip_player_id) end

render = {}
---@param x number
---@param y number
---@param text string
---@param color Color
---@param font? integer Handle obtained by this script in paint.
function render.text(x, y, text, color, font) end
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param color Color
---@param thickness? number
function render.line(x1, y1, x2, y2, color, thickness) end
---@param x number
---@param y number
---@param width number
---@param height number
---@param color Color
---@param filled? boolean
function render.rect(x, y, width, height, color, filled) end
---@param x number
---@param y number
---@param radius number
---@param color Color
---@param filled? boolean
function render.circle(x, y, radius, color, filled) end
---@param text string
---@return number width
---@return number height
---@param font? integer Custom fonts require paint.
function render.measure_text(text, font) end
---@param world Vector3
---@return number? x
---@return number? y
---@return boolean? on_screen
function render.world_to_screen(world) end

ui = {}
---@param kind 'checkbox'|'slider'|'combo'|'color'|'text'
---@param id string
---@param label string
---@param default any
---@param min_or_options? number|string[]|{key: integer, mode: integer} Checkbox accepts optional bind table (key 0..255; mode 0 toggle, 1 hold_on, 2 hold_off).
---@param max? number
---@return string id
function ui.create(kind, id, label, default, min_or_options, max) end
---@param id string
---@return any
function ui.get(id) end
---@param id string
---@param value any
function ui.set(id, value) end
---@param id string Checkbox control id.
---@param key? integer Windows VK 0..255; 0 removes the key.
---@param mode? integer 0 toggle, 1 hold_on, 2 hold_off.
---@return {key: integer, mode: integer, active: boolean} bind
function ui.bind(id, key, mode) end

storage = {}
---@param key string
---@param default? any
---@return any
function storage.get(key, default) end
---@param key string
---@param value any Pass nil to remove the key. Persisted on unload.
function storage.set(key, value) end

---@class CustomModel
---@field id string Relative compiled file under game/csgo/characters/models, e.g. fatality/sas/player.vmdl_c.
---@field path string Virtual CS2 path passed to the player-model setter.

models = {}
---@return CustomModel[] models Up to 512 compiled models found under CS2 game/csgo/characters/models.
function models.list() end
---@param id string ID returned by models.list().
---@return string path Virtual model path; this script's choice overrides the built-in agent changer while enabled.
function models.set(id) end
---Release this script's custom model choice. The original agent selection is restored.
function models.clear() end
---@return string? path This script's current virtual model path, or nil.
function models.current() end
---@return 'idle'|'ready'|'error' status Ready confirms file existence, not engine rendering.
---@return string? message Error detail when status is error.
function models.status() end

chams = {}
---@return string[] targets enemy, enemy_invisible, team, team_invisible, local, arms, weapon.
function chams.targets() end
---@param brightness number 0.1..8. Only allowed while the script loads.
---@param tint Color RGB baked into a new solidcolor material; alpha is ignored.
---@return integer handle Script-local handle, valid until the script is unloaded.
function chams.create_material(brightness, tint) end
---@param target string One of chams.targets().
---@param handle integer? Script-local material handle; nil releases this target.
---@param color Color? Render RGBA; required unless handle is nil.
function chams.set(target, handle, color) end

-- API v2; full contracts and phase restrictions: EXTENSIONS.ru.md / RAGEBOT.ru.md.
---@class Vector2
---@field x number
---@field y number
---@class RageRecord
---@field tick integer
---@field time number
---@field origin Vector3
---@field velocity Vector3
---@field extrapolated boolean
---@field future boolean
---@field ducked boolean
---@class RagePoint
---@field hitbox integer 0..18; hitbox index, not bone index.
---@field position Vector3 World position.
---@field center? boolean Ordering hint.
---@class RageHitbox
---@field index integer
---@field bone integer
---@field radius number
---@field center Vector3
---@field capsule_a Vector3
---@field capsule_b Vector3
---@field extents Vector3
---@field axis_x Vector3
---@field axis_y Vector3
---@field axis_z Vector3
---@class RageScan
---@field id integer Player controller index.
---@field health integer
---@field min_damage number
---@field record RageRecord
---@field eye Vector3
---@field inaccuracy number
---@field spread number
---@field prediction boolean
---@field centers_only boolean
---@field trace_budget integer
---@field hitboxes RageHitbox[] All available geometry, including boxes disabled in menu.
---@field points RagePoint[] Native point list for this pass.
---@class RageHit
---@field id integer
---@field health integer
---@field damage number
---@field fov number
---@field hitbox integer Actual intersected hitbox.
---@field requested_hitbox integer Requested hitbox.
---@field hitgroup integer
---@field position Vector3
---@field angles Vector3
---@field eye Vector3
---@field center boolean
---@field penetrated boolean
---@field record RageRecord
---@class RageSelection
---@field hits RageHit[]
---@field inaccuracy number
---@field spread number
---@field no_spread boolean
---@field required_hitchance number Percent 0..100.
---@field allow_force boolean

ragebot = {}
---Pure geometry. phase is in radians. Rings are interleaved from inner to outer.
---@param kind 'rings'|'spiral'
---@param count integer 1..128
---@param rings? integer 1..32, default 4; ignored for spiral.
---@param phase? number Radians, default 0.
---@return Vector2[]
function ragebot.pattern(kind, count, rings, phase) end
---Only in rage_scan; maps offsets onto the current record's hitbox silhouette.
---@param hitbox integer 0..18
---@param offsets Vector2[] At most 128 points in the unit disk.
---@param scale? number 0..100, default 100.
---@return RagePoint[]
function ragebot.multipoints(hitbox, offsets, scale) end
---Only in rage_select; at most 32 total HC queries per script/command.
---@param index integer 1-based index into this callback's hits.
---@return number percentage 0..100, geometric; not a second penetration test.
function ragebot.hitchance(index) end
---Only in pre_rage. Skips the native ragebot for THIS command; renew each command.
---Use cmd APIs to implement a complete custom command strategy. Other features still run.
function ragebot.claim_command() end

---Command callbacks only. nil if the record expired; latest record if tick omitted.
---@param id integer
---@param record_tick? integer
---@return {tick: integer, time: number, hitboxes: table[]}?
function combat.hitboxes(id, record_tick) end
---@param id integer
---@param point Vector3
---@param hitbox integer 0..18
---@param record_tick? integer
---@return number? percentage 0..100
function combat.hitchance(id, point, hitbox, record_tick) end

---Deferred self-unload after the current callback returns.
function client.unload() end
---paint only.
---@return boolean
function ui.is_menu_opened() end
---paint only. Screen pixels.
---@return {x: number, y: number, w: number, h: number}
function ui.get_menu_rect() end
---paint only. Mouse coordinates are screen pixels; drag only while menu is open.
---@return {x: number, y: number, down: boolean, clicked: boolean}
function ui.mouse_state() end
---@param src Vector3
---@param dst Vector3
---@return Vector3 angles Degrees.
function math.calc_angle(src, dst) end
---@param src Vector3
---@param dst Vector3
---@return number degrees
function math.calc_fov(src, dst) end
---@param degrees number
---@return number degrees -180..180
function math.normalize_angle(degrees) end
---@param forward Vector3
---@return Vector3 angles
function math.vector_angles(forward) end
---@param angles Vector3
---@return Vector3 forward
---@return Vector3 right
---@return Vector3 up
function math.angle_vectors(angles) end

-- Render additions. Drawing, resource creation and UI geometry require paint.
---@return integer count Number of scripting paint passes since DLL initialization.
function render.frame_count() end
---@return number seconds
function render.frame_time() end
---@return integer width
---@return integer height
function render.screen_size() end
---@param x number
---@param y number
---@param w number
---@param h number
---@param tl Color
---@param tr Color
---@param br Color
---@param bl Color
function render.rect_filled_fade(x, y, w, h, tl, tr, br, bl) end
---@param points Vector2[] 2..256 points.
---@param color Color
---@param thickness? number 0.1..100, default 1.
---@param closed? boolean Default false.
function render.poly_line(points, color, thickness, closed) end
---@param points Vector2[] 3..256 vertices; simple polygon without holes.
---@param color Color
function render.polygon(points, color) end
---@param points Vector2[] Same contract as polygon.
---@param color Color
function render.concave_polygon(points, color) end
---@param x number
---@param y number
---@param radius number
---@param start_angle number Radians.
---@param end_angle number Radians.
---@param color Color
---@param thickness? number Default 1.
---@param segments? integer 2..256, default 64.
function render.arc(x, y, radius, start_angle, end_angle, color, thickness, segments) end
---@param x number
---@param y number
---@param width number
---@param height number
function render.push_clip_rect(x, y, width, height) end
function render.pop_clip_rect() end
---@param x number
---@param y number
---@param radius number
---@param inside Color
---@param outside Color
function render.circle_fade(x, y, radius, inside, outside) end
---@param position Vector3
---@param radius number
---@param color Color
---@param normal? Vector3 Default {x=0,y=0,z=1}.
function render.circle_3d(position, radius, color, normal) end
---@param position Vector3
---@param radius number
---@param color Color
---@param normal? Vector3
function render.circle_filled_3d(position, radius, color, normal) end
---@param position Vector3
---@param radius number
---@param inside Color
---@param outside Color
---@param normal? Vector3
function render.circle_fade_3d(position, radius, inside, outside, normal) end
---@param basename string File under config_dir/resources/<basename>, or skeetles/name.png under config_dir/skeetles; at most 4 MiB.
---@return integer? texture Handle; nil on missing/unsupported image.
---@return string? error Resource failure code; nil on success.
function render.setup_texture(basename) end
---@param bytes string Binary encoded image, at most 4 MiB.
---@return integer? texture
---@return string? error Resource failure code; nil on success.
function render.setup_texture_from_memory(bytes) end
---@param bytes string Raw RGBA bytes; exactly width*height*4.
---@param width integer 1..4096, total pixels at most 1048576.
---@param height integer 1..4096
---@return integer? texture
---@return string? error Resource failure code; nil on success.
function render.setup_texture_rgba(bytes, width, height) end
---@param texture integer Handle returned to this script.
---@return integer width Original pixel width.
---@return integer height Original pixel height.
function render.texture_size(texture) end
---@param texture integer Handle returned to this script.
---@param x number
---@param y number
---@param width number
---@param height number
---@param tint? Color Default white.
---@param rounding? number Default 0.
function render.texture(texture, x, y, width, height, tint, rounding) end
---@param texture integer Handle returned to this script.
---@param center_x number Rotation center in screen pixels.
---@param center_y number Rotation center in screen pixels.
---@param width number Drawn width.
---@param height number Drawn height.
---@param angle number Clockwise rotation in radians.
---@param tint? Color Default white.
function render.texture_rotated(texture, center_x, center_y, width, height, angle, tint) end
---@param basename string TTF/OTF under config_dir/resources/<basename>, or fonts/<basename> under config_dir/fonts.
---@param size number 6..96 pixels.
---@return integer? font
---@return string? error Resource failure code; nil on success.
function render.setup_font(basename, size) end
---Override built-in ESP labels, keybinds or watermark with a font loaded by this script.
---Call in paint; pass nil to release this script's override.
---@param target 'esp'|'keybinds'|'watermark'
---@param font? integer
function render.builtin_font(target, font) end
