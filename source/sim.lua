-- The simulation: animate() dispatcher + per-element physics handlers, ported
-- from HL_PLAY.C over the shared 22x14 grid. Hero is inert in Phase 2 (heroProc
-- is a stub; gravity may still crush it). Bitwise ops in the C are written here
-- as arithmetic %/+ to avoid any integer/float surprises in Playdate Lua.
hl = hl or {}

hl.POST_MORTAL_TIME = 32

-- Per-tick globals (HL_PLAY.C). counter drives alternating-tick effects.
hl.counter, hl.actives, hl.suicide, hl.dance, hl.post_mortal, hl.hero_dir =
    0, 0, 0, 0, 0, 0

-- play_init (HL_PLAY.C 80): reset the per-cave timers/counters.
function hl.playInit()
    hl.counter = 0
    hl.actives = 1            -- start non-zero so the cave runs at least one tick
    hl.suicide = 0
    hl.dance = 0
    hl.post_mortal = hl.POST_MORTAL_TIME
    hl.hero_dir = 0
    hl.mode = hl.MODE.GAME_OK
    hl.won = false            -- set true only when the hero enters the exit door
end

-- fallers_proc (HL_PLAY.C 323): shared gravity for rock/heart/bomb. Returns true
-- when the object lands this tick (caller plays the landing sound).
function hl.fallersProc(pos)
    local cave, state, phase, call = hl.cave, hl.state, hl.phase, hl.call
    local S, E = hl.S, hl.E
    local DOWN, LEFT, RIGHT, UP = hl.DOWN, hl.LEFT, hl.RIGHT, hl.UP
    local result = false

    if state[pos] == S.STATIC then
        local below = cave[pos + DOWN]
        local roll = false
        if below == E.SPACE then
            state[pos] = S.FALLING
            hl.actives = hl.actives + 1
        elseif below == E.BOMB then
            if phase[pos + DOWN] == 0 then roll = true end   -- else: blocked
        elseif below == E.ROCK or below == E.HEART or below == E.BRICK
            or below == E.PLASMA or below == E.EXPL then
            roll = true
        elseif below == E.BALOON then
            if cave[pos + DOWN * 2] == E.SPACE
                and (cave[pos + UP] == E.ROCK or cave[pos + UP] == E.HEART
                     or cave[pos + UP] == E.BOMB) then
                cave[pos + DOWN * 2]  = cave[pos + DOWN]
                state[pos + DOWN * 2] = state[pos + DOWN]
                phase[pos + DOWN * 2] = phase[pos + DOWN]
                call[pos + DOWN * 2]  = 0
                cave[pos + DOWN]  = E.SPACE
                state[pos + DOWN] = S.NOTACTIVE
                phase[pos + DOWN] = 0
                state[pos] = S.FALLING
            end
        end
        if roll then
            if cave[pos + LEFT] == E.SPACE and cave[pos + LEFT + DOWN] == E.SPACE then
                if state[pos + LEFT + UP] ~= S.FALLING then
                    cave[pos + LEFT]  = cave[pos]
                    state[pos + LEFT] = S.FALLING
                    phase[pos + LEFT] = phase[pos]
                    call[pos + LEFT]  = 0
                    cave[pos] = E.SPACE; state[pos] = S.NOTACTIVE; phase[pos] = 0
                    hl.actives = hl.actives + 1
                end
            elseif cave[pos + RIGHT] == E.SPACE and cave[pos + RIGHT + DOWN] == E.SPACE then
                if state[pos + RIGHT + UP] ~= S.FALLING then
                    cave[pos + RIGHT]  = cave[pos]
                    state[pos + RIGHT] = S.FALLING
                    phase[pos + RIGHT] = phase[pos]
                    call[pos + RIGHT]  = 0
                    cave[pos] = E.SPACE; state[pos] = S.NOTACTIVE; phase[pos] = 0
                    hl.actives = hl.actives + 1
                end
            end
        end
    end

    if state[pos] == S.FALLING then
        hl.actives = hl.actives + 1
        local below = cave[pos + DOWN]
        if below == E.SPACE then
            cave[pos + DOWN]  = cave[pos]
            state[pos + DOWN] = S.FALLING
            phase[pos + DOWN] = phase[pos]
            call[pos + DOWN]  = 0
            cave[pos] = E.SPACE; state[pos] = S.NOTACTIVE; phase[pos] = 0
        elseif below == E.HERO then
            if phase[pos + DOWN] < 6 then
                cave[pos + DOWN]  = E.EXPL
                state[pos + DOWN] = S.ACTIVE
                phase[pos + DOWN] = 0
                call[pos + DOWN]  = 0
            end
            state[pos] = S.STATIC; result = true
        elseif below == E.BOMB then
            state[pos + DOWN] = S.FIRED
            state[pos] = S.STATIC; result = true
        else
            state[pos] = S.STATIC; result = true
        end
    end
    return result
end

-- rock_proc (427)
function hl.rockProc(pos)
    if hl.fallersProc(pos) then
        hl.sfx(hl.cave[pos + hl.DOWN] ~= hl.E.GRASS and "rock" or "rocgrass")
    end
end

-- heart_proc (436): pulse animation + gravity
function hl.heartProc(pos)
    hl.phase[pos] = (hl.phase[pos] + 1) % 6
    if hl.fallersProc(pos) then
        hl.sfx(hl.cave[pos + hl.DOWN] ~= hl.E.GRASS and "heart" or "hrtgrass")
    end
end

-- bomb_proc (452): falls, arms on hard landing, 2-phase blast in 4 dirs
function hl.bombProc(pos)
    local cave, state, phase, call = hl.cave, hl.state, hl.phase, hl.call
    local S, E, DOWN = hl.S, hl.E, hl.DOWN

    if hl.fallersProc(pos) then
        if cave[pos + DOWN] ~= E.GRASS then
            state[pos] = S.FIRED
        else
            hl.sfx("rocgrass")
        end
    end

    if state[pos] == S.FIRED then
        if phase[pos] == 0 then
            phase[pos] = 1
            if not (cave[pos + DOWN] == E.HERO and phase[pos + DOWN] >= 6)
                and cave[pos + DOWN] ~= E.BOMB then
                call[pos + DOWN] = 0
            end
        else
            hl.sfx("expl")
            cave[pos] = E.EXPL; state[pos] = S.ACTIVE; phase[pos] = 1
            local blast = { hl.LEFT, hl.RIGHT, hl.UP, hl.DOWN }
            for i = 1, 4 do
                local dir = blast[i]
                local c = cave[pos + dir]
                if c == E.BOMB then
                    state[pos + dir] = S.FIRED
                    call[pos + dir] = 0
                elseif c == E.METAL or c == E.LJUMP or c == E.RJUMP then
                    -- blast blocked
                else
                    if not (c == E.HERO and phase[pos + dir] >= 6) then
                        cave[pos + dir] = E.EXPL
                        state[pos + dir] = S.ACTIVE
                        phase[pos + dir] = 0
                    end
                end
            end
        end
    end
end

-- baloon_proc (504): rises into SPACE, can push rock/heart/bomb/hero up
function hl.baloonProc(pos)
    local cave, state, phase, call = hl.cave, hl.state, hl.phase, hl.call
    local S, E, UP = hl.S, hl.E, hl.UP

    phase[pos] = (phase[pos] + 1) % 4

    if state[pos] == S.STATIC then
        local up = cave[pos + UP]
        if up == E.SPACE then
            state[pos] = S.FLYING
            hl.actives = hl.actives + 1
        elseif up == E.HERO or up == E.ROCK or up == E.BOMB or up == E.HEART then
            if cave[pos + UP * 2] == E.SPACE then
                cave[pos + UP * 2]  = cave[pos + UP]
                state[pos + UP * 2] = state[pos + UP]
                phase[pos + UP * 2] = phase[pos + UP]
                cave[pos + UP]  = E.SPACE
                state[pos + UP] = S.NOTACTIVE
                phase[pos + UP] = 0
                state[pos] = S.FLYING
            end
        end
    end

    if state[pos] == S.FLYING then
        hl.actives = hl.actives + 1
        if cave[pos + UP] == E.SPACE then
            cave[pos + UP]  = E.BALOON
            state[pos + UP] = S.FLYING
            phase[pos + UP] = phase[pos]
            call[pos + UP]  = 0
            cave[pos] = E.SPACE; state[pos] = S.NOTACTIVE; phase[pos] = 0
        else
            state[pos] = S.STATIC
        end
    end
end

-- door_proc (554): opens (animates) once all hearts are collected
function hl.doorProc(pos)
    local phase, state = hl.phase, hl.state
    if phase[pos] < 3 then
        if hl.hearts_num == 0 then
            if phase[pos] == 0 then hl.sfx("colected") end
            phase[pos] = phase[pos] + 1
        end
    else
        state[pos] = hl.S.OPENED
    end
end

-- expl_proc (568): explosion animation, then clears to SPACE
function hl.explProc(pos)
    local phase = hl.phase
    if phase[pos] < 6 then
        hl.actives = hl.actives + 1
        phase[pos] = phase[pos] + 1
    else
        hl.cave[pos] = hl.E.SPACE
        hl.state[pos] = hl.S.NOTACTIVE
        phase[pos] = 0
        hl.actives = hl.actives + 1
    end
end

-- plasma_proc (584): hazard animation
function hl.plasmaProc(pos)
    hl.phase[pos] = (hl.phase[pos] + 1) % 8
end

-- jump_proc (273): tunnel-pad animation; ACTIVE/FALLING carry the hero through
-- and emit it on the far side (driven by hero_proc, so Phase 2 only animates).
function hl.jumpProc(pos)
    local cave, state, phase, call = hl.cave, hl.state, hl.phase, hl.call
    local S, E = hl.S, hl.E
    local st = state[pos]
    if st == S.STATIC then
        phase[pos] = (phase[pos] + 1) % 4
    elseif st == S.ACTIVE then
        hl.actives = hl.actives + 1
        hl.post_mortal = hl.POST_MORTAL_TIME
        local e = cave[pos]
        local dir = (e == E.LJUMP) and hl.LEFT or hl.RIGHT
        phase[pos] = ((phase[pos] + 1) % 4) + 4
        state[pos] = S.STATIC
        local c = cave[pos + dir]
        if c == E.LJUMP or c == E.RJUMP then
            if c == e then
                state[pos + dir] = S.ACTIVE
                call[pos + dir] = 0
            end
        elseif c == E.GRASS or c == E.SPACE then
            state[pos] = S.FALLING
        end
    elseif st == S.FALLING then
        hl.actives = hl.actives + 1
        hl.post_mortal = hl.POST_MORTAL_TIME
        local e = cave[pos]
        local dir = (e == E.LJUMP) and hl.LEFT or hl.RIGHT
        phase[pos] = (phase[pos] + 1) % 4
        state[pos] = S.STATIC
        if cave[pos + dir] == E.GRASS or cave[pos + dir] == E.SPACE then
            cave[pos + dir]  = E.HERO
            state[pos + dir] = S.ACTIVE
            phase[pos + dir] = (e == E.LJUMP) and 0 or 2
            call[pos + dir]  = 0
        end
    end
end

-- hero_proc (HL_PLAY.C 144): the player. Handles death (suicide), victory
-- (dance), and direction-driven movement: walk into space/grass, push
-- rock/bomb/balloon (horizontal, half-speed on odd counter), enter tunnels,
-- collect hearts, exit through an opened door. hero_dir is set by main each tick.
-- hero_phase bits: bit1 = facing (0 left / 1 right), bit0 = walk step.
function hl.heroProc(pos)
    local cave, state, phase, call = hl.cave, hl.state, hl.phase, hl.call
    local S, E = hl.S, hl.E
    local UP = hl.UP
    local dir = hl.hero_dir
    local hero_phase

    local function moveHero()
        cave[pos + dir]  = E.HERO
        state[pos + dir] = S.ACTIVE
        phase[pos + dir] = hero_phase
        call[pos + dir]  = 0
        cave[pos] = E.SPACE; state[pos] = S.NOTACTIVE; phase[pos] = 0
    end
    local function heroStop()
        hero_phase = hero_phase & 2
        phase[pos] = hero_phase
    end

    hl.actives = hl.actives + 1
    hl.post_mortal = hl.POST_MORTAL_TIME

    if hl.suicide > 0 then
        if hl.suicide > 1 then
            phase[pos] = (hl.suicide & 1) | 4
        else
            hl.sfx("expl")
            cave[pos] = E.EXPL; state[pos] = S.ACTIVE; phase[pos] = 0
        end
        return
    end

    if hl.dance > 0 then
        if hl.dance > 1 then
            phase[pos] = (hl.dance & 1) | 6
        else
            hl.mode = hl.MODE.CAVE_DONE
        end
        return
    end

    hero_phase = phase[pos]
    if dir == hl.LEFT then
        hero_phase = (hero_phase ~ 1) & 1
    elseif dir == hl.RIGHT then
        hero_phase = (hero_phase ~ 1) | 2
    elseif dir == hl.UP or dir == hl.DOWN then
        hero_phase = (hero_phase & 2) | (hero_phase ~ 1)
    end

    if dir ~= 0 then
        local target = cave[pos + dir]
        if target == E.BALOON or target == E.ROCK or target == E.BOMB then
            if cave[pos + dir * 2] == E.SPACE and state[pos + dir] == S.STATIC
                and state[pos + dir + UP] ~= S.FALLING
                and dir ~= hl.UP and dir ~= hl.DOWN then
                if (hl.counter & 1) == 1 then
                    cave[pos + dir * 2]  = cave[pos + dir]
                    state[pos + dir * 2] = state[pos + dir]
                    phase[pos + dir * 2] = phase[pos + dir]
                    call[pos + dir * 2]  = 0
                    moveHero()
                else
                    phase[pos] = hero_phase
                end
            else
                heroStop()
            end
        elseif target == E.SPACE or target == E.GRASS then
            moveHero()
        elseif target == E.LJUMP or target == E.RJUMP then
            if (target == E.LJUMP and dir == hl.LEFT)
                or (target == E.RJUMP and dir == hl.RIGHT) then
                local p = pos + dir
                local e = cave[p]
                while cave[p] == e do p = p + dir end
                if cave[p] == E.SPACE or cave[p] == E.GRASS then
                    hl.sfx("tunnel")
                    state[pos + dir] = S.ACTIVE
                    call[pos + dir] = 0
                    cave[pos] = E.SPACE; state[pos] = S.NOTACTIVE; phase[pos] = 0
                else
                    heroStop()
                end
            else
                heroStop()
            end
        elseif target == E.HEART then
            if state[pos + dir] == S.STATIC then
                hl.sfx("colect")
                moveHero()
                hl.hearts_num = hl.hearts_num - 1
            end
        elseif target == E.DOOR then
            if state[pos + dir] == S.OPENED then
                hl.sfx("door")
                moveHero()
                hl.dance = 16
                hl.won = true   -- genuine clear (vs. a dev skip) -> save progress
            else
                heroStop()
            end
        else
            heroStop()
        end
    else
        heroStop()
    end
end

-- animate (591): one simulation tick. Sweep the inner grid top-to-bottom,
-- left-to-right; the call[] guard stops an object moved this tick from being
-- processed again when the sweep reaches its new cell.
function hl.animate()
    local cave, state, call = hl.cave, hl.state, hl.call
    local S, E = hl.S, hl.E
    local CAVEX = hl.CAVEX

    hl.actives = 0           -- hero_dir is set by main before each animate()
    for i = 0, hl.N - 1 do call[i] = 1 end   -- FILL(call, 1)

    for y = 1, hl.CAVEY - 2 do
        for x = 1, hl.CAVEX - 2 do
            local pos = y * CAVEX + x
            if state[pos] ~= S.NOTACTIVE and call[pos] ~= 0 then
                local e = cave[pos]
                if e == E.HEART then hl.heartProc(pos)
                elseif e == E.DOOR then hl.doorProc(pos)
                elseif e == E.HERO then hl.heroProc(pos)
                elseif e == E.ROCK then hl.rockProc(pos)
                elseif e == E.BOMB then hl.bombProc(pos)
                elseif e == E.EXPL then hl.explProc(pos)
                elseif e == E.BALOON then hl.baloonProc(pos)
                elseif e == E.PLASMA then hl.plasmaProc(pos)
                elseif e == E.LJUMP or e == E.RJUMP then hl.jumpProc(pos)
                end
            end
        end
    end

    hl.counter = hl.counter + 1
    hl.post_mortal = hl.post_mortal - 1
    if hl.suicide > 0 then hl.suicide = hl.suicide - 1 end
    if hl.dance > 0 then hl.dance = hl.dance - 1 end
end
