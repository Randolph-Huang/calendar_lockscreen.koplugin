-- Calendar Lockscreen plugin for KOReader (offline ink-screen screensaver)
-- Replaces the screensaver with today's calendar + lunar date.
local Blitbuffer = require("ffi/blitbuffer")
local CalendarScreen = require("calendarscreen")
local Device = require("device")
local Font = require("ui/font")
local Screen = Device.screen
local ScreenSaverWidget = require("ui/widget/screensaverwidget")
local Screensaver = require("ui/screensaver")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")
local gettext = _
local calfont = require("calfont")
local calquote = require("calquote")
local logger = require("logger")

local CalendarLockscreen = WidgetContainer:extend{
    name = "calendar_lockscreen",
}

function CalendarLockscreen:isEnabled()
    return G_reader_settings:isTrue("calendar_lockscreen_enabled")
end

-- The font and the whole look are resolved by calendarscreen.lua (via
-- calfont.lua), so there is nothing to pass in here.
function CalendarLockscreen:newScreen()
    return CalendarScreen:new{}
end

-- Clear e-ink ghosting before the calendar is painted.
--
-- KOReader already does this for image-type screensavers (Screensaver:show():
-- "flash the screen to white first, to eliminate ghosting"), but that branch is
-- gated on self:modeIsImage() -- and we force the "message" mode, so the
-- calendar would be the one screensaver mode left without the protection.
-- Hence we do it ourselves: drive every pixel white with a *full* (flashing)
-- refresh first, then let the screensaver widget repaint on top of it.
--
-- Hook point: ScreenSaverWidget:init runs after Screensaver:show() has switched
-- the rotation to portrait and before UIManager:show() paints the calendar, so
-- Screen:getWidth()/getHeight() already describe the panel here.
local function wipeGhosting()
    local ok, err = pcall(function()
        local w, h = Screen:getWidth(), Screen:getHeight()
        Screen.bb:fill(Blitbuffer.COLOR_WHITE)
        if Screen.refreshFull then
            Screen:refreshFull(0, 0, w, h)
        else
            -- Older builds: go through UIManager instead.
            UIManager:setDirty(nil, "full")
            UIManager:forceRePaint()
        end
    end)
    if not ok then
        logger.warn("calendar_lockscreen: could not clear ghosting:", err)
    end
end

-- Force KOReader's screensaver into a mode that always builds a ScreenSaverWidget
-- (so our ScreenSaverWidget.init hook runs), with a solid white background.
local function applyCalendarMode(self)
    self.screensaver_type = "message"
    self.show_message = true
    self.screensaver_background = "white"
    self.image = nil
    self.image_file = nil
end

-- Install injection hooks exactly once. The plugin instance may be created twice
-- (once for FileManager / main screen, once for ReaderUI), so guard with a
-- module-level flag to avoid wrapping the hooks twice.
local hooks_installed = false
local function installHooks()
    if hooks_installed then return end
    hooks_installed = true

    -- 1) Swap the screensaver content widget for our calendar, and wipe the
    --    e-ink ghosting of the page underneath before it is painted.
    local orig_ssw_init = ScreenSaverWidget.init
    ScreenSaverWidget.init = function(self, ...)
        if CalendarLockscreen:isEnabled() then
            self.widget = CalendarLockscreen:newScreen()
            self.background = Blitbuffer.COLOR_WHITE
            wipeGhosting()
        end
        return orig_ssw_init(self, ...)
    end

    -- 2) After KOReader prepared the screensaver from the user's own settings,
    --    force our mode so a ScreenSaverWidget is always created.
    local orig_setup = Screensaver.setup
    Screensaver.setup = function(self, ...)
        local ret = orig_setup(self, ...)
        if CalendarLockscreen:isEnabled() then
            applyCalendarMode(self)
        end
        return ret
    end

    -- 3) Belt and braces: re-assert right before showing.
    local orig_show = Screensaver.show
    Screensaver.show = function(self, ...)
        if CalendarLockscreen:isEnabled() then
            applyCalendarMode(self)
        end
        return orig_show(self, ...)
    end

    -- 4) Universal teardown: UIManager:close() ALWAYS runs onCloseWidget,
    --    whatever path dismissed the screensaver (tap, key, power button,
    --    delayed close).  Unregister the lockscreen here so a later "换一条
    --    金句" can never repaint an already-closed widget.
    local orig_onCloseWidget = ScreenSaverWidget.onCloseWidget
    if type(orig_onCloseWidget) == "function" then
        ScreenSaverWidget.onCloseWidget = function(self, ...)
            if CalendarLockscreen:isEnabled() then
                pcall(calquote.clearScreen)
            end
            return orig_onCloseWidget(self, ...)
        end
    end
end

function CalendarLockscreen:init()
    -- KEY: register to the main menu, otherwise the plugin never appears in the menu.
    if self.ui and self.ui.menu then
        self.ui.menu:registerToMainMenu(self)
    end
    -- Install screensaver injection hooks (guarded, never fatal to loading).
    local ok, err = pcall(installHooks)
    if not ok then
        logger.warn("calendar_lockscreen: failed to install hooks:", err)
    end
end

-- Show the lock screen immediately (for preview, without sleeping the device).
function CalendarLockscreen:preview()
    local ssw = ScreenSaverWidget:new{
        widget = self:newScreen(),
        background = Blitbuffer.COLOR_WHITE,
    }
    UIManager:show(ssw, "full")
end

-- Font picker.  This is a sub_item_table_func, i.e. it runs every time the
-- submenu is opened -- which is exactly what we want: fonts dropped into a
-- font folder while KOReader is running show up as soon as you come back here,
-- with no code change and usually no restart.
local function buildFontMenu()
    calfont.rescan()

    local items = {
        {
            text = _("自动（挑最粗的中文字体）"),
            checked_func = function() return calfont.getSelected() == "" end,
            callback = function() calfont.setSelected("") end,
            separator = true,
            help_text = _("自动在设备上所有字体里挑选笔画最粗的中文字体。放入新字体后重新打开本菜单即可看到。"),
        },
    }

    local cjk, others = {}, {}
    for _, e in ipairs(calfont.catalog()) do
        local item = {
            text = e.label,
            checked_func = function() return calfont.getSelected() == e.name end,
            callback = function() calfont.setSelected(e.name) end,
            -- Render each entry in its own typeface, so the list is a preview.
            font_func = function(size)
                local ok, f = pcall(function() return Font:getFace(e.path, size) end)
                if ok and f then return f end
                return nil
            end,
        }
        if e.cjk then cjk[#cjk + 1] = item else others[#others + 1] = item end
    end

    if #cjk > 0 and #others > 0 then
        cjk[#cjk].separator = true
    end
    for _, it in ipairs(cjk) do items[#items + 1] = it end

    if #others > 0 then
        items[#items + 1] = {
            text = string.format(_("显示全部字体（%d）"), #others),
            sub_item_table = others,
        }
    end
    if #cjk == 0 and #others == 0 then
        items[#items + 1] = {
            text = _("没有找到任何字体文件"),
            enabled = false,
        }
    end
    return items
end

-- Quote-type picker: one checkable entry per type from calquote.KINDS.
-- NOTE: the loop variable must NOT be named `_` -- that shadows the gettext
-- function and `_(kind)` would try to call a number.
local function buildKindMenu()
    local items = {}
    for _, kind in ipairs(calquote.KINDS) do
        items[#items + 1] = {
            text = gettext(kind),
            checked_func = function() return calquote.selectedKind() == kind end,
            callback = function() calquote.setKind(kind) end,
        }
    end
    items[#items].separator = true
    return items
end

function CalendarLockscreen:addToMainMenu(menu_items)
    menu_items.calendar_lockscreen = {
        text = _("日历锁屏"),
        -- Without a sorting_hint MenuSorter treats this entry as an orphan and
        -- prepends its "NEW: " (新：) prefix before dumping it into the first
        -- menu tab.  Pointing it at the "tools" menu fixes both problems.
        sorting_hint = "tools",
        sub_item_table = {
            {
                text = _("启用日历锁屏"),
                checked_func = function() return self:isEnabled() end,
                callback = function()
                    if self:isEnabled() then
                        G_reader_settings:makeFalse("calendar_lockscreen_enabled")
                    else
                        G_reader_settings:makeTrue("calendar_lockscreen_enabled")
                    end
                end,
            },
            {
                -- Read-only info line.
                text_func = function()
                    local e = calfont.resolve()
                    local name = e and (e.label or e.name) or "infofont"
                    if calfont.getSelected() == "" then
                        return string.format(_("当前字体：%s（自动）"), name)
                    end
                    return string.format(_("当前字体：%s"), name)
                end,
                enabled = false,
            },
            {
                text = _("字体"),
                sub_item_table_func = buildFontMenu,
            },
            {
                text = _("额外加粗"),
                checked_func = function() return calfont.isBoldEnabled() end,
                callback = function()
                    calfont.setBoldEnabled(not calfont.isBoldEnabled())
                end,
                help_text = _("已经选到很粗的字体时不需要开；只有字体偏细、又不想另外下载字体文件时才建议开启（由 KOReader 合成加粗）。"),
            },
            {
                text = _("预览锁屏样式"),
                callback = function()
                    self:preview()
                end,
            },
            {
                text = _("金句类型"),
                sub_item_table_func = buildKindMenu,
                help_text = _("锁屏底部每日金句的内容类型。切换类型后，当天的金句会立即换成对应类型。"),
            },
            {
                text = _("金句字号"),
                sub_item_table_func = function()
                    local sizes = { 6, 7, 8, 9, 10, 11, 12, 13, 14 }
                    local items = {}
                    for i, sz in ipairs(sizes) do
                        items[#items + 1] = {
                            text = sz == 12 and _("12（默认）") or tostring(sz),
                            checked_func = function() return calquote.quoteSize() == sz end,
                            callback = function() calquote.setQuoteSize(sz) end,
                        }
                    end
                    return items
                end,
                help_text = _("锁屏底部每日金句的字体大小（6–14）。仅影响金句，不影响日历其他文字。"),
            },
            {
                -- Local "换一条": pick the next line for today (no network).
                text = _("换一条金句"),
                keep_menu_open = true,
                help_text = _("从内置的真实语料库里换一句今天的内容（诗词/名言警句均出自真实出处，绝不编造）。"),
                callback = function()
                    local InfoMessage = require("ui/widget/infomessage")
                    local text = calquote.rotate()
                    UIManager:show(InfoMessage:new{
                        text = _("今日金句：") .. (text or _("（语料库为空）")),
                        timeout = 6,
                    })
                end,
            },
        },
    }
end

return CalendarLockscreen
