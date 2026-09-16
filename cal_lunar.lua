-- Calendar lunar/term algorithm (port of jjonline/calendar.js, pure Lua, offline)
-- Auto-generated from calendar_src.js. Valid range 1900-2100.
local _M = {}

local lunarInfo = {
    0x4bd8,
    0x4ae0,
    0xa570,
    0x54d5,
    0xd260,
    0xd950,
    0x16554,
    0x56a0,
    0x9ad0,
    0x55d2,
    0x4ae0,
    0xa5b6,
    0xa4d0,
    0xd250,
    0x1d255,
    0xb540,
    0xd6a0,
    0xada2,
    0x95b0,
    0x14977,
    0x4970,
    0xa4b0,
    0xb4b5,
    0x6a50,
    0x6d40,
    0x1ab54,
    0x2b60,
    0x9570,
    0x52f2,
    0x4970,
    0x6566,
    0xd4a0,
    0xea50,
    0x16a95,
    0x5ad0,
    0x2b60,
    0x186e3,
    0x92e0,
    0x1c8d7,
    0xc950,
    0xd4a0,
    0x1d8a6,
    0xb550,
    0x56a0,
    0x1a5b4,
    0x25d0,
    0x92d0,
    0xd2b2,
    0xa950,
    0xb557,
    0x6ca0,
    0xb550,
    0x15355,
    0x4da0,
    0xa5b0,
    0x14573,
    0x52b0,
    0xa9a8,
    0xe950,
    0x6aa0,
    0xaea6,
    0xab50,
    0x4b60,
    0xaae4,
    0xa570,
    0x5260,
    0xf263,
    0xd950,
    0x5b57,
    0x56a0,
    0x96d0,
    0x4dd5,
    0x4ad0,
    0xa4d0,
    0xd4d4,
    0xd250,
    0xd558,
    0xb540,
    0xb6a0,
    0x195a6,
    0x95b0,
    0x49b0,
    0xa974,
    0xa4b0,
    0xb27a,
    0x6a50,
    0x6d40,
    0xaf46,
    0xab60,
    0x9570,
    0x4af5,
    0x4970,
    0x64b0,
    0x74a3,
    0xea50,
    0x6b58,
    0x5ac0,
    0xab60,
    0x96d5,
    0x92e0,
    0xc960,
    0xd954,
    0xd4a0,
    0xda50,
    0x7552,
    0x56a0,
    0xabb7,
    0x25d0,
    0x92d0,
    0xcab5,
    0xa950,
    0xb4a0,
    0xbaa4,
    0xad50,
    0x55d9,
    0x4ba0,
    0xa5b0,
    0x15176,
    0x52b0,
    0xa930,
    0x7954,
    0x6aa0,
    0xad50,
    0x5b52,
    0x4b60,
    0xa6e6,
    0xa4e0,
    0xd260,
    0xea65,
    0xd530,
    0x5aa0,
    0x76a3,
    0x96d0,
    0x4afb,
    0x4ad0,
    0xa4d0,
    0x1d0b6,
    0xd250,
    0xd520,
    0xdd45,
    0xb5a0,
    0x56d0,
    0x55b2,
    0x49b0,
    0xa577,
    0xa4b0,
    0xaa50,
    0x1b255,
    0x6d20,
    0xada0,
    0x14b63,
    0x9370,
    0x49f8,
    0x4970,
    0x64b0,
    0x168a6,
    0xea50,
    0x6b20,
    0x1a6c4,
    0xaae0,
    0x92e0,
    0xd2e3,
    0xc960,
    0xd557,
    0xd4a0,
    0xda50,
    0x5d55,
    0x56a0,
    0xa6d0,
    0x55d4,
    0x52d0,
    0xa9b8,
    0xa950,
    0xb4a0,
    0xb6a6,
    0xad50,
    0x55a0,
    0xaba4,
    0xa5b0,
    0x52b0,
    0xb273,
    0x6930,
    0x7337,
    0x6aa0,
    0xad50,
    0x14b55,
    0x4b60,
    0xa570,
    0x54e4,
    0xd160,
    0xe968,
    0xd520,
    0xdaa0,
    0x16aa6,
    0x56d0,
    0x4ae0,
    0xa9d4,
    0xa2d0,
    0xd150,
    0xf252,
    0xd520
}

local solarTerm = {
    "小寒",
    "大寒",
    "立春",
    "雨水",
    "惊蛰",
    "春分",
    "清明",
    "谷雨",
    "立夏",
    "小满",
    "芒种",
    "夏至",
    "小暑",
    "大暑",
    "立秋",
    "处暑",
    "白露",
    "秋分",
    "寒露",
    "霜降",
    "立冬",
    "小雪",
    "大雪",
    "冬至"
}

local sTermInfo = {
    "9778397bd097c36b0b6fc9274c91aa",
    "97b6b97bd19801ec9210c965cc920e",
    "97bcf97c3598082c95f8c965cc920f",
    "97bd0b06bdb0722c965ce1cfcc920f",
    "b027097bd097c36b0b6fc9274c91aa",
    "97b6b97bd19801ec9210c965cc920e",
    "97bcf97c359801ec95f8c965cc920f",
    "97bd0b06bdb0722c965ce1cfcc920f",
    "b027097bd097c36b0b6fc9274c91aa",
    "97b6b97bd19801ec9210c965cc920e",
    "97bcf97c359801ec95f8c965cc920f",
    "97bd0b06bdb0722c965ce1cfcc920f",
    "b027097bd097c36b0b6fc9274c91aa",
    "9778397bd19801ec9210c965cc920e",
    "97b6b97bd19801ec95f8c965cc920f",
    "97bd09801d98082c95f8e1cfcc920f",
    "97bd097bd097c36b0b6fc9210c8dc2",
    "9778397bd197c36c9210c9274c91aa",
    "97b6b97bd19801ec95f8c965cc920e",
    "97bd09801d98082c95f8e1cfcc920f",
    "97bd097bd097c36b0b6fc9210c8dc2",
    "9778397bd097c36c9210c9274c91aa",
    "97b6b97bd19801ec95f8c965cc920e",
    "97bcf97c3598082c95f8e1cfcc920f",
    "97bd097bd097c36b0b6fc9210c8dc2",
    "9778397bd097c36c9210c9274c91aa",
    "97b6b97bd19801ec9210c965cc920e",
    "97bcf97c3598082c95f8c965cc920f",
    "97bd097bd097c35b0b6fc920fb0722",
    "9778397bd097c36b0b6fc9274c91aa",
    "97b6b97bd19801ec9210c965cc920e",
    "97bcf97c3598082c95f8c965cc920f",
    "97bd097bd097c35b0b6fc920fb0722",
    "9778397bd097c36b0b6fc9274c91aa",
    "97b6b97bd19801ec9210c965cc920e",
    "97bcf97c359801ec95f8c965cc920f",
    "97bd097bd097c35b0b6fc920fb0722",
    "9778397bd097c36b0b6fc9274c91aa",
    "97b6b97bd19801ec9210c965cc920e",
    "97bcf97c359801ec95f8c965cc920f",
    "97bd097bd097c35b0b6fc920fb0722",
    "9778397bd097c36b0b6fc9274c91aa",
    "97b6b97bd19801ec9210c965cc920e",
    "97bcf97c359801ec95f8c965cc920f",
    "97bd097bd07f595b0b6fc920fb0722",
    "9778397bd097c36b0b6fc9210c8dc2",
    "9778397bd19801ec9210c9274c920e",
    "97b6b97bd19801ec95f8c965cc920f",
    "97bd07f5307f595b0b0bc920fb0722",
    "7f0e397bd097c36b0b6fc9210c8dc2",
    "9778397bd097c36c9210c9274c920e",
    "97b6b97bd19801ec95f8c965cc920f",
    "97bd07f5307f595b0b0bc920fb0722",
    "7f0e397bd097c36b0b6fc9210c8dc2",
    "9778397bd097c36c9210c9274c91aa",
    "97b6b97bd19801ec9210c965cc920e",
    "97bd07f1487f595b0b0bc920fb0722",
    "7f0e397bd097c36b0b6fc9210c8dc2",
    "9778397bd097c36b0b6fc9274c91aa",
    "97b6b97bd19801ec9210c965cc920e",
    "97bcf7f1487f595b0b0bb0b6fb0722",
    "7f0e397bd097c35b0b6fc920fb0722",
    "9778397bd097c36b0b6fc9274c91aa",
    "97b6b97bd19801ec9210c965cc920e",
    "97bcf7f1487f595b0b0bb0b6fb0722",
    "7f0e397bd097c35b0b6fc920fb0722",
    "9778397bd097c36b0b6fc9274c91aa",
    "97b6b97bd19801ec9210c965cc920e",
    "97bcf7f1487f531b0b0bb0b6fb0722",
    "7f0e397bd097c35b0b6fc920fb0722",
    "9778397bd097c36b0b6fc9274c91aa",
    "97b6b97bd19801ec9210c965cc920e",
    "97bcf7f1487f531b0b0bb0b6fb0722",
    "7f0e397bd07f595b0b6fc920fb0722",
    "9778397bd097c36b0b6fc9274c91aa",
    "97b6b97bd19801ec9210c9274c920e",
    "97bcf7f0e47f531b0b0bb0b6fb0722",
    "7f0e397bd07f595b0b0bc920fb0722",
    "9778397bd097c36b0b6fc9210c91aa",
    "97b6b97bd197c36c9210c9274c920e",
    "97bcf7f0e47f531b0b0bb0b6fb0722",
    "7f0e397bd07f595b0b0bc920fb0722",
    "9778397bd097c36b0b6fc9210c8dc2",
    "9778397bd097c36c9210c9274c920e",
    "97b6b7f0e47f531b0723b0b6fb0722",
    "7f0e37f5307f595b0b0bc920fb0722",
    "7f0e397bd097c36b0b6fc9210c8dc2",
    "9778397bd097c36b0b70c9274c91aa",
    "97b6b7f0e47f531b0723b0b6fb0721",
    "7f0e37f1487f595b0b0bb0b6fb0722",
    "7f0e397bd097c35b0b6fc9210c8dc2",
    "9778397bd097c36b0b6fc9274c91aa",
    "97b6b7f0e47f531b0723b0b6fb0721",
    "7f0e27f1487f595b0b0bb0b6fb0722",
    "7f0e397bd097c35b0b6fc920fb0722",
    "9778397bd097c36b0b6fc9274c91aa",
    "97b6b7f0e47f531b0723b0b6fb0721",
    "7f0e27f1487f531b0b0bb0b6fb0722",
    "7f0e397bd097c35b0b6fc920fb0722",
    "9778397bd097c36b0b6fc9274c91aa",
    "97b6b7f0e47f531b0723b0b6fb0721",
    "7f0e27f1487f531b0b0bb0b6fb0722",
    "7f0e397bd097c35b0b6fc920fb0722",
    "9778397bd097c36b0b6fc9274c91aa",
    "97b6b7f0e47f531b0723b0b6fb0721",
    "7f0e27f1487f531b0b0bb0b6fb0722",
    "7f0e397bd07f595b0b0bc920fb0722",
    "9778397bd097c36b0b6fc9274c91aa",
    "97b6b7f0e47f531b0723b0787b0721",
    "7f0e27f0e47f531b0b0bb0b6fb0722",
    "7f0e397bd07f595b0b0bc920fb0722",
    "9778397bd097c36b0b6fc9210c91aa",
    "97b6b7f0e47f149b0723b0787b0721",
    "7f0e27f0e47f531b0723b0b6fb0722",
    "7f0e397bd07f595b0b0bc920fb0722",
    "9778397bd097c36b0b6fc9210c8dc2",
    "977837f0e37f149b0723b0787b0721",
    "7f07e7f0e47f531b0723b0b6fb0722",
    "7f0e37f5307f595b0b0bc920fb0722",
    "7f0e397bd097c35b0b6fc9210c8dc2",
    "977837f0e37f14998082b0787b0721",
    "7f07e7f0e47f531b0723b0b6fb0721",
    "7f0e37f1487f595b0b0bb0b6fb0722",
    "7f0e397bd097c35b0b6fc9210c8dc2",
    "977837f0e37f14998082b0787b06bd",
    "7f07e7f0e47f531b0723b0b6fb0721",
    "7f0e27f1487f531b0b0bb0b6fb0722",
    "7f0e397bd097c35b0b6fc920fb0722",
    "977837f0e37f14998082b0787b06bd",
    "7f07e7f0e47f531b0723b0b6fb0721",
    "7f0e27f1487f531b0b0bb0b6fb0722",
    "7f0e397bd097c35b0b6fc920fb0722",
    "977837f0e37f14998082b0787b06bd",
    "7f07e7f0e47f531b0723b0b6fb0721",
    "7f0e27f1487f531b0b0bb0b6fb0722",
    "7f0e397bd07f595b0b0bc920fb0722",
    "977837f0e37f14998082b0787b06bd",
    "7f07e7f0e47f531b0723b0b6fb0721",
    "7f0e27f1487f531b0b0bb0b6fb0722",
    "7f0e397bd07f595b0b0bc920fb0722",
    "977837f0e37f14998082b0787b06bd",
    "7f07e7f0e47f149b0723b0787b0721",
    "7f0e27f0e47f531b0b0bb0b6fb0722",
    "7f0e397bd07f595b0b0bc920fb0722",
    "977837f0e37f14998082b0723b06bd",
    "7f07e7f0e37f149b0723b0787b0721",
    "7f0e27f0e47f531b0723b0b6fb0722",
    "7f0e397bd07f595b0b0bc920fb0722",
    "977837f0e37f14898082b0723b02d5",
    "7ec967f0e37f14998082b0787b0721",
    "7f07e7f0e47f531b0723b0b6fb0722",
    "7f0e37f1487f595b0b0bb0b6fb0722",
    "7f0e37f0e37f14898082b0723b02d5",
    "7ec967f0e37f14998082b0787b0721",
    "7f07e7f0e47f531b0723b0b6fb0722",
    "7f0e37f1487f531b0b0bb0b6fb0722",
    "7f0e37f0e37f14898082b0723b02d5",
    "7ec967f0e37f14998082b0787b06bd",
    "7f07e7f0e47f531b0723b0b6fb0721",
    "7f0e37f1487f531b0b0bb0b6fb0722",
    "7f0e37f0e37f14898082b072297c35",
    "7ec967f0e37f14998082b0787b06bd",
    "7f07e7f0e47f531b0723b0b6fb0721",
    "7f0e27f1487f531b0b0bb0b6fb0722",
    "7f0e37f0e37f14898082b072297c35",
    "7ec967f0e37f14998082b0787b06bd",
    "7f07e7f0e47f531b0723b0b6fb0721",
    "7f0e27f1487f531b0b0bb0b6fb0722",
    "7f0e37f0e366aa89801eb072297c35",
    "7ec967f0e37f14998082b0787b06bd",
    "7f07e7f0e47f149b0723b0787b0721",
    "7f0e27f1487f531b0b0bb0b6fb0722",
    "7f0e37f0e366aa89801eb072297c35",
    "7ec967f0e37f14998082b0723b06bd",
    "7f07e7f0e47f149b0723b0787b0721",
    "7f0e27f0e47f531b0723b0b6fb0722",
    "7f0e37f0e366aa89801eb072297c35",
    "7ec967f0e37f14998082b0723b06bd",
    "7f07e7f0e37f14998083b0787b0721",
    "7f0e27f0e47f531b0723b0b6fb0722",
    "7f0e37f0e366aa89801eb072297c35",
    "7ec967f0e37f14898082b0723b02d5",
    "7f07e7f0e37f14998082b0787b0721",
    "7f07e7f0e47f531b0723b0b6fb0722",
    "7f0e36665b66aa89801e9808297c35",
    "665f67f0e37f14898082b0723b02d5",
    "7ec967f0e37f14998082b0787b0721",
    "7f07e7f0e47f531b0723b0b6fb0722",
    "7f0e36665b66a449801e9808297c35",
    "665f67f0e37f14898082b0723b02d5",
    "7ec967f0e37f14998082b0787b06bd",
    "7f07e7f0e47f531b0723b0b6fb0721",
    "7f0e36665b66a449801e9808297c35",
    "665f67f0e37f14898082b072297c35",
    "7ec967f0e37f14998082b0787b06bd",
    "7f07e7f0e47f531b0723b0b6fb0721",
    "7f0e26665b66a449801e9808297c35",
    "665f67f0e37f1489801eb072297c35",
    "7ec967f0e37f14998082b0787b06bd",
    "7f07e7f0e47f531b0723b0b6fb0721",
    "7f0e27f1487f531b0b0bb0b6fb0722"
}

local Gan = {
    "甲",
    "乙",
    "丙",
    "丁",
    "戊",
    "己",
    "庚",
    "辛",
    "壬",
    "癸"
}

local Zhi = {
    "子",
    "丑",
    "寅",
    "卯",
    "辰",
    "巳",
    "午",
    "未",
    "申",
    "酉",
    "戌",
    "亥"
}

local nStr1 = {
    "日",
    "一",
    "二",
    "三",
    "四",
    "五",
    "六",
    "七",
    "八",
    "九",
    "十"
}

local nStr2 = {
    "初",
    "十",
    "廿",
    "卅"
}

local nStr3 = {
    "正",
    "二",
    "三",
    "四",
    "五",
    "六",
    "七",
    "八",
    "九",
    "十",
    "冬",
    "腊"
}

local bit = require("bit")

local function leapMonth(y)
    return bit.band(lunarInfo[y - 1900 + 1], 0xf)
end

local function leapDays(y)
    if leapMonth(y) ~= 0 then
        if bit.band(lunarInfo[y - 1900 + 1], 0x10000) ~= 0 then return 30 else return 29 end
    end
    return 0
end

local function lYearDays(y)
    local sum = 348
    local i = 0x8000
    while i > 0x8 do
        if bit.band(lunarInfo[y - 1900 + 1], i) ~= 0 then sum = sum + 1 end
        i = bit.rshift(i, 1)
    end
    return sum + leapDays(y)
end

local function monthDays(y, m)
    if m > 12 or m < 1 then return -1 end
    if bit.band(lunarInfo[y - 1900 + 1], bit.rshift(0x10000, m)) ~= 0 then return 30 else return 29 end
end

local function toGanZhiYear(lYear)
    local g = (lYear - 3) % 10
    local z = (lYear - 3) % 12
    if g == 0 then g = 10 end
    if z == 0 then z = 12 end
    return Gan[g] .. Zhi[z]
end

local function toGanZhi(offset)
    return Gan[(offset % 10) + 1] .. Zhi[(offset % 12) + 1]
end

local function getTerm(y, n)
    if y < 1900 or y > 2100 or n < 1 or n > 24 then return -1 end
    local _table = sTermInfo[y - 1900 + 1]
    local calc = {}
    local i = 1
    while i <= #_table do
        local chunk5 = string.sub(_table, i, i + 4)
        local num = tonumber(chunk5, 16)
        local s = tostring(num)
        calc[#calc + 1] = string.sub(s, 1, 1)
        calc[#calc + 1] = string.sub(s, 2, 3)
        calc[#calc + 1] = string.sub(s, 4, 4)
        calc[#calc + 1] = string.sub(s, 5, 6)
        i = i + 5
    end
    return tonumber(calc[n])
end

local function toChinaMonth(m)
    if m < 1 or m > 12 then return "" end
    return nStr3[m] .. "月"
end

local function toChinaDay(d)
    if d == 10 then return "初十" end
    if d == 20 then return "二十" end
    if d == 30 then return "三十" end
    return nStr2[math.floor(d / 10) + 1] .. nStr1[(d % 10) + 1]
end

local function gregDay(y, m, d)
    local a = math.floor((14 - m) / 12)
    local yy = y + 4800 - a
    local mm = m + 12 * a - 3
    return d + math.floor((153 * mm + 2) / 5) + 365 * yy + math.floor(yy / 4) - math.floor(yy / 100) + math.floor(yy / 400) - 32045
end

local function solar2lunar(y, m, d)
    if y < 1900 or y > 2100 then return nil end
    if y == 1900 and m == 1 and d < 31 then return nil end
    local offset = gregDay(y, m, d) - gregDay(1900, 1, 31)
    local i = 1900
    local temp = 0
    while i < 2101 and offset > 0 do
        temp = lYearDays(i)
        offset = offset - temp
        i = i + 1
    end
    if offset < 0 then offset = offset + temp; i = i - 1 end
    local year = i
    local leap = leapMonth(i)
    local isLeap = false
    local j = 1
    local temp2 = 0
    while j < 13 and offset > 0 do
        if leap > 0 and j == (leap + 1) and not isLeap then
            j = j - 1
            isLeap = true
            temp2 = leapDays(year)
        else
            temp2 = monthDays(year, j)
        end
        if isLeap and j == (leap + 1) then
            isLeap = false
        end
        offset = offset - temp2
        j = j + 1
    end
    if offset == 0 and leap > 0 and j == (leap + 1) then
        if isLeap then
            isLeap = false
        else
            isLeap = true
            j = j - 1
        end
    end
    if offset < 0 then
        offset = offset + temp2
        j = j - 1
    end
    local month = j
    local day = offset + 1
    local gzY = toGanZhiYear(year)
    local firstNode = getTerm(y, m * 2 - 1)
    local secondNode = getTerm(y, m * 2)
    local gzM = toGanZhi((y - 1900) * 12 + m + 11)
    if d >= firstNode then
        gzM = toGanZhi((y - 1900) * 12 + m + 12)
    end
    local isTerm = false
    local Term = nil
    if firstNode == d then isTerm = true; Term = solarTerm[m * 2 - 1] end
    if secondNode == d then isTerm = true; Term = solarTerm[m * 2] end
    -- Weekday derived from the Julian day number: no dependency on
    -- os.time/os.date, so it is immune to device timezone/time_t quirks.
    local wd = ((gregDay(y, m, d) % 7) + 1) % 7 + 1   -- 1=Sunday .. 7=Saturday
    local weekCn = "星期" .. nStr1[wd]
    local IMonthCn = (isLeap and "闰" or "") .. toChinaMonth(month)
    local IDayCn = toChinaDay(day)
    return {
        lYear = year, lMonth = month, lDay = day, isLeap = isLeap,
        gzYear = gzY, IMonthCn = IMonthCn, IDayCn = IDayCn,
        isTerm = isTerm, Term = Term, weekCn = weekCn,
    }
end

_M.solar2lunar = solar2lunar
return _M
