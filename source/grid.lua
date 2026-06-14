-- The shared cave grid: four parallel 0-based arrays indexed pos = y*CAVEX + x,
-- exactly as the C engine (HL.H). The grid is 22x14 with a 1-cell border around
-- the visible 20x12 play area. Directions are grid offsets so the C physics
-- ports verbatim. INDEXING CONVENTION: positions are 0-based (0 .. N-1); Lua
-- tables hold index 0 fine since we never use the # length operator on them.
hl = hl or {}

hl.CAVEX, hl.CAVEY = 22, 14
hl.INNER_W, hl.INNER_H = hl.CAVEX - 2, hl.CAVEY - 2   -- 20 x 12 visible
hl.N = hl.CAVEX * hl.CAVEY

-- enum dirs (HL.H): grid offsets
hl.LEFT, hl.RIGHT, hl.UP, hl.DOWN = -1, 1, -hl.CAVEX, hl.CAVEX

hl.cave  = {}
hl.state = {}
hl.phase = {}
hl.call  = {}

-- FILL(cave, e) + reset state/phase/call (HL_CAV.C get_cave preamble).
function hl.gridClear(e)
    local cave, state, phase, call = hl.cave, hl.state, hl.phase, hl.call
    local notactive = hl.S.NOTACTIVE
    for i = 0, hl.N - 1 do
        cave[i] = e
        state[i] = notactive
        phase[i] = 0
        call[i] = 0
    end
end
