-- Progress persistence: which levels the player has completed. Saved to the
-- Playdate datastore (progress.json) so it survives across sessions. The set is
-- keyed by 1-based level number. datastore serializes via JSON, so keys round-
-- trip as strings (or array indices); we always write string keys and normalize
-- back to numbers on load.
hl = hl or {}

local SAVE_FILE <const> = "progress"

hl.progress = { completed = {} }

local function normalize(t)
    local out = {}
    if type(t) == "table" then
        for k, v in pairs(t) do
            if v then
                local n = tonumber(k)
                if n then out[n] = true end
            end
        end
    end
    return out
end

function hl.loadProgress()
    local data = playdate.datastore.read(SAVE_FILE)
    if data and data.completed then
        hl.progress.completed = normalize(data.completed)
    else
        hl.progress.completed = {}
    end
end

function hl.saveProgress()
    local completed = {}
    for k in pairs(hl.progress.completed) do
        completed[tostring(k)] = true   -- string keys -> stable JSON object
    end
    playdate.datastore.write({ completed = completed }, SAVE_FILE)
end

function hl.isCompleted(i)
    return hl.progress.completed[i] == true
end

-- Mark level i (1-based) completed and persist. No-op if already recorded.
function hl.markCompleted(i)
    if not hl.progress.completed[i] then
        hl.progress.completed[i] = true
        hl.saveProgress()
    end
end

function hl.completedCount()
    local n = 0
    for _ in pairs(hl.progress.completed) do n = n + 1 end
    return n
end

function hl.resetProgress()
    hl.progress.completed = {}
    hl.saveProgress()
end
