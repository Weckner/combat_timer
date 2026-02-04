--[[
    Scoffs Misc - Combat Status Indicator
    Shows Combat+ / Combat- on status change (flashes for 2 seconds)
    Shows 00:00 timer during combat (hidden until combat starts)
    Drag to move. Use /sm font <size> to change timer font size.
]]

local STATUS_FLASH_DURATION = 2
local TIMER_TICK_INTERVAL = 1
local DEFAULT_TIMER_FONT = 16
local DEFAULTS = {
    status = { point = "CENTER", relPoint = "CENTER", x = -60, y = 150, w = 150, h = 40 },
    timer = { point = "CENTER", relPoint = "CENTER", x = 60, y = 150, w = 120, h = 40 },
}

local statusFrame
local statusText
local timerFrame
local timerText
local combatStartTime
local timerTicker
local statusHideTimer
local editMode = false

local function FormatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d", m, s)
end

local function ShowStatusFlash(text)
    if statusHideTimer then
        statusHideTimer:Cancel()
        statusHideTimer = nil
    end

    statusText:SetText(text)
    statusFrame:SetAlpha(1)
    statusFrame:Show()

    UIFrameFadeOut(statusFrame, STATUS_FLASH_DURATION, 1, 0)
    statusHideTimer = C_Timer.NewTimer(STATUS_FLASH_DURATION, function()
        statusFrame:Hide()
        statusFrame:SetAlpha(1)
        statusHideTimer = nil
    end)
end

local function UpdateTimer()
    if not combatStartTime or not timerFrame:IsShown() then return end
    local elapsed = GetTime() - combatStartTime
    timerText:SetText(FormatTime(elapsed))
end

local function StartCombatTimer()
    combatStartTime = GetTime()
    timerText:SetText("00:00")
    timerFrame:Show()
    UpdateTimer()
    if timerTicker then
        timerTicker:Cancel()
    end
    timerTicker = C_Timer.NewTicker(TIMER_TICK_INTERVAL, UpdateTimer)
end

local function StopCombatTimer()
    if timerTicker then
        timerTicker:Cancel()
        timerTicker = nil
    end
    timerFrame:Hide()
    combatStartTime = nil
end

local function OnEnterCombat()
    ShowStatusFlash("combat+")
    StartCombatTimer()
end

local function OnLeaveCombat()
    ShowStatusFlash("combat-")
    StopCombatTimer()
end

local function MakeMovable(frame, key)
    ScoffsMiscDB = ScoffsMiscDB or {}
    local db = ScoffsMiscDB[key] or {}
    local d = DEFAULTS[key]
    local point, relPoint = db.point or d.point, db.relPoint or d.relPoint
    local x, y = db.x or d.x, db.y or d.y
    local w, h = db.w or d.w, db.h or d.h

    frame:ClearAllPoints()
    frame:SetPoint(point, UIParent, relPoint, x, y)
    frame:SetSize(w, h)
    frame:SetMovable(true)

    -- Drag overlay: transparent frame on top to capture drag (FontStrings don't receive drag)
    local overlay = CreateFrame("Frame", nil, frame)
    overlay:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    overlay:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
    overlay:EnableMouse(true)
    overlay:RegisterForDrag("LeftButton")
    overlay:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    overlay:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local p, _, r, x2, y2 = frame:GetPoint()
        ScoffsMiscDB[key] = ScoffsMiscDB[key] or {}
        ScoffsMiscDB[key].point = p
        ScoffsMiscDB[key].relPoint = r
        ScoffsMiscDB[key].x = x2
        ScoffsMiscDB[key].y = y2
    end)
end

local function ApplyTimerFont()
    ScoffsMiscFontDB = ScoffsMiscFontDB or {}
    local size = ScoffsMiscFontDB.timerSize or (ScoffsMiscDB and ScoffsMiscDB.timerFontSize) or DEFAULT_TIMER_FONT
    if timerText then
        local path, _, flags = timerText:GetFont()
        timerText:SetFont(path or "Fonts\\ARIALN.TTF", size, flags or "")
    end
end

local function Setup()
    ScoffsMiscDB = ScoffsMiscDB or {}

    statusFrame = CreateFrame("Frame", "ScoffsMiscStatusFrame", UIParent)
    statusFrame:SetAlpha(0)
    statusFrame:Hide()
    MakeMovable(statusFrame, "status")
    statusText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    statusText:SetPoint("CENTER", statusFrame, "CENTER", 0, 0)
    statusText:SetTextColor(1, 1, 1)
    statusText:SetShadowColor(0, 0, 0, 1)
    statusText:SetShadowOffset(1, -1)

    timerFrame = CreateFrame("Frame", "ScoffsMiscTimerFrame", UIParent)
    timerFrame:Hide()
    MakeMovable(timerFrame, "timer")
    timerText = timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ApplyTimerFont()
    timerText:SetPoint("CENTER", timerFrame, "CENTER", 0, 0)
    timerText:SetTextColor(1, 1, 1)
    timerText:SetShadowColor(0, 0, 0, 1)
    timerText:SetShadowOffset(1, -1)

    local eventFrame = CreateFrame("Frame", nil, UIParent)
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:SetScript("OnEvent", function(_, event, addonName)
        if event == "ADDON_LOADED" and addonName == "scoffsmisc" then
            ApplyTimerFont()
        elseif event == "PLAYER_REGEN_DISABLED" then
            if not editMode then OnEnterCombat() end
        elseif event == "PLAYER_REGEN_ENABLED" then
            if not editMode then OnLeaveCombat() end
        end
    end)

    local function enterEditMode()
        editMode = true
        statusText:SetText("Combat+")
        statusFrame:SetAlpha(1)
        statusFrame:Show()
        timerText:SetText("00:00")
        timerFrame:Show()
        print("Edit mode ON - drag to move")
    end
    local function leaveEditMode()
        editMode = false
        statusFrame:SetAlpha(0)
        statusFrame:Hide()
        timerFrame:Hide()
        if combatStartTime then
            timerFrame:Show()
            UpdateTimer()
        end
        print("Edit mode OFF")
    end
    SLASH_SCOFFSMISC1 = "/scoffsmisc"
    SLASH_SCOFFSMISC2 = "/sm"
    SlashCmdList["SCOFFSMISC"] = function(msg)
        local cmd = (msg or ""):lower():match("^%s*(.-)%s*$")
        if cmd == "reset" then
            ScoffsMiscDB.status = nil
            ScoffsMiscDB.timer = nil
            leaveEditMode()
            Setup()
            enterEditMode()
            print("Positions reset to default")
        elseif cmd == "font" or cmd:match("^font%s") then
            local arg = (cmd:match("^font%s+(.+)$") or ""):match("^%s*(.-)%s*$")
            local size
            if arg == "small" then size = 12
            elseif arg == "medium" then size = 16
            elseif arg == "large" then size = 20
            elseif arg ~= "" then size = tonumber(arg) end
            if size and size >= 8 and size <= 48 then
                ScoffsMiscFontDB.timerSize = size
                ApplyTimerFont()
                print("Timer font size set to " .. size)
            else
                ScoffsMiscFontDB = ScoffsMiscFontDB or {}
                local cur = ScoffsMiscFontDB.timerSize or DEFAULT_TIMER_FONT
                print("Timer font " .. cur .. ". Use: /sm font <8-48> or small/medium/large")
            end
        elseif cmd == "help" or cmd == "?" then
            print("  /sm | /scoffsmisc - Toggle edit mode")
            print("  font <size> - Timer font: 8-48, or small/medium/large")
            print("  reset - Reset positions to default")
        else
            editMode = not editMode
            if editMode then
                enterEditMode()
            else
                leaveEditMode()
            end
        end
    end
end

Setup()
