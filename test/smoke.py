#!/usr/bin/env python3
# Headless integration smoke test. Loads the real Playdate Lua modules + main.lua
# in an embedded Lua (lupa), stubbing the `playdate` API and `import`, then drives
# input (press A to start, hold Right to move the hero) and fails on any Lua
# runtime error. This catches integration bugs the Simulator only reports to its
# own console. Requires: pip install lupa
import os
import sys
from lupa import LuaRuntime, LuaError

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "source")
LEVELS = os.path.join(SRC, "levels", "LEVELS.HL")
MODULES = ["elements", "grid", "cave", "sound", "sim", "render", "title"]

lua = LuaRuntime(unpack_returned_tuples=True)
print("Lua:", lua.eval("_VERSION"))

# --- input state, driven from Python ----------------------------------------
held, just = set(), set()
btn = dict(A=1, B=2, Up=3, Down=4, Left=5, Right=6)

g = lua.globals()
g["_isPressed"] = lambda b: b in held
g["_justPressed"] = lambda b: b in just
g["_levelLines"] = lua.table(*open(LEVELS, encoding="latin-1").read().split("\n"))

# --- playdate / runtime stubs ------------------------------------------------
lua.execute("""
local function noop() end
local fakeImg = { draw = noop, getSize = function() return 192, 120 end }
local fakeTable = { getImage = function(_, n) return fakeImg end }
kTextAlignment = { center = 0, left = 1, right = 2 }

local lineIdx = 0
local fileObj = {
    readline = function() lineIdx = lineIdx + 1; return _levelLines[lineIdx] end,
    close = noop,
}

playdate = {
    kButtonA = 1, kButtonB = 2, kButtonUp = 3, kButtonDown = 4,
    kButtonLeft = 5, kButtonRight = 6,
    buttonIsPressed   = function(b) return _isPressed(b) == true end,
    buttonJustPressed = function(b) return _justPressed(b) == true end,
    display = { setRefreshRate = noop },
    getSystemMenu = function() return { addMenuItem = noop, addCheckmarkMenuItem = noop } end,
    file = { kFileRead = 1, open = function() lineIdx = 0; return fileObj end },
    graphics = {
        kColorBlack = 0, kColorWhite = 1,
        kDrawModeCopy = 0, kDrawModeFillWhite = 1,
        clear = noop, setImageDrawMode = noop,
        drawText = noop, drawTextAligned = noop,
        getDisplayImage = function() return fakeImg end,
        imagetable = { new = function() return fakeTable end },
        image = { new = function() return fakeImg end },
    },
    sound = {
        sample = { new = function() return {} end },
        sampleplayer = { new = function() return { play = noop, stop = noop } end },
    },
}
""")

loaded = set()
def lua_import(name):
    if name.startswith("CoreLibs") or name in loaded:
        return
    loaded.add(name)
    path = os.path.join(SRC, name + ".lua")
    lua.execute(open(path, encoding="utf-8").read())
g["import"] = lua_import

try:
    for m in MODULES:
        lua_import(m)
    lua.execute(open(os.path.join(SRC, "main.lua"), encoding="utf-8").read())
except LuaError as e:
    print("FAIL: error loading modules/main:\n ", e)
    sys.exit(1)

update = g.playdate.update
hl = g.hl


def frame(label, hold=(), press=()):
    global held, just
    held = {btn[b] for b in hold}
    just = {btn[b] for b in press}
    try:
        update()
    except LuaError as e:
        print("FAIL during %s:\n  %s" % (label, e))
        sys.exit(1)


frame("title")
frame("title")
frame("press-A", press=("A",))
assert hl.scene == "playing", "A did not start the game (scene=%s)" % hl.scene
for i in range(40):
    frame("walk %d" % i, hold=("Right",))

# cave skip (A+Right -> CAVE_DONE) must trigger and complete a slide transition
frame("skip", hold=("A",), press=("Right",))
for i in range(20):
    frame("transition %d" % i)
assert hl.scene == "playing", "transition did not finish (scene=%s)" % hl.scene

print("OK: scene=%s cave=%d/%d hearts=%d mode=%s"
      % (hl.scene, hl.current, int(lua.eval("#hl.levels")), hl.hearts_num, hl.mode))
print("ALL SMOKE TESTS PASSED")
