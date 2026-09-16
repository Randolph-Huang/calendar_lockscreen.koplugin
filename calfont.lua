-- Font discovery + selection for the calendar lock screen.
--
-- Goal: NEVER hard-code a font file name again.  Whatever the user drops into
-- one of KOReader's font directories is discovered, ranked by weight, and can
-- be picked from a menu -- so changing the lock-screen font never needs a code
-- change.
--
-- How KOReader finds fonts (frontend/fontlist.lua):
--   * "./fonts" relative to the process working directory, plus
--   * FontSettings:getPath(); on Android that is "<external storage>/fonts"
--     and "<external storage>/koreader/fonts".
--   getFontList() returns full paths (e.g. "./fonts/Foo-Bold.otf"), and
--   Font:getFace() treats a name starting with "/" or "./" as a literal path,
--   which is what we hand it -- that bypasses KOReader's own name guessing.

local Font = require("ui/font")
local FontList = require("fontlist")
local logger = require("logger")

local calfont = {}

local SETTING_FONT = "calendar_lockscreen_font"          -- "" / unset = automatic
local SETTING_BOLD = "calendar_lockscreen_synth_bold"    -- extra synthesized bold

-- Weight tokens, MUST be ordered longest/most specific first: "semibold"
-- contains "bold", "ultrabold" contains "bold", "extralight" contains "light".
local WEIGHT_TOKENS = {
    { "ultrablack", 6 }, { "extrablack", 6 },
    { "ultraheavy", 6 }, { "extraheavy", 6 },
    { "ultrabold", 6 },  { "extrabold", 6 },
    { "black", 6 },      { "heavy", 6 },
    { "semibold", 4 },   { "demibold", 4 },
    { "bold", 5 },
    { "medium", 3 },
    { "regular", 2 },    { "normal", 2 }, { "book", 2 },
    { "ultralight", 1 }, { "extralight", 1 },
    { "light", 1 },      { "thin", 1 },
}

-- Filename fragments that indicate a font carries Chinese glyphs.  Matched as
-- plain substrings against the lowercased file name.
local CJK_HINTS = {
    "sourcehansans", "sourcehanserif", "sourcehan",
    "notosanscjk", "notoserifcjk", "notosanssc", "notoserifsc",
    "notosanstc", "notoseriftc", "droidsansfallback",
    "harmonyos", "misans", "opposans", "vivosans", "hyqihei",
    "wqy", "wenquanyi", "cjk",
    "simsun", "simhei", "songti", "heiti", "kaiti", "fangsong",
    "msyh", "pingfang", "lantinghei", "yozai",
    -- Chinese file names, as shipped by many font sites
    "思源", "黑体", "宋体", "楷体", "仿宋", "雅黑", "文泉驿",
}

local list_cache, catalog_cache
local resolve_cache = {}
local logged_lang

--------------------------------------------------------------- basic helpers

local function basename(path)
    return (path:gsub("\\", "/"):match("([^/]+)$")) or path
end

-- cruder weight for a lowercased name: 1 (thin) .. 6 (black/heavy)
function calfont.weightOf(low_name)
    for _, t in ipairs(WEIGHT_TOKENS) do
        if low_name:find(t[1], 1, true) then return t[2] end
    end
    return 2
end

-- HarfBuzz coverage, when KOReader has it: a positive "zh" answer is a reliable
-- "has Chinese glyphs".  We only ever use it to CONFIRM, never to reject (we
-- return nil when unknown), so an API change can't lock the user out of a font.
local function coverageSaysCJK(path)
    local ok, info = pcall(function()
        return FontList.fontinfo and FontList.fontinfo[path]
    end)
    if not ok or type(info) ~= "table" then return nil end
    for _, face in ipairs(info) do
        local langs = type(face) == "table" and face.langs or nil
        if type(langs) == "table" then
            for k, v in pairs(langs) do
                local s = type(k) == "string" and k or (type(v) == "string" and v or nil)
                if s and s:lower():match("^zh") then return true end
            end
        end
    end
    return nil
end

local function looksCJK(low_name)
    for _, hint in ipairs(CJK_HINTS) do
        if low_name:find(hint, 1, true) then return true end
    end
    return false
end

function calfont.isCJK(path, name)
    if coverageSaysCJK(path) then return true end
    return looksCJK((name or basename(path)):lower())
end

------------------------------------------------------------------ discovery

function calfont.getFontList()
    if list_cache then return list_cache end
    local ok, list = pcall(function() return FontList:getFontList() end)
    if not ok or type(list) ~= "table" then
        list = {}
    end
    list_cache = list
    return list_cache
end

-- Every known font, best candidate first: Chinese fonts outrank other scripts,
-- heavier cuts outrank lighter ones, italics are demoted.
function calfont.catalog()
    if catalog_cache then return catalog_cache end
    local out = {}
    for _, path in ipairs(calfont.getFontList()) do
        if type(path) == "string" then
            local name = basename(path)
            local low = name:lower()
            local weight = calfont.weightOf(low)
            local cjk = calfont.isCJK(path, name)
            local score = (cjk and 1000 or 0) + weight * 10
            if low:find("italic", 1, true) or low:find("oblique", 1, true) then
                score = score - 100
            end
            out[#out + 1] = {
                path = path, name = name, weight = weight, cjk = cjk,
                score = score, label = (name:gsub("%.[^.]+$", "")),
            }
        end
    end
    table.sort(out, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return a.name < b.name
    end)
    catalog_cache = out
    return catalog_cache
end

-- The automatic choice: the heaviest Chinese font we can find.
function calfont.autoPick()
    for _, e in ipairs(calfont.catalog()) do
        if e.cjk then return e end
    end
    return nil
end

------------------------------------------------------------- user selection

function calfont.getSelected()
    if not G_reader_settings then return "" end
    local ok, v = pcall(function() return G_reader_settings:readSetting(SETTING_FONT) end)
    if ok and type(v) == "string" then return v end
    return ""
end

function calfont.setSelected(name)
    if not G_reader_settings then return end
    pcall(function() G_reader_settings:saveSetting(SETTING_FONT, name or "") end)
    resolve_cache = {}
end

function calfont.isBoldEnabled()
    if not G_reader_settings then return false end
    local ok, v = pcall(function() return G_reader_settings:isTrue(SETTING_BOLD) end)
    return ok and v == true
end

function calfont.setBoldEnabled(on)
    if not G_reader_settings then return end
    pcall(function()
        if on then G_reader_settings:makeTrue(SETTING_BOLD)
        else G_reader_settings:makeFalse(SETTING_BOLD) end
    end)
end

-- The entry that will actually be used: manual choice if it still exists on
-- disk, otherwise the automatic pick.
function calfont.resolve()
    local sel = calfont.getSelected()
    if sel == "" then
        return calfont.autoPick()
    end
    if resolve_cache[sel] then return resolve_cache[sel] end

    local entry
    for _, e in ipairs(calfont.catalog()) do
        if e.name == sel then entry = e break end
    end
    if not entry then
        for _, e in ipairs(calfont.catalog()) do
            if e.path:find(sel, 1, true) then entry = e break end
        end
    end
    -- Not on disk (yet): still hand the bare name to KOReader, it may resolve it.
    entry = entry or { path = sel, name = sel, weight = 0, cjk = false, label = sel }
    resolve_cache[sel] = entry
    return entry
end

------------------------------------------------------------------ face open

local function log_choice(cand)
    if logged_lang == cand then return end
    logged_lang = cand
    pcall(function()
        local mode = calfont.getSelected() == "" and "auto" or "manual"
        logger.info("calendar_lockscreen: using font", cand, "(" .. mode .. ")")
    end)
end

-- Returns a usable face.  `size` is the value handed to Font:getFace() (i.e.
-- already divided by the DPI factor by the caller).
function calfont.openFace(size)
    local entry = calfont.resolve()
    local candidates = {}
    if entry then
        candidates[#candidates + 1] = entry.path
        if entry.name and entry.name ~= entry.path then
            candidates[#candidates + 1] = entry.name
        end
    end
    candidates[#candidates + 1] = "infofont"

    for _, cand in ipairs(candidates) do
        local ok, f = pcall(Font.getFace, Font, cand, size)
        if ok and f and f.ftsize then
            log_choice(cand)
            return f, cand
        end
    end
    log_choice("infofont")
    return Font:getFace("infofont", size), "infofont"
end

------------------------------------------------------------- cache control

-- KOReader caches the font list for the whole process, so a font dropped in
-- while it is running stays invisible.  Clearing the two tables makes the next
-- getFontList() re-scan the directories (fontinfo itself is cached on disk per
-- file change, so only new files get parsed).
function calfont.rescan()
    local ok = pcall(function()
        FontList.fontlist = {}
        FontList.fontnames = {}
    end)
    list_cache, catalog_cache = nil, nil
    resolve_cache = {}
    return ok
end

return calfont
