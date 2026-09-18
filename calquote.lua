-- Daily quote ("每日金句") for the calendar lockscreen.
--
-- Contract:
--   * the quote is picked LOCALLY from a bundled, human-verified corpus
--     (calcorpus.lua) -- no AI, no network, no hallucination;
--   * selection is DETERMINISTIC per calendar day: the same day always shows
--     the same line for a given type, so the lockscreen never changes mid-day;
--   * the user picks a quote type in the menu (诗词/名言警句/著名台词/歌词/随机);
--   * the user picks the quote font size (6-14 mock px, default 12);
--   * "换一条" advances an offset so the user can walk to another line today;
--   * the lockscreen asks M.dailyQuote() for the text when it builds.
--
-- Why no AI: generative models fabricate "poems" and "famous quotes" that
-- sound right but have no real source.  That cannot be fixed by prompt
-- wording, so the source of truth is a curated corpus instead.
local logger = require("logger")
local UIManager = require("ui/uimanager")
local corpus = require("calcorpus")

local KEY_QUOTE = "calendar_lockscreen_quote"
local KEY_KIND = "calendar_lockscreen_ai"        -- selected quote type (legacy key name kept)
local KEY_OFFSET = "calendar_lockscreen_quote_offset"
local KEY_SIZE = "calendar_lockscreen_quote_size"  -- quote font size (mock px, 6-14)

local M = {}

-- Quote types shown in the menu.  KIND_POOL drives the 随机 pick.
M.KINDS = { "诗词", "名言警句", "著名台词", "歌词", "随机" }

-- Quote font size, in mock px.  Default 12, clamped to 6-14.  The calendar's
-- other text (date, weekday, lunar) is NOT affected by this setting.
function M.quoteSize()
    local n = G_reader_settings:readSetting(KEY_SIZE)
    if type(n) == "number" and n >= 6 and n <= 14 then return n end
    return 12
end

function M.setQuoteSize(n)
    if type(n) == "number" then
        n = math.max(6, math.min(14, math.floor(n + 0.5)))
        G_reader_settings:saveSetting(KEY_SIZE, n)
    end
end

-- The lockscreen widget currently on screen, if any.  Set by calendarscreen.lua
-- in its init() and cleared on close, so a "换一条" can repaint the visible
-- lockscreen immediately.
local live_screen = nil

function M.setScreen(w)
    live_screen = w
end

function M.clearScreen()
    live_screen = nil
end

-- Today's local date, "YYYY-MM-DD".  This is the freshness key.
function M.today()
    return os.date("%Y-%m-%d")
end

------------------------------------------------------------- type selection
-- The selected type lives in one settings table so it survives as a unit.
function M.config()
    local c = G_reader_settings:readSetting(KEY_KIND)
    if type(c) ~= "table" then c = {} end
    return c
end

function M.setConfig(field, value)
    local c = M.config()
    c[field] = value
    G_reader_settings:saveSetting(KEY_KIND, c)
end

-- The selected quote type; defaults to 随机.  Only values from M.KINDS win.
function M.selectedKind()
    local sel = M.config().kind
    for _, k in ipairs(M.KINDS) do
        if k == sel then return k end
    end
    return "随机"
end

function M.setKind(kind)
    for _, k in ipairs(M.KINDS) do
        if k == kind then
            M.setConfig("kind", kind)
            return
        end
    end
end

---------------------------------------------------------- daily rotate offset
-- "换一条" walks to the next line of the same day by bumping this offset, so
-- the choice is stable across lock cycles and resets on the next day.
local function offsetToday()
    local o = G_reader_settings:readSetting(KEY_OFFSET)
    if type(o) == "table" and o.date == M.today() and type(o.n) == "number" then
        return o.n
    end
    return 0
end

local function bumpOffset()
    local n = offsetToday() + 1
    G_reader_settings:saveSetting(KEY_OFFSET, { date = M.today(), n = n })
    return n
end

----------------------------------------------------- quote decor stripping
-- Peel any WRAPPING quotes off both ends of the sentence (repeatedly, so a
-- doubly-wrapped answer is cleaned too).  Covers ASCII " ' and the full-width
-- styles " " ' ' 「」 『』.  The corpus is already clean, but this guards
-- against any future hand-edit.  Internal quotes are left untouched.
local function stripWrappingQuotes(s)
    while true do
        local before = s
        s = s:gsub('^"', ""):gsub('"$', "")   -- ASCII straight quotes
        s = s:gsub("^'", ""):gsub("'$", "")   -- ASCII single quotes
        s = s:gsub('^“', ""):gsub('”$', "")   -- full-width “ ”
        s = s:gsub("^‘", ""):gsub("’$", "")   -- full-width ‘ ’
        s = s:gsub('^「', ""):gsub('」$', "")
        s = s:gsub('^『', ""):gsub('』$', "")
        s = s:gsub("^%s+", ""):gsub("%s+$", "")
        if s == before then break end
    end
    return s
end

-------------------------------------------------------------- deterministic
-- Pick the day's line for the selected kind at the current offset.
local function compute(kind)
    local t = corpus.pick(kind, M.today(), offsetToday())
    if type(t) ~= "string" then return nil end
    return stripWrappingQuotes(t)
end

-- Cache today's quote so lock cycles and "换一条" agree.  Invalidated by date
-- (next day) or type change (different kind -> different line).
function M.dailyQuote()
    local kind = M.selectedKind()
    local q = G_reader_settings:readSetting(KEY_QUOTE)
    if type(q) == "table" and q.date == M.today() and q.kind == kind
       and type(q.text) == "string" and q.text ~= "" then
        return q.text
    end
    local text = compute(kind)
    if text and text ~= "" then
        G_reader_settings:saveSetting(KEY_QUOTE,
            { date = M.today(), kind = kind, text = text })
        return text
    end
end

-- Change today's quote to the next line (manual "换一条金句").
-- Repaints a visible lockscreen so the swap shows without re-locking.
function M.rotate()
    bumpOffset()
    local kind = M.selectedKind()
    local text = compute(kind)
    if text and text ~= "" then
        G_reader_settings:saveSetting(KEY_QUOTE,
            { date = M.today(), kind = kind, text = text })
    end
    if live_screen then
        pcall(function() live_screen:refreshQuote() end)
    end
    return M.dailyQuote()
end

return M
