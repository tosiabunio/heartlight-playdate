-- Sound effects. Plays the converted .SND samples (source/sounds/*.wav, 8-bit
-- 8523 Hz mono) at the points the original engine fires SOUND() in HL_PLAY.C.
-- hl.sfx(name) plays a one-shot; "heart" picks a random heart0..3 (the original
-- plays one of four heart-landing samples at random). Music is not handled here.
hl = hl or {}

local snd = playdate.sound

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
