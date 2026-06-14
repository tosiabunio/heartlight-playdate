-- Sound stub. Phase 5 will play the HL/DATA/*.SND samples here; for now the
-- calls just mark where the original engine triggers effects (SOUND() macro in
-- HL_PLAY.C). No-op so the physics ports read 1:1 with the C.
hl = hl or {}

function hl.sfx(name) end   -- luacheck: ignore name
