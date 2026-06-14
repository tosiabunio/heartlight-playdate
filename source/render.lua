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

-- HUD: level number (top-left) and a heart icon + remaining count (top-right) in
-- the black top margin; author credit centered in the bottom margin.
function hl.drawHud()
    local gfx = playdate.graphics

    -- The A.B. Cop font is uppercase only (no / - : . or lowercase), so all HUD
    -- text is uppercase and avoids those characters.
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText(string.format("LEVEL %d OF %d", hl.current, #hl.levels), 44, 8)

    -- heart icon (drawn in its own colours) + remaining count
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    local heart = hl.tiles:getImage(hl.shapes[hl.E.HEART] + 1)
    if heart then heart:draw(312, 4) end
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText(tostring(hl.hearts_num or 0), 332, 8)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end
