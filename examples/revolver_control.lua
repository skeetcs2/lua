-- R8 command-control template. Off by default; adapt the target and timing
-- policy before using it. Native ragebot remains active while this is off.
local enabled = ui.create("checkbox", "r8_control", "Custom R8 control", false)
local held = false

events.on("pre_rage", function()
    local weapon = combat.weapon_state()
    if not weapon or not weapon.is_revolver or not ui.get(enabled) then
        held = false
        return
    end

    -- Only R8 is claimed. Every other weapon keeps the native ragebot.
    ragebot.claim_command()
    local current = cmd.get()
    local secondary = (current.buttons & buttons.attack2) ~= 0
    if secondary or weapon.reloading or weapon.ammo <= 0 then
        if held then cmd.set_button_state(buttons.attack, false, true, false) end
        held = false
        return
    end

    -- Example policy: start charging as soon as the weapon can begin a
    -- primary attack. Keep the command edge only on the first held tick.
    if not held then
        if not weapon.can_start_primary then return end
        cmd.set_button_state(buttons.attack, true, true, true)
        cmd.set_attack_start()
        held = true
    else
        cmd.set_button_state(buttons.attack, true, false, false)
    end

    -- Insert your own target selection here. Only call set_shot_angles on a
    -- command that should actually fire; it suppresses the final AA pose.
    -- local target = ...
    -- if target then
    --     local aim = math.calc_angle(combat.context().eye, target)
    --     cmd.set_shot_angles(aim)
    --     cmd.set_attack_start()
    -- end

    -- Release before the unattended charge can produce an untargeted shot.
    -- This margin is a sample policy, not a guaranteed R8 timing constant.
    if weapon.ready_tick > 0 and weapon.client_tick >= weapon.ready_tick - 3 then
        cmd.set_button_state(buttons.attack, false, true, false)
        held = false
    end
end)
