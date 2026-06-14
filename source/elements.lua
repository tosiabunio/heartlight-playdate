-- Element / state enums and sprite mapping. Authoritative: HL.H (enums),
-- HL.C read_sprites (shapes[]/frames), HL_CAV.C get_cave (CHARMAP).
hl = hl or {}

-- enum element (HL.H)
hl.E = {
    SPACE = 0, EXPL = 1, BRICK = 2, METAL = 3, ROCK = 4, HEART = 5, BOMB = 6,
    GRASS = 7, HERO = 8, DOOR = 9, BALOON = 10, PLASMA = 11, LJUMP = 12,
    RJUMP = 13, OBJECTS_NUM = 14,
}

-- enum states (HL.H)
hl.S = {
    NOTACTIVE = 0, ACTIVE = 1, STATIC = 2, FALLING = 3, BLASTING = 4,
    CLOSED = 5, OPENED = 6, FLYING = 7, FIRED = 8,
}

-- enum game_mode (HL.H). Only GAME_OK / CAVE_DONE / CAVE_BACK are used by the
-- port; CAVE_DONE = win or skip-forward, CAVE_BACK = skip-back.
hl.MODE = {
    INITIALIZATION = 0, GAME_OK = 1, SELECT_PLAYER = 2, QUIT_GAME = 3,
    QUIT_PART = 4, HERO_DEAD = 5, CAVE_DONE = 6, CAVE_BACK = 7, QUIT_NOW = 8,
}

-- Base atlas slot per element. Per HL.C read_sprites, the engine packs sprites
-- into a dense spr_num order, keeping only slots with states[0] != 0; for the HL
-- set every slot qualifies, so spr_num == GGS slot and these are the raw slots
-- (== the atlas cell index). A tile's cell = shapes[e] + phase[pos].
hl.shapes = {
    [hl.E.SPACE] = 0,  [hl.E.EXPL] = 9,   [hl.E.BRICK] = 56, [hl.E.METAL] = 60,
    [hl.E.ROCK] = 8,   [hl.E.HEART] = 1,  [hl.E.BOMB] = 61,  [hl.E.GRASS] = 7,
    [hl.E.HERO] = 16,  [hl.E.DOOR] = 24,  [hl.E.BALOON] = 28, [hl.E.PLASMA] = 32,
    [hl.E.LJUMP] = 40, [hl.E.RJUMP] = 48,
}

-- Animation frame count per element (consecutive slots sharing states[0]).
hl.frames = {
    [hl.E.SPACE] = 1, [hl.E.EXPL] = 7,  [hl.E.BRICK] = 4,  [hl.E.METAL] = 1,
    [hl.E.ROCK] = 1,  [hl.E.HEART] = 6, [hl.E.BOMB] = 2,   [hl.E.GRASS] = 1,
    [hl.E.HERO] = 8,  [hl.E.DOOR] = 4,  [hl.E.BALOON] = 4, [hl.E.PLASMA] = 8,
    [hl.E.LJUMP] = 8, [hl.E.RJUMP] = 8,
}

-- Level char -> element (READROOM.C okChars / HL_CAV.C get_cave).
hl.CHARMAP = {
    [" "] = hl.E.SPACE, ["#"] = hl.E.BRICK, ["%"] = hl.E.METAL,
    ["@"] = hl.E.ROCK,  ["$"] = hl.E.HEART, ["*"] = hl.E.HERO,
    ["!"] = hl.E.DOOR,  ["&"] = hl.E.BOMB,  ["."] = hl.E.GRASS,
    ["0"] = hl.E.BALOON, ["="] = hl.E.PLASMA,
    ["<"] = hl.E.LJUMP, [">"] = hl.E.RJUMP,
}
