-- Level loading: parse LEVELS.HL and materialize a level into the shared grid.
-- Port of HL_CAV.C get_cave (lines 383-475) over the 22x14 bordered grid.
hl = hl or {}

-- Parse LEVELS.HL: skip the legend header, collect each '{' .. '}' block
-- (preceded by an optional 'author:' line). Row text is kept raw -- spaces are
-- significant -- and only padded/clipped when laid into the grid.
function hl.parseLevels(path)
    local f = assert(playdate.file.open(path, playdate.file.kFileRead),
        "cannot open " .. path)
    local levels, body, pendingAuthor = {}, nil, nil
    while true do
        local line = f:readline()
        if line == nil then break end
        local stripped = line:match("^%s*(.-)%s*$")
        if body == nil then
            local a = line:match("^%s*author:%s*(.-)%s*$")
            if a then
                pendingAuthor = a
            elseif stripped == "{" then
                body = {}
            end
        elseif stripped == "}" then
            levels[#levels + 1] = { author = pendingAuthor, rows = body }
            body, pendingAuthor = nil, nil
        else
            body[#body + 1] = line
        end
    end
    f:close()
    return levels
end

-- get_cave: fill the grid with METAL (border), then lay the level's inner 20x12
-- from its text, setting each cell's element + initial state + initial phase per
-- get_cave. Returns the heart count. caveNum is 0-based (drives brick variant).
function hl.getCave(level, caveNum)
    local E, S = hl.E, hl.S
    local CAVEX = hl.CAVEX
    local cave, state, phase = hl.cave, hl.state, hl.phase

    hl.gridClear(E.METAL)
    local hearts = 0
    local rows = level.rows

    for y = 0, hl.INNER_H - 1 do
        local line = rows[y + 1] or ""
        for x = 0, hl.INNER_W - 1 do
            local ch = line:sub(x + 1, x + 1)
            if ch == "" then ch = " " end
            local pos = (1 + y) * CAVEX + (1 + x)
            if ch == " " then
                cave[pos] = E.SPACE
            elseif ch == "#" then
                cave[pos] = E.BRICK
                phase[pos] = caveNum % 4
            elseif ch == "%" then
                cave[pos] = E.METAL
            elseif ch == "@" then
                cave[pos] = E.ROCK;   state[pos] = S.STATIC
            elseif ch == "$" then
                cave[pos] = E.HEART;  state[pos] = S.STATIC
                phase[pos] = math.random(0, 5)
                hearts = hearts + 1
            elseif ch == "*" then
                cave[pos] = E.HERO;   state[pos] = S.ACTIVE
                phase[pos] = (x < hl.INNER_W // 2) and 2 or 0   -- facing
            elseif ch == "!" then
                cave[pos] = E.DOOR;   state[pos] = S.CLOSED
            elseif ch == "&" then
                cave[pos] = E.BOMB;   state[pos] = S.STATIC
            elseif ch == "." then
                cave[pos] = E.GRASS
            elseif ch == "0" then
                cave[pos] = E.BALOON; state[pos] = S.STATIC
                phase[pos] = math.random(0, 3)
            elseif ch == "=" then
                cave[pos] = E.PLASMA; state[pos] = S.STATIC
            elseif ch == "<" then
                cave[pos] = E.LJUMP;  state[pos] = S.STATIC
            elseif ch == ">" then
                cave[pos] = E.RJUMP;  state[pos] = S.STATIC
            else
                cave[pos] = E.METAL;  state[pos] = S.STATIC
            end
        end
    end

    hl.hearts_num = hearts
    hl.start_hearts_num = hearts
    return hearts
end
