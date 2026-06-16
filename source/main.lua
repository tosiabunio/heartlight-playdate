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
import "save"

local gfx <const> = playdate.graphics
local pd <const> = playdate

hl.tiles = assert(gfx.imagetable.new("images/HL"),
    "failed to load images/HL-table-16-16.png")

-- Use the A.B. Cop bitmap font for all text/numbers (uppercase + digits + a few
-- symbols only). Set as the default so every drawText picks it up.
local font = gfx.font.new("fonts/A.B. Cop")
if font then gfx.setFont(font) end

hl.levels = hl.parseLevels("levels/LEVELS.HL")
hl.current = 1
hl.loadProgress()           -- restore which levels were previously completed
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

-- Cave-to-cave slide (HL_PLAY.C next_cave/previous_cave scroll the screen to
-- reveal the new cave). Snapshot the old screen, load + draw the new one, then
-- slide both across. The slide runs at 30 fps (gameplay's ~8.9 fps is too coarse
-- for smooth motion). dir +1 = forward (new enters from the right), -1 = back.
local TRANS_FRAMES <const> = 16
local trans = nil   -- { old, new, dir, frame }

-- Draw the current slide position. frame 0 = old fully on screen (off 0);
-- frame TRANS_FRAMES = new fully on screen (off 400). The two snapshots always
-- tile the full 400px width together, so no clear is needed.
local function drawTransition()
    local off = (trans.frame * 400) // TRANS_FRAMES
    if trans.dir > 0 then           -- forward: old slides out left, new in from right
        trans.old:draw(-off, 0)
        trans.new:draw(400 - off, 0)
    else                            -- back: old slides out right, new in from left
        trans.old:draw(off, 0)
        trans.new:draw(off - 400, 0)
    end
end

-- Render the CURRENT cave (whatever is in the grid right now) into its own
-- offscreen image. We can't use gfx.getDisplayImage() here: mid-update() it
-- returns the already-displayed front buffer, so it would not reflect the cave
-- we just drew -- old and new would both capture the old scene.
local function snapshotScene()
    local img = gfx.image.new(400, 240)
    gfx.pushContext(img)
    hl.drawCave()
    hl.drawHud()
    gfx.popContext()
    return img
end

local function beginTransition(newIndex, dir)
    local old = snapshotScene()         -- grid still holds the OLD cave here
    startCave(newIndex)                 -- load the new cave into the grid
    local new = snapshotScene()         -- now the grid holds the NEW cave
    trans = { old = old, new = new, dir = dir, frame = 0 }
    hl.scene = "transition"
    playdate.display.setRefreshRate(30)
    -- Draw frame 0 (old fully visible) so the slide starts from the old cave.
    drawTransition()
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
    hl.playMusic("game")
end

-- System menu: bail back to the title screen, and a music on/off toggle.
local menu = pd.getSystemMenu()
menu:addMenuItem("title screen", function()
    hl.scene = "title"
    titleFrame = 0
end)
menu:addCheckmarkMenuItem("music", true, function(on) hl.setMusicEnabled(on) end)
menu:addMenuItem("reset progress", function() hl.resetProgress() end)

function playdate.update()
    if #hl.levels == 0 then
        gfx.clear(gfx.kColorBlack)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawTextAligned("NO LEVELS FOUND", 200, 110, kTextAlignment.center)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        return
    end

    if hl.scene == "title" then
        hl.playMusic("title")
        titleFrame = titleFrame + 1
        hl.drawTitle(titleFrame)
        if pd.buttonJustPressed(pd.kButtonA) then startGame() end
        return
    end

    if hl.scene == "transition" then
        trans.frame = trans.frame + 1
        drawTransition()                 -- frame TRANS_FRAMES => new fully on screen
        if trans.frame >= TRANS_FRAMES then
            trans = nil
            hl.scene = "playing"
            playdate.display.setRefreshRate(hl.FPS)
        end
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
        if hl.won then hl.markCompleted(hl.current) end   -- real clear, not a skip
        beginTransition(hl.current + 1, 1)
    elseif hl.mode == hl.MODE.CAVE_BACK then
        beginTransition(hl.current - 1, -1)
    elseif hl.actives == 0 or hl.post_mortal == 0 then
        startCave(hl.current)            -- death: instant reload (no slide)
    end
end
