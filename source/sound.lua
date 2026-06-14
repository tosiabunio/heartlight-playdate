-- Sound: effects + music. Plays the converted samples (source/sounds/*.wav,
-- 8-bit 8523 Hz mono) where the original engine fires SOUND()/play_sample().
-- SFX: hl.sfx(name) one-shots ("heart" -> random heart0..3, like the original).
-- Music: the title track is TITLE.SND looped; the game track is the gsong note
-- chain pre-rendered to one looping sample (see conversion/convert_music.py).
hl = hl or {}

local snd = playdate.sound

-- --- effects ---------------------------------------------------------------
local NAMES = {
    "rock", "rocgrass", "heart0", "heart1", "heart2", "heart3", "hrtgrass",
    "expl", "colect", "colected", "tunnel", "door", "key",
}
local players = {}
for _, n in ipairs(NAMES) do
    local sample = snd and snd.sample.new("sounds/" .. n)
    if sample then players[n] = snd.sampleplayer.new(sample) end
end

function hl.sfx(name)
    if name == "heart" then name = "heart" .. math.random(0, 3) end
    local p = players[name]
    if p then p:play() end
end

-- --- music -----------------------------------------------------------------
local music = {}
if snd then
    music.title = snd.sampleplayer.new("sounds/title_music")
    music.game = snd.sampleplayer.new("sounds/game_music")
end
local current = nil          -- "title" | "game" | nil
local musicOn = true

-- Switch to (and loop) a track. Called every frame for the active scene, so it
-- no-ops when already on that track -- never restarts.
function hl.playMusic(which)
    if current == which then return end
    current = which
    for k, p in pairs(music) do
        if k ~= which then p:stop() end
    end
    local p = music[which]
    if p and musicOn then p:play(0) end   -- 0 = loop forever
end

function hl.setMusicEnabled(on)
    musicOn = on
    local p = current and music[current]
    if not p then return end
    if on then p:play(0) else p:stop() end
end
