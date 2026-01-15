-- TweaksUI Unit Frames - Range Fade System
-- Fades party frame elements when units are out of range

local ADDON_NAME, TweaksUI = ...

-- Module reference (will be set during init)
local UnitFrames = nil

-- ============================================================================
-- RANGE FADE MODULE
-- ============================================================================

local RangeFade = {
    -- Update ticker
    ticker = nil,
    
    -- Is the system active
    active = false,
}

-- Export to TweaksUI namespace
TweaksUI.UnitFramesRangeFade = RangeFade

-- ============================================================================
-- DEFAULT SETTINGS
-- ============================================================================

RangeFade.DEFAULTS = {
    enabled = true,
    checkInterval = 0.2,  -- Update frequency in seconds
    
    -- Overall fade when out of range (if perElementFade is false)
    outOfRangeAlpha = 0.4,
    
    -- Per-element alpha control
    perElementFade = true,
    elementAlphas = {
        healthBar = 0.2,
        powerBar = 0.2,
        background = 0.1,
        nameText = 1.0,      -- Keep names visible!
        healthText = 0.25,
        auras = 0.2,
        icons = 0.5,         -- Role, leader, raid target
        dispelIndicator = 0.2,
        defensiveIcon = 0.5,
        absorbBar = 0.2,
    },
}

-- ============================================================================
-- HELPER: SAFE ALPHA APPLICATION
-- ============================================================================

-- Apply alpha using SetAlphaFromBoolean if available (Midnight secret value compatible)
-- Falls back to simple SetAlpha if not
local function ApplyAlpha(element, inRange, inRangeAlpha, outOfRangeAlpha)
    if not element then return end
    
    -- SetAlphaFromBoolean is a native widget method that handles secret values
    if element.SetAlphaFromBoolean then
        element:SetAlphaFromBoolean(inRange, inRangeAlpha, outOfRangeAlpha)
    else
        -- Fallback for elements without the method
        -- Note: inRange might be a secret value, so we need pcall
        local success, result = pcall(function()
            if inRange then
                return inRangeAlpha
            else
                return outOfRangeAlpha
            end
        end)
        
        if success then
            element:SetAlpha(result)
        else
            -- If inRange is a secret, try to use it as a boolean
            -- This is a last resort and may not work perfectly
            element:SetAlpha(outOfRangeAlpha)
        end
    end
end

-- ============================================================================
-- RANGE CHECK
-- ============================================================================

-- Check if Edit Mode is currently active (to prevent taint issues)
local function IsEditModeActive()
    if EditModeManagerFrame and EditModeManagerFrame:IsShown() then
        return true
    end
    if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then
        return true
    end
    return false
end

-- Check if a unit is in range
-- Returns true if in range, false if out of range
-- NEVER returns secret values - always converts to boolean
local function IsUnitInRange(unit)
    if not unit then return true end
    
    -- Skip range checks during Edit Mode to prevent taint
    if IsEditModeActive() then
        return true
    end
    
    -- Check test mode first
    local TestMode = TweaksUI.UnitFramesTestMode
    if TestMode and TestMode:IsActive() then
        local testData = TestMode:GetDataByUnit(unit)
        if testData then
            return testData.inRange ~= false  -- Default to true if not set
        end
    end
    
    -- Real unit checks
    if not UnitExists(unit) then return true end
    
    -- Player is always in range of themselves
    if UnitIsUnit(unit, "player") then return true end
    
    -- NPC party members (followers, etc.) - UnitInRange doesn't work for them
    -- Check if it's a player - if not, assume in range or use visibility check
    if not UnitIsPlayer(unit) then
        -- For NPCs, check if they're visible on screen as a fallback
        -- If we can't determine, assume in range
        return true
    end
    
    -- Must be in a group to check range
    if not (IsInGroup() or IsInRaid()) then return true end
    
    -- UnitInRange returns:
    -- - true if in range
    -- - false if out of range
    -- - nil if can't determine (treat as in range)
    -- In Midnight, may return a secret value
    local inRange = UnitInRange(unit)
    
    -- CRITICAL: Convert to non-secret boolean immediately
    -- Secret values cannot be stored on frames or used in boolean tests
    -- Use pcall to safely handle secret value comparison
    local success, isInRange = pcall(function()
        if inRange == nil then
            return true  -- Can't determine, assume in range
        elseif inRange == true then
            return true
        elseif inRange == false then
            return false
        else
            -- If it's a secret value, we can't compare it directly
            -- Default to in-range to be safe
            return true
        end
    end)
    
    if not success then
        -- If pcall failed, inRange was likely a secret value
        return true  -- Default to in-range
    end
    
    return isInRange
end

-- ============================================================================
-- APPLY RANGE FADE TO A FRAME
-- ============================================================================

function RangeFade:UpdateFrameRange(frame, settings)
    if not frame or not frame.unit then return end
    
    -- Get settings
    settings = settings or self.DEFAULTS
    
    -- Skip if disabled
    if not settings.enabled then
        -- Reset to full alpha only if not already reset
        if frame.tuiRangeFadeApplied then
            ApplyAlpha(frame, true, 1.0, 1.0)
            frame.tuiRangeFadeApplied = false
            frame.tuiLastRangeState = nil
        end
        return
    end
    
    local unit = frame.unit
    
    -- Skip if dead fade is active (dead fade takes priority)
    if frame.tuiDeadFadeApplied then
        return
    end
    
    -- Get range status
    local inRange = IsUnitInRange(unit)
    
    -- PERFORMANCE OPTIMIZATION: Skip update if range state unchanged
    -- Convert inRange to boolean for comparison (handles secret values)
    local rangeState
    local success = pcall(function()
        rangeState = inRange and true or false
    end)
    if not success then
        rangeState = true  -- Default to in-range if secret
    end
    
    -- Check if state changed
    if frame.tuiLastRangeState == rangeState then
        return  -- No change, skip expensive alpha updates
    end
    frame.tuiLastRangeState = rangeState
    frame.tuiRangeFadeApplied = true
    
    -- Store range state on frame for other systems to reference
    -- CRITICAL: Store the boolean rangeState, NOT the potentially-secret inRange
    -- This prevents taint from spreading to other systems
    frame.tuiInRange = rangeState
    
    -- Get alpha settings
    local inRangeAlpha = 1.0
    local outOfRangeAlpha = settings.outOfRangeAlpha or 0.4
    
    if settings.perElementFade then
        -- Per-element alpha mode
        -- Frame stays at full alpha, individual elements fade
        local elementAlphas = settings.elementAlphas or self.DEFAULTS.elementAlphas
        
        -- Frame itself stays full alpha
        ApplyAlpha(frame, true, 1.0, 1.0)
        
        -- Health bar
        local healthAlpha = elementAlphas.healthBar or 0.2
        ApplyAlpha(frame.healthBar, inRange, 1.0, healthAlpha)
        
        -- Health bar background (if separate)
        if frame.healthBar and frame.healthBar.bg then
            ApplyAlpha(frame.healthBar.bg, inRange, 1.0, healthAlpha)
        end
        
        -- Power bar
        local powerAlpha = elementAlphas.powerBar or 0.2
        ApplyAlpha(frame.powerBar, inRange, 1.0, powerAlpha)
        
        -- Background
        local bgAlpha = elementAlphas.background or 0.1
        if frame.background then
            ApplyAlpha(frame.background, inRange, 1.0, bgAlpha)
        end
        -- For BackdropTemplate frames
        if frame.SetBackdropColor then
            -- Can't easily fade backdrop with SetAlphaFromBoolean
            -- Use the frame reference stored during creation
            if frame.backdropFrame then
                ApplyAlpha(frame.backdropFrame, inRange, 1.0, bgAlpha)
            end
        end
        
        -- Name text
        local nameAlpha = elementAlphas.nameText or 1.0
        ApplyAlpha(frame.nameText, inRange, 1.0, nameAlpha)
        
        -- Health text
        local healthTextAlpha = elementAlphas.healthText or 0.25
        ApplyAlpha(frame.healthText, inRange, 1.0, healthTextAlpha)
        
        -- Auras (buffs and debuffs)
        local auraAlpha = elementAlphas.auras or 0.2
        if frame.buffIcons then
            for _, icon in ipairs(frame.buffIcons) do
                ApplyAlpha(icon, inRange, 1.0, auraAlpha)
            end
        end
        if frame.debuffIcons then
            for _, icon in ipairs(frame.debuffIcons) do
                ApplyAlpha(icon, inRange, 1.0, auraAlpha)
            end
        end
        
        -- Icons (role, leader, raid target, ready check)
        local iconAlpha = elementAlphas.icons or 0.5
        ApplyAlpha(frame.roleIcon, inRange, 1.0, iconAlpha)
        ApplyAlpha(frame.leaderIcon, inRange, 1.0, iconAlpha)
        ApplyAlpha(frame.raidTargetIcon, inRange, 1.0, iconAlpha)
        ApplyAlpha(frame.readyCheckIcon, inRange, 1.0, iconAlpha)
        ApplyAlpha(frame.summonIcon, inRange, 1.0, iconAlpha)
        
        -- Dispel indicator
        local dispelAlpha = elementAlphas.dispelIndicator or 0.2
        ApplyAlpha(frame.dispelIndicator, inRange, 1.0, dispelAlpha)
        if frame.dispelOverlay then
            ApplyAlpha(frame.dispelOverlay, inRange, 1.0, dispelAlpha)
        end
        
        -- Defensive icon (future feature)
        local defAlpha = elementAlphas.defensiveIcon or 0.5
        ApplyAlpha(frame.defensiveIcon, inRange, 1.0, defAlpha)
        
        -- Absorb bar
        local absorbAlpha = elementAlphas.absorbBar or 0.2
        ApplyAlpha(frame.absorbBar, inRange, 1.0, absorbAlpha)
        
    else
        -- Simple frame-level alpha mode
        -- Reset all elements to full alpha first
        ApplyAlpha(frame.healthBar, true, 1.0, 1.0)
        ApplyAlpha(frame.powerBar, true, 1.0, 1.0)
        ApplyAlpha(frame.nameText, true, 1.0, 1.0)
        ApplyAlpha(frame.healthText, true, 1.0, 1.0)
        ApplyAlpha(frame.roleIcon, true, 1.0, 1.0)
        
        -- Apply frame-level alpha
        ApplyAlpha(frame, inRange, inRangeAlpha, outOfRangeAlpha)
    end
end

-- ============================================================================
-- UPDATE ALL PARTY FRAMES
-- ============================================================================

function RangeFade:UpdateAllFrames(frames, settings)
    if not frames then return end
    
    for i, frame in pairs(frames) do
        if frame and frame:IsShown() then
            self:UpdateFrameRange(frame, settings)
        end
    end
end

-- ============================================================================
-- RANGE UPDATE TICKER
-- ============================================================================

local function OnRangeTick()
    -- Get party frames from UnitFrames module
    if not UnitFrames then return end
    
    -- CRITICAL: Skip range updates during Edit Mode to prevent taint
    -- Edit Mode refreshes Blizzard's CompactUnitFrames and any taint can cause errors
    if IsEditModeActive() then
        return
    end
    
    -- Also skip if TUI Layout Mode is active
    if TweaksUI.Layout and TweaksUI.Layout:IsActive() then
        return
    end
    
    -- In raids, we use a counter to reduce frequency (performance optimization)
    -- Raids check every other tick (effectively 0.4s instead of 0.2s)
    if IsInRaid() then
        RangeFade.raidTickCounter = (RangeFade.raidTickCounter or 0) + 1
        if RangeFade.raidTickCounter < 2 then
            return  -- Skip this tick for raids
        end
        RangeFade.raidTickCounter = 0
    end
    
    -- Update party frames (only when not in raid)
    if not IsInRaid() then
        local partyMemberFrames = UnitFrames:GetPartyMemberFrames()
        if partyMemberFrames then
            local partySettings = nil
            if TweaksUI.db and TweaksUI.db.unitFrames and TweaksUI.db.unitFrames.party then
                partySettings = TweaksUI.db.unitFrames.party.rangeFade
            end
            partySettings = partySettings or RangeFade.DEFAULTS
            RangeFade:UpdateAllFrames(partyMemberFrames, partySettings)
        end
    end
    
    -- Update raid frames if in raid
    if IsInRaid() then
        local raidFrames = UnitFrames:GetRaidMemberFrames()
        if raidFrames then
            -- Get appropriate raid settings (small or large)
            local raidSettings = nil
            if TweaksUI.db and TweaksUI.db.unitFrames and TweaksUI.db.unitFrames.raid then
                local raidSize = GetNumGroupMembers()
                local threshold = TweaksUI.db.unitFrames.raid.sizeThreshold or 20
                if raidSize <= threshold then
                    raidSettings = TweaksUI.db.unitFrames.raid.small and TweaksUI.db.unitFrames.raid.small.rangeFade
                else
                    raidSettings = TweaksUI.db.unitFrames.raid.large and TweaksUI.db.unitFrames.raid.large.rangeFade
                end
            end
            raidSettings = raidSettings or RangeFade.DEFAULTS
            RangeFade:UpdateAllFrames(raidFrames, raidSettings)
        end
    end
end

function RangeFade:Start(interval)
    if self.ticker then
        self.ticker:Cancel()
    end
    
    interval = interval or self.DEFAULTS.checkInterval
    self.ticker = C_Timer.NewTicker(interval, OnRangeTick)
    self.active = true
    
    TweaksUI:PrintDebug("RangeFade ticker started (" .. interval .. "s interval)")
end

function RangeFade:Stop()
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end
    self.active = false
    
    TweaksUI:PrintDebug("RangeFade ticker stopped")
end

function RangeFade:Restart(interval)
    self:Stop()
    self:Start(interval)
end

function RangeFade:IsActive()
    return self.active
end

-- ============================================================================
-- RESET FRAME ALPHAS
-- ============================================================================

-- Reset all elements to full alpha (for when disabled or destroyed)
function RangeFade:ResetFrame(frame)
    if not frame then return end
    
    frame.tuiInRange = true
    
    ApplyAlpha(frame, true, 1.0, 1.0)
    ApplyAlpha(frame.healthBar, true, 1.0, 1.0)
    ApplyAlpha(frame.powerBar, true, 1.0, 1.0)
    ApplyAlpha(frame.nameText, true, 1.0, 1.0)
    ApplyAlpha(frame.healthText, true, 1.0, 1.0)
    ApplyAlpha(frame.roleIcon, true, 1.0, 1.0)
    ApplyAlpha(frame.leaderIcon, true, 1.0, 1.0)
    ApplyAlpha(frame.raidTargetIcon, true, 1.0, 1.0)
    
    if frame.buffIcons then
        for _, icon in ipairs(frame.buffIcons) do
            ApplyAlpha(icon, true, 1.0, 1.0)
        end
    end
    if frame.debuffIcons then
        for _, icon in ipairs(frame.debuffIcons) do
            ApplyAlpha(icon, true, 1.0, 1.0)
        end
    end
end

function RangeFade:ResetAllFrames(frames)
    -- If specific frames provided, reset those
    if frames then
        for i, frame in pairs(frames) do
            if frame then
                self:ResetFrame(frame)
            end
        end
        return
    end
    
    -- Otherwise reset all party and raid frames
    if UnitFrames then
        local partyFrames = UnitFrames:GetPartyMemberFrames() or {}
        for _, frame in pairs(partyFrames) do
            if frame then
                self:ResetFrame(frame)
            end
        end
        
        local raidFrames = UnitFrames:GetRaidMemberFrames() or {}
        for _, frame in pairs(raidFrames) do
            if frame then
                self:ResetFrame(frame)
            end
        end
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function RangeFade:Init(unitFramesModule)
    UnitFrames = unitFramesModule
    
    -- Add methods to UnitFrames for integration
    if UnitFrames then
        -- Method to get party frames (will be implemented in main module)
        if not UnitFrames.GetPartyMemberFrames then
            UnitFrames.GetPartyMemberFrames = function(self)
                return nil  -- Will be overridden
            end
        end
        
        -- Method to get range fade settings
        if not UnitFrames.GetRangeFadeSettings then
            UnitFrames.GetRangeFadeSettings = function(self)
                return RangeFade.DEFAULTS
            end
        end
    end
    
    TweaksUI:PrintDebug("UnitFrames RangeFade initialized")
end

-- ============================================================================
-- DEBUG COMMAND
-- ============================================================================

SLASH_TUIRANGE1 = "/tuirange"
SlashCmdList["TUIRANGE"] = function(msg)
    local args = {}
    for arg in msg:gmatch("%S+") do
        table.insert(args, arg:lower())
    end
    
    local cmd = args[1] or "status"
    
    if cmd == "on" or cmd == "start" then
        RangeFade:Start()
        print("|cff00ff00TweaksUI:|r Range fade started")
        
    elseif cmd == "off" or cmd == "stop" then
        RangeFade:Stop()
        print("|cff00ff00TweaksUI:|r Range fade stopped")
        
    elseif cmd == "reset" then
        if UnitFrames then
            local frames = UnitFrames:GetPartyMemberFrames()
            RangeFade:ResetAllFrames(frames)
        end
        print("|cff00ff00TweaksUI:|r Frame alphas reset")
        
    elseif cmd == "status" then
        print("|cff00ccffTweaksUI Range Fade Status:|r")
        print("  Active: " .. tostring(RangeFade.active))
        print("  Ticker: " .. tostring(RangeFade.ticker ~= nil))
        
        -- Show range status for party members
        if UnitFrames then
            local frames = UnitFrames:GetPartyMemberFrames()
            if frames then
                for i, frame in pairs(frames) do
                    if frame and frame.unit then
                        local inRange = frame.tuiInRange
                        local status = "unknown"
                        if inRange == true then
                            status = "|cff00ff00IN RANGE|r"
                        elseif inRange == false then
                            status = "|cffff0000OUT OF RANGE|r"
                        end
                        print("  " .. frame.unit .. ": " .. status)
                    end
                end
            else
                print("  No party frames available")
            end
        end
        
    else
        print("|cff00ff00TweaksUI Range Fade Commands:|r")
        print("  /tuirange [status] - Show status")
        print("  /tuirange on - Start range checking")
        print("  /tuirange off - Stop range checking")
        print("  /tuirange reset - Reset all alphas")
    end
end

return RangeFade
