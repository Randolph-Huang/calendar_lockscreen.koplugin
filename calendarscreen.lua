-- Calendar lock screen widget (pure Lua, offline).
--
-- The layout is a pixel-faithful port of the approved mock
-- (demo_calendar_lockscreen.html).  The mock's screen area is 310x420 CSS px,
-- so every metric here is
--     real_px = mock_px * (screen_height / 420)
-- which keeps the exact same proportions on any e-ink size.
--
-- Font sizes are additionally divided by the DPI factor of
-- Screen:scaleBySize(), because Font:getFace() multiplies the size back by it.
-- Without that compensation the very same plugin would render at a different
-- size on every screen DPI (which is why it did not match the mock before).
--
-- Mock typography (the "classic" style):
--     2026.9 -> 30px      day number -> 120px
--     weekday -> 30px     lunar line -> 15px
-- The status row keeps only the battery: the "锁定" label was removed on
-- request.  Colour scheme is fixed to black-on-white; there is no inverted
-- theme.
--
-- Fonts are never hard-coded: calfont.lua discovers every font KOReader can
-- see, ranks Chinese fonts by weight, and the plugin menu lets the user pick
-- one (see main.lua).  The automatic choice is the heaviest Chinese font
-- available; on top of that the user can ask for synthesized extra bold.

local Blitbuffer = require("ffi/blitbuffer")
local calfont = require("calfont")
local calquote = require("calquote")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local FrameContainer = require("ui/widget/container/framecontainer")
local LineWidget = require("ui/widget/linewidget")
local OverlapGroup = require("ui/widget/overlapgroup")
local RightContainer = require("ui/widget/container/rightcontainer")
local TextWidget = require("ui/widget/textwidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local lunar = require("cal_lunar")

local Screen = Device.screen
local UIManager = require("ui/uimanager")

-- Height of the mock's screen, in CSS px.  Everything is scaled from it.
local REF_H = 420

-- Font lookup lives in calfont.lua (discovery + user selection + fallbacks).

-- Convert a size expressed in *real screen pixels* into the value that must be
-- handed to Font:getFace(): it multiplies the size by the screen DPI factor
-- (Screen:scaleBySize()), so we solve for the size that renders back to `px`
-- real pixels.  We binary-search Screen:scaleBySize() instead of assuming its
-- formula, which keeps the result exact on any DPI.
local function dpi_size(px)
    local target = math.max(1, math.floor(px + 0.5))
    local ok, top = pcall(function() return Screen:scaleBySize(target) end)
    if not ok or type(top) ~= "number" or top < target then
        return target   -- no DPI scaling at all: the size is already in pixels
    end
    local lo, hi = 1, target
    while lo < hi do
        local mid = math.floor((lo + hi) / 2)
        local ok_m, sm = pcall(function() return Screen:scaleBySize(mid) end)
        if ok_m and type(sm) == "number" and sm >= target then
            hi = mid
        else
            lo = mid + 1
        end
    end
    return lo
end

-- One face for every row, chosen by calfont (manual pick, else automatic).
local function get_face(px)
    return calfont.openFace(dpi_size(px))
end

-- TextWidget gets bold=false by default: when the picked face already IS a
-- heavy cut, asking for bold on top would double-bold it.  The menu option
-- "extra bold" deliberately re-enables it -- KOReader then uses the real bold
-- variant when one exists, and synthesizes one otherwise.
local function want_bold()
    return calfont.isBoldEnabled()
end

-- Fixed colour scheme: black ink on white paper (the approved classic look).
-- NOTE: FrameContainer's own "invert" field is deliberately left untouched --
-- its paintTo() calls bb:invertRect() on the whole widget, which would flip
-- the entire screen.
local CalendarScreen = FrameContainer:extend{}

function CalendarScreen:init()
    local screen_w, screen_h = Screen:getWidth(), Screen:getHeight()
    self.screen_w, self.screen_h = screen_w, screen_h

    local fg = Blitbuffer.COLOR_BLACK
    local bg = Blitbuffer.COLOR_WHITE

    -- Today's date + lunar info, fully offline.
    local t = os.date("*t")
    local y, m, d = t.year, t.month, t.day
    local info = lunar.solar2lunar(y, m, d)

    local ym_text = string.format("%d.%d", y, m)          -- e.g. 2026.9
    local day_text = tostring(d)
    local week_text = info.weekCn                          -- 星期六
    local lunar_text = info.gzYear .. "年 " .. info.IMonthCn .. info.IDayCn
    if info.isTerm and info.Term then
        lunar_text = lunar_text .. " · " .. info.Term
    end

    local batt_txt = ""
    local ok, cap = pcall(function() return Device:getCapacity() end)
    if ok and type(cap) == "number" and cap >= 0 then
        batt_txt = tostring(cap) .. "%"
    end

    -- Daily quote: shown only when it was fetched today (calquote.lua decides).
    local quote_text = calquote.dailyQuote()
    local quote_fg = fg  -- black, same ink as the rest of the calendar

    -- Build the whole column for a given mock scale factor `k`.
    -- Returns the widget plus the *natural* content height/width: the group
    -- itself is always padded to the screen height by its trailing span, so the
    -- fit test must use these numbers instead of the group's own size.
    function CalendarScreen:build(k)
        -- Pull the screen dims from self so this method can be re-run from
        -- refreshQuote() (which rebuilds the whole content with the new quote).
        local screen_w, screen_h = self.screen_w, self.screen_h
        local function s(v) return math.max(1, math.floor(v * k + 0.5)) end   -- mock px -> real px
        local function fpx(v) return v * k end                                -- mock font px -> real px

        local items = {}
        local max_text_w = 0
        local function add(w) items[#items + 1] = w end

        -- Text with a CSS-like line box: forced_height = line-height, and the
        -- glyphs are vertically centred inside it.
        local function make_text(str, size_px, lh, color)
            local face = get_face(fpx(size_px))
            local line_h = math.max(1, math.floor(fpx(size_px) * lh + 0.5))
            local tw = TextWidget:new{
                text = str, face = face, bold = want_bold(),
                fgcolor = color or fg, padding = 0,
            }
            tw:updateSize()  -- also swaps in the real bold face, if any
            local face_h, ascender = line_h, line_h * 0.8
            local okm, h, a = pcall(function()
                return tw.face.ftsize:getHeightAndAscender()
            end)
            if okm and type(h) == "number" then
                face_h = math.ceil(h)
                ascender = a or ascender
            end
            tw.forced_height = line_h
            tw.forced_baseline = math.max(0, math.floor((line_h - face_h) / 2 + ascender + 0.5))
            local tw_w = tw:getSize().w
            if tw_w > max_text_w then max_text_w = tw_w end
            return tw
        end

        local function text_row(str, size_px, lh)
            local tw = make_text(str, size_px, lh)
            add(CenterContainer:new{
                dimen = { w = screen_w, h = tw.forced_height },
                tw,
            })
        end

        local function gap(v) add(VerticalSpan:new{ width = s(v) }) end

        local function rule()
            local th = math.max(2, s(1))
            add(CenterContainer:new{
                dimen = { w = screen_w, h = th },
                LineWidget:new{
                    dimen = { w = math.max(2, screen_w - 2 * s(24)), h = th },
                    background = fg,
                    style = "solid",
                },
            })
        end

        -- Status row: battery only, right aligned with the mock's 16px margin.
        local status_h = math.max(1, math.floor(fpx(12) * 1.2 + 0.5))
        local batt = make_text(batt_txt, 12, 1.2)
        add(OverlapGroup:new{
            dimen = { w = screen_w, h = status_h },
            RightContainer:new{
                dimen = { w = screen_w - s(16), h = status_h },
                batt,
            },
        })

        gap(28); rule(); gap(14)                      -- mock: .rule-top (28/14)
        text_row(ym_text, 30, 1.2)
        gap(8)
        text_row(day_text, 120, 0.9)                   -- mock: line-height .9
        gap(8)
        text_row(week_text, 30, 1.2)
        gap(16); rule(); gap(14)                       -- mock: .rule (14/14)
        text_row(lunar_text, 15, 1.2)

        -- Daily quote, pinned to the bottom edge:  [calendar rows] [flex]
        -- [quote rows] [bottom margin].  Layout rules:
        --   * the quote font size is user-selectable via calquote.quoteSize()
        --     (default 12, range 6-14) -- it does NOT affect the calendar;
        --   * a single-line type (诗词/名言警句/著名台词/随机) is wrapped by
        --     hand into AT MOST TWO lines; an overflowing second line is cut
        --     with an ellipsis -- behaviour does not depend on TextWidget's
        --     internal max_width handling;
        --   * the 歌词 type ships its text already split on "\n" (foreign above,
        --     Chinese below) and each line is clamped to the screen width on
        --     its own.
        local quote_row_h = 0
        local quote_widgets = nil
        if quote_text and quote_text ~= "" then
            local margin_w = screen_w - 2 * s(24)
            local qsize = calquote.quoteSize()
            local quote_max_w_before = max_text_w
            local function fits(str)
                local tw = make_text(str, qsize, 1.4, quote_fg)
                return tw:getSize().w <= margin_w, tw
            end
            -- Longest UTF-8 prefix that fits on ONE line.
            local function maxPrefix(str)
                local ok, tw = fits(str)
                if ok then return str, tw end
                while #str > 1 do
                    local cut = #str
                    if utf8 and utf8.offset then
                        cut = utf8.offset(str, -1) or (#str - 1)
                    else
                        cut = #str - 1
                    end
                    str = str:sub(1, cut - 1)
                    ok, tw = fits(str)
                    if ok then return str, tw end
                end
                return "", nil
            end
            -- Shortened with a trailing ellipsis so it fits ONE line.
            local function fitEllipsized(str)
                local ok, tw = fits(str)
                if ok then return str, tw end
                while #str > 1 do
                    local cut = #str
                    if utf8 and utf8.offset then
                        cut = utf8.offset(str, -1) or (#str - 1)
                    else
                        cut = #str - 1
                    end
                    str = str:sub(1, cut - 1)
                    ok, tw = fits(str .. "…")
                    if ok then return str .. "…", tw end
                end
                return nil, nil
            end

            -- Split into logical lines on "\n" (kept for the 歌词 two-line
            -- layout).  Strip a stray CR; enforce the two-line cap.
            local lines = {}
            for seg in (quote_text .. "\n"):gmatch("(.-)\n") do
                lines[#lines + 1] = seg:gsub("[\r]", "")
            end
            if #lines > 2 then lines = { lines[1], lines[2] } end

            local widgets = {}
            if #lines == 2 then
                -- 歌词 two-line layout: each line clamped on its own.
                local _, tw1 = fitEllipsized(lines[1])
                if tw1 then widgets[#widgets + 1] = tw1 end
                local _, tw2 = fitEllipsized(lines[2])
                if tw2 then widgets[#widgets + 1] = tw2 end
            else
                -- Single-line type: wrap into at most two lines; the overflowing
                -- second line is cut with an ellipsis.
                local text = lines[1] or ""
                local fill1, tw1 = maxPrefix(text)
                if tw1 then
                    widgets[#widgets + 1] = tw1
                    if #fill1 < #text then
                        local rest = text:sub(#fill1 + 1)
                        local _, tw2 = fitEllipsized(rest)
                        if tw2 then widgets[#widgets + 1] = tw2 end
                    end
                else
                    -- Even one glyph + ellipsis overflows: hard-cut prefix.
                    local l1, tw2 = maxPrefix(text)
                    if tw2 then widgets[#widgets + 1] = tw2 end
                end
            end

            if #widgets > 0 then
                quote_widgets = widgets
                for _, tw in ipairs(widgets) do
                    quote_row_h = quote_row_h + tw.forced_height
                end
            end
            -- The width probes above ran make_text with UNTRUNCATED prefixes,
            -- which inflates max_text_w and would drive the global shrink
            -- loop into minuscule fonts.  The quote is clamped to the screen
            -- width by construction, so it must never influence the shrink
            -- decision beyond that clamp: restore, then add the FINAL drawn
            -- width only.
            max_text_w = quote_max_w_before
            if quote_widgets then
                for _, tw in ipairs(quote_widgets) do
                    max_text_w = math.max(max_text_w,
                                          math.min(tw:getSize().w, margin_w))
                end
            end
        end

        -- Leading offset of the mock's top bar (padding-top: 10px), plus the
        -- flexible filler that pushes the quote to the bottom edge.
        local used = 0
        for _, w in ipairs(items) do used = used + w:getSize().h end
        local lead = s(10)
        local tail = math.max(0, screen_h - used - lead - quote_row_h - s(24))

        local group = VerticalGroup:new{ align = "center" }
        group[1] = VerticalSpan:new{ width = lead }
        for i, w in ipairs(items) do group[i + 1] = w end
        -- The filler absorbs whatever is left; when a quote exists it sits
        -- directly below the filler (i.e. flush with the bottom margin).
        local filler = VerticalSpan:new{ width = tail }
        filler.is_filler = true          -- tests: not part of "content height"
        group[#group + 1] = filler
        -- The bottom margin is layout chrome, not content (same in the mock).
        local bottom_gap = VerticalSpan:new{ width = s(24) }
        bottom_gap.is_filler = true
        if quote_widgets then
            local qgroup = VerticalGroup:new{ align = "center" }
            for i, tw in ipairs(quote_widgets) do
                qgroup[i] = CenterContainer:new{
                    dimen = { w = screen_w, h = tw.forced_height },
                    tw,
                }
            end
            group[#group + 1] = qgroup
        end
        group[#group + 1] = bottom_gap
        return group, used + lead + quote_row_h + s(24), max_text_w
    end

    -- Build, and shrink the scale factor only if the content would not fit.
    local k = screen_h / REF_H
    self.scale_k = k
    local content, need_h, need_w = self:build(k)
    local max_w = screen_w - math.max(2, math.floor(screen_w * 0.04))
    local max_h = screen_h - 2
    for _ = 1, 6 do
        if need_h <= max_h and need_w <= max_w then break end
        local f = math.min(max_h / math.max(1, need_h), max_w / math.max(1, need_w))
        k = k * math.max(0.4, math.min(0.97, f))
        content, need_h, need_w = build(k)
    end

    self.background = bg
    self.bordersize = 0
    self.margin = 0
    self.padding = 0
    self.dimen = { w = screen_w, h = screen_h }
    self.content = content
    self[1] = CenterContainer:new{
        dimen = { w = screen_w, h = screen_h },
        content,
    }
    -- Register so the "换一条金句" action can repaint this screen live
    -- (e.g. while the preview is on screen).  Unregistered on close.
    pcall(calquote.setScreen, self)
end

-- Repaint with the latest stored quote.  Called by calquote.lua after a fresh
-- quote lands while this lockscreen is already on screen, so the new day's
-- quote shows without a second lock cycle.  Rebuilds the content -- the quote
-- is read from the store here, not cached at init time.
function CalendarScreen:refreshQuote()
    local ok, err = pcall(function()
        self.content = self:build(self.scale_k)
        self[1] = CenterContainer:new{
            dimen = { w = self.screen_w, h = self.screen_h },
            self.content,
        }
        UIManager:setDirty(self, "ui")
    end)
    if not ok then
        logger.warn("calendar_lockscreen: quote redraw failed:", err)
    end
end

return CalendarScreen
