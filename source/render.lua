-- Draw the cave grid. Port of HL_PLAY.C display_big: each inner cell's atlas
-- cell = shapes[cave[pos]] + phase[pos]. The 320x192 play area is centered on
-- the 400x240 screen (OX=40, OY=24); the 22x14 border ring is off-screen.
hl = hl or {}

hl.TILE = 16
hl.OX = (400 - hl.INNER_W * hl.TILE) // 2   -- 40
hl.OY = (240 - hl.INNER_H * hl.TILE) // 2   -- 24

function hl.drawCave()
    local gfx = playdate.graphics
    gfx.clear(gfx.kColorBlack)

    local cave, phase, shapes = hl.cave, hl.phase, hl.shapes
    local CAVEX, TILE, OX, OY = hl.CAVEX, hl.TILE, hl.OX, hl.OY
    local tiles = hl.tiles

    for y = 1, hl.INNER_H do
        for x = 1, hl.INNER_W do
            local pos = y * CAVEX + x
            local img = tiles:getImage(shapes[cave[pos]] + phase[pos] + 1)
            if img then
                img:draw(OX + (x - 1) * TILE, OY + (y - 1) * TILE)
            end
        end
    end
end

-- HUD: level number (top-left) and a heart icon + collected/required count
-- (top-right) in the black top margin; a "COMPLETED" badge centered in the
-- bottom margin when the current level has already been beaten.
function hl.drawHud()
    local gfx = playdate.graphics

    -- The A.B. Cop font is uppercase only (no / - : . or lowercase), so all HUD
    -- text is uppercase and avoids those characters.
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText(string.format("LEVEL %d OF %d", hl.current, #hl.levels), 44, 8)

    -- collected of required hearts, right-aligned to the level's right edge (not
    -- the screen edge), with the heart icon to its left. hearts_num counts down
    -- from start_hearts_num as hearts are taken.
    local rightEdge = hl.OX + hl.INNER_W * hl.TILE   -- 360 = right edge of play area
    local required = hl.start_hearts_num or 0
    local collected = required - (hl.hearts_num or 0)
    local txt = string.format("%d OF %d", collected, required)
    local w = gfx.getTextSize(txt)
    gfx.drawTextAligned(txt, rightEdge, 8, kTextAlignment.right)

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    local heart = hl.tiles:getImage(hl.shapes[hl.E.HEART] + 1)
    if heart then heart:draw(rightEdge - w - 18, 4) end

    -- completion status: shown when re-entering an already-cleared level.
    if hl.isCompleted and hl.isCompleted(hl.current) then
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawTextAligned("COMPLETED", 200, 220, kTextAlignment.center)
    end
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end
