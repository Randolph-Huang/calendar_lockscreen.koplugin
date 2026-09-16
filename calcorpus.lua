-- Loader for the HUMAN-VERIFIED quote corpus.
--
-- Design decision (2026-09-14): the plugin used to ask a user-configured AI
-- for the daily quote, but generative models hallucinate -- they fabricate
-- "classical poems" and "famous quotes" that sound right but have no real
-- source.  That is unfixable from the prompt side, so we dropped AI entirely.
-- Every entry is a real, well-known line, so the lockscreen can never show a
-- made-up one.  No network, no key, no latency.
--
-- The corpus lives in THREE PLAIN TEXT FILES next to this module so the USER
-- can replace the content without writing any Lua:
--   * poems.txt   -- 诗词 (complete couplets, 一联)
--   * quotes.txt  -- 名言警句 (real quotations)
--   * lines.txt   -- 著名台词 (famous film / TV / theatre lines; TWO lines)
-- Edit those files and restart KOReader -- done.  Per-line format:
--   * one entry per line;
--   * blank lines and lines starting with '#' are ignored (use '#' for notes);
--   * an optional " | 出处" suffix:
--       - for poems.txt / quotes.txt it is STRIPPED (kept for yourself only,
--         it never reaches the screen);
--       - for lines.txt it is the SOURCE shown on the FIRST line (e.g. 阿甘正传),
--         and the line itself is the quote shown on the SECOND line -- the
--         著名台词 type renders as two lines (source above, line below).
-- If a file is missing or empty, a tiny built-in fallback keeps the plugin
-- from showing nothing.
local M = {}

local logger = require("logger")

-- Directory of this very file, so we find poems.txt / quotes.txt / lines.txt
-- no matter where the plugin is installed (the .koplugin folder is a dir).
local function selfDir()
    local src = debug.getinfo(1, "S").source
    src = src:gsub("^@", "")                 -- strip the leading '@'
    return (src:match("(.*[/\\])") or "./")
end

-- Read a corpus file into a list of bare lines (the optional " | 出处" note is
-- stripped).  Returns nil on any failure (missing / empty) so the caller falls
-- back.  Used by poems.txt and quotes.txt.
local function loadLines(name)
    local path = selfDir() .. name
    local f, err = io.open(path, "r")
    if not f then
        logger.warn("calendar_lockscreen: corpus file not found, using fallback:",
                    path, err or "")
        return nil
    end
    local out = {}
    for raw in f:lines() do
        local line = raw:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" and line:sub(1, 1) ~= "#" then
            -- Keep only the part before an optional " | 出处" note.
            local q = line:match("^([^|]*)")
            q = q:gsub("^%s+", ""):gsub("%s+$", "")
            if q ~= "" then out[#out + 1] = q end
        end
    end
    f:close()
    if #out == 0 then
        logger.warn("calendar_lockscreen: corpus file is empty, using fallback:", path)
        return nil
    end
    return out
end

-- Read lines.txt into a list of { text = line, source = 出处 } tables.  The
-- " | 出处" suffix is the SOURCE shown above the line (two-line layout), so it
-- is kept here (not stripped like the other two files).
local function loadLinesWithSource(name)
    local path = selfDir() .. name
    local f, err = io.open(path, "r")
    if not f then
        logger.warn("calendar_lockscreen: lines.txt not found, using fallback:",
                    path, err or "")
        return nil
    end
    local out = {}
    for raw in f:lines() do
        local line = raw:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" and line:sub(1, 1) ~= "#" then
            local text, source = line:match("^([^|]*)%s*|%s*(.*)$")
            if not text then text, source = line, "" end
            text = text:gsub("^%s+", ""):gsub("%s+$", "")
            source = source:gsub("^%s+", ""):gsub("%s+$", "")
            if text ~= "" then
                out[#out + 1] = { text = text, source = source }
            end
        end
    end
    f:close()
    if #out == 0 then
        logger.warn("calendar_lockscreen: lines.txt is empty, using fallback:", path)
        return nil
    end
    return out
end

-- Tiny built-in fallback so the plugin never shows nothing if the TXT files
-- are missing or empty.  Replace content via the TXT files, not here.
local FALLBACK_POEMS = {
    "床前明月光，疑是地上霜。",
    "春眠不觉晓，处处闻啼鸟。",
    "白日依山尽，黄河入海流。",
}
local FALLBACK_QUOTES = {
    "学而不思则罔，思而不学则殆。",
    "千里之行，始于足下。",
    "知识就是力量。",
}
local FALLBACK_LINES = {
    { text = "生活就像一盒巧克力，你永远不知道下一颗是什么味道。", source = "阿甘正传" },
    { text = "要么忙着活，要么忙着死。", source = "肖申克的救赎" },
}

M.poems  = loadLines("poems.txt")  or FALLBACK_POEMS
M.quotes = loadLines("quotes.txt") or FALLBACK_QUOTES
M.lines  = loadLinesWithSource("lines.txt") or FALLBACK_LINES

---------------------------------------------------- deterministic selection
-- djb2 string hash, kept inside 32 bits.  Stable across runs/devices, so the
-- same date always maps to the same entry.
local function hash(s)
    local h = 5381
    for i = 1, #s do
        h = (h * 33 + s:byte(i, i)) % 4294967296
    end
    return h
end

local function pickFrom(list, date, offset)
    if #list == 0 then return nil end
    local idx = (hash(date) + (offset or 0)) % #list
    return list[idx + 1]
end

-- Pick today's line for the chosen kind.  offset lets "换一条" walk to the
-- next entry deterministically (same day + higher offset -> next line).
function M.pick(kind, date, offset)
    offset = offset or 0
    if kind == "诗词" then
        return pickFrom(M.poems, date, offset)
    elseif kind == "名言警句" then
        return pickFrom(M.quotes, date, offset)
    elseif kind == "著名台词" then
        local e = pickFrom(M.lines, date, offset)
        if type(e) == "table" then
            -- Only the line itself is shown on the lockscreen; the source
            -- (出处) is kept in lines.txt as a note but is NOT displayed.
            return e.text
        end
        return nil
    end
    -- 随机: a single pool of poems + quotes (lines are shown two-line, so they
    -- are NOT mixed into the single-line 随机 pool).
    local pool = {}
    for _, v in ipairs(M.poems) do pool[#pool + 1] = v end
    for _, v in ipairs(M.quotes) do pool[#pool + 1] = v end
    return pickFrom(pool, date, offset)
end

-- Number of distinct lines for a kind (used by tests / future UI).
function M.count(kind)
    if kind == "诗词" then return #M.poems end
    if kind == "名言警句" then return #M.quotes end
    if kind == "著名台词" then return #M.lines end
    return #M.poems + #M.quotes
end

return M
