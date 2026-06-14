-- Heartlight (1994) - Playdate port.
-- Title screen -> playable hero. D-pad moves the hero (walk/push/collect/tunnel);
-- collect every heart to open the exit, step through it to win -> next cave.
-- Controls: A = start (on title); D-pad = move; B = restart cave (suicide);
-- A + Left/Right = skip cave (dev). Win advances, death reloads (sequential).

import "CoreLibs/graphics"
import "elements"
import "grid"
import "cave"
import "sound"
import "sim"
import "render"
import "title"

local gfx <const> = playdate.graphics
local pd <const> = playdate

hl.tiles = assert(gfx.imagetable.new("images/HL"),
    "failed to load images/HL-table-16-16.png")
hl.levels = hl.parseLevels("levels/LEVELS.HL")
hl.current = 1
-- The original locks simulation + display at one constant rate (HL_PLAY.C
-- heartlight loop: animate(); display_cave(); wait until get_timer() >=
-- GAME_SPEED). The sound library (HL/SOUNDS) drives that timer: it programs PIT
-- channel 0 to 1193182/clock_divisor Hz, and the ISR adds 2 to the timer each
-- interrupt. During play clock_divisor = 140 (COVOX/ADLIB/BLASTER; SPEAKER and
-- SILENCE scale divisor and increment together to match). With GAME_SPEED=1920 a
-- frame is 960 interrupts: fps = 1193182 / 140 / (1920/2) = ~8.88. That
-- deliberate ~8.9 fps is the authentic cave speed -- reproduced here with a fixed
-- refresh rate + one sim step per frame. Raise hl.FPS for a livelier feel.
hl.FPS = 1193182 / 140 / (1920 / 2)   -- ~8.88 fps (matches the 1994 original)
playdate.display.setRefreshRate(hl.FPS)

local function startCave(i)
    if #hl.levels == 0 then return end
    hl.current = (i - 1) % #hl.levels + 1
    hl.getCave(hl.levels[hl.current], hl.current - 1)   -- caveNum is 0-based
    hl.playInit()
    hl.drawCave()
    hl.drawHud()
end

-- One-shot actions, polled every frame so a quick press isn't lost between the
-- slower sim ticks (HL_PLAY.C animate: Space+L/R navigates, Esc = suicide).
local function pollOneShots()
    if pd.buttonIsPressed(pd.kButtonA) then
        if pd.buttonJustPressed(pd.kButtonLeft) then hl.mode = hl.MODE.CAVE_BACK end
        if pd.buttonJustPressed(pd.kButtonRight) then hl.mode = hl.MODE.CAVE_DONE end
    end
    if pd.buttonJustPressed(pd.kButtonB) and hl.suicide == 0 and hl.dance == 0 then
        hl.suicide = 8
    end
end

-- Held D-pad -> hero_dir (last pressed wins, matching the C ordering). A acts as
-- a modifier for cave-skip, so it suppresses movement.
local function heroDir()
    if pd.buttonIsPressed(pd.kButtonA) then return 0 end
    local d = 0
    if pd.buttonIsPressed(pd.kButtonUp) then d = hl.UP end
    if pd.buttonIsPressed(pd.kButtonDown) then d = hl.DOWN end
    if pd.buttonIsPressed(pd.kButtonLeft) then d = hl.LEFT end
    if pd.buttonIsPressed(pd.kButtonRight) then d = hl.RIGHT end
    return d
end

hl.scene = "title"          -- "title" | "playing"
local titleFrame = 0

local function startGame()
    hl.scene = "playing"
    startCave(1)
end

-- System menu: bail back to the title screen.
pd.getSystemMenu():addMenuItem("title screen", function()
    hl.scene = "title"
    titleFrame = 0
end)

function playdate.update()
    if #hl.levels == 0 then
        gfx.clear(gfx.kColorBlack)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawTextAligned("No levels in levels/LEVELS.HL", 200, 110, kTextAlignment.center)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        return
    end

    if hl.scene == "title" then
        titleFrame = titleFrame + 1
        hl.drawTitle(titleFrame)
        if pd.buttonJustPressed(pd.kButtonA) then startGame() end
        return
    end

    -- Playing.
    pollOneShots()
    hl.hero_dir = heroDir()
    hl.animate()
    hl.drawCave()
    hl.drawHud()

    -- End-of-cave (HL_PLAY.C heartlight loop): win/skip advances, skip-back
    -- retreats, and a cleared board (hero dead, nothing else active) or a
    -- timed-out post_mortal reloads the current cave.
    if hl.mode == hl.MODE.CAVE_DONE then
        startCave(hl.current + 1)
    elseif hl.mode == hl.MODE.CAVE_BACK then
        startCave(hl.current - 1)
    elseif hl.actives == 0 or hl.post_mortal == 0 then
        startCave(hl.current)
    end
end
