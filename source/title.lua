-- Title screen. Minimal front end (no player profiles, per the port scope): the
-- authentic "HEARTLIGHT PC" logo (the original LOGO.GGS, assembled from its 8x5
-- grid of 24x24 tiles and thresholded to 1-bit) plus a blinking start prompt.
hl = hl or {}

hl.logo = playdate.graphics.image.new("images/logo")   -- 192x120

function hl.drawTitle(frame)
    local gfx = playdate.graphics
    gfx.clear(gfx.kColorBlack)

    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    if hl.logo then
        local w = hl.logo:getSize()
        hl.logo:draw((400 - w) // 2, 22)
    end

    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("a puzzle game - 1994", 200, 152, kTextAlignment.center)
    gfx.drawTextAligned(string.format("%d caves", #hl.levels), 200, 168, kTextAlignment.center)

    -- blinking prompt (~1.4 s period at 8.88 fps)
    if (frame // 6) % 2 == 0 then
        gfx.drawTextAligned("Press A to start", 200, 198, kTextAlignment.center)
    end
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end
