-- ============================================================================
-- TweaksUI CooldownHighlights.lua
-- Creates positionable highlight clones for cooldown trackers
-- Supports: Essential Cooldowns, Utility Cooldowns, Custom Trackers
-- Active = ability ready (off cooldown), Inactive = on cooldown
-- ============================================================================

local addonName, TweaksUI = ...
TweaksUI.CooldownHighlights = TweaksUI.CooldownHighlights or {}
local CooldownHighlights = TweaksUI.CooldownHighlights

-- ============================================================================
-- MIDNIGHT API WRAPPERS (v2.0.0)
-- ============================================================================

local SpellAPI = TweaksUI.SpellAPI
local DurationAPI = TweaksUI.DurationAPI

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local UPDATE_INTERVAL = 0.2  -- 5 Hz update rate (balance of responsiveness and performance)
local DEFAULT_SIZE = 48

-- Tracker definitions
local TRACKER_TYPES = {
    essential = {
        key = "essential",
        viewerName = "EssentialCooldownViewer",
        displayName = "Essential Cooldowns",
        framePrefix = "TweaksUI_EssentialHighlight_",
        dbKey = "essentialHighlights",
    },
    utility = {
        key = "utility",
        viewerName = "UtilityCooldownViewer",
        displayName = "Utility Cooldowns",
        framePrefix = "TweaksUI_UtilityHighlight_",
        dbKey = "utilityHighlights",
    },
    custom = {
        key = "custom",
        viewerName = "TweaksUI_CustomTrackerFrame",
        displayName = "Custom Trackers",
        framePrefix = "TweaksUI_CustomHighlight_",
        dbKey = "customHighlights",
    },
}

-- ============================================================================
-- STATE (per tracker type)
-- ============================================================================

local highlightFrames = {
    essential = {},
    utility = {},
    custom = {},
}

-- Track cooldown state per-icon (true = on cooldown, false = ready)
local iconCooldownState = {
    essential = {},
    utility = {},
    custom = {},
}

local layoutWrappers = {
    essential = {},
    utility = {},
    custom = {},
}

local updateTickers = {}
local isInitialized = {}

-- Debug mode
local debugMode = false  -- Set to true for debugging
local function dprint(...)
    if debugMode then
        print("|cff00ccff[CooldownHighlights]|r", ...)
    end
end

-- ============================================================================
-- DATABASE
-- ============================================================================

local function GetDB(trackerKey)
    if not TweaksUI_CharDB then TweaksUI_CharDB = {} end
    
    local trackerType = TRACKER_TYPES[trackerKey]
    if not trackerType then return nil end
    
    local dbKey = trackerType.dbKey
    if not TweaksUI_CharDB[dbKey] then
        TweaksUI_CharDB[dbKey] = {
            hideTracker = false,
            enabled = {},
            positions = {},
            -- Custom label settings (per slot, state-independent)
            labelEnabled = {},
            labelText = {},
            labelFontSize = {},
            labelColor = {},
            labelOffsetX = {},
            labelOffsetY = {},
            active = {
                size = {},
                opacity = {},
                saturation = {},
                aspectRatio = {},
                customAspectW = {},
                customAspectH = {},
                show = {},
            },
            inactive = {
                size = {},
                opacity = {},
                saturation = {},
                aspectRatio = {},
                customAspectW = {},
                customAspectH = {},
                show = {},
            },
        }
    end
    
    local db = TweaksUI_CharDB[dbKey]
    
    -- Ensure all fields exist
    if not db.enabled then db.enabled = {} end
    if not db.positions then db.positions = {} end
    if not db.active then db.active = {} end
    if not db.inactive then db.inactive = {} end
    -- Custom label fields
    if not db.labelEnabled then db.labelEnabled = {} end
    if not db.labelText then db.labelText = {} end
    if not db.labelFontSize then db.labelFontSize = {} end
    if not db.labelColor then db.labelColor = {} end
    if not db.labelOffsetX then db.labelOffsetX = {} end
    if not db.labelOffsetY then db.labelOffsetY = {} end
    
    for _, state in ipairs({"active", "inactive"}) do
        if not db[state].size then db[state].size = {} end
        if not db[state].opacity then db[state].opacity = {} end
        if not db[state].saturation then db[state].saturation = {} end
        if not db[state].aspectRatio then db[state].aspectRatio = {} end
        if not db[state].customAspectW then db[state].customAspectW = {} end
        if not db[state].customAspectH then db[state].customAspectH = {} end
        if not db[state].show then db[state].show = {} end
    end
    
    -- Per-icon text settings (state-independent)
    if not db.cooldownTextScale then db.cooldownTextScale = {} end
    if not db.cooldownTextColor then db.cooldownTextColor = {} end
    if not db.cooldownTextOffsetX then db.cooldownTextOffsetX = {} end
    if not db.cooldownTextOffsetY then db.cooldownTextOffsetY = {} end
    if not db.countTextScale then db.countTextScale = {} end
    if not db.countTextColor then db.countTextColor = {} end
    if not db.countTextOffsetX then db.countTextOffsetX = {} end
    if not db.countTextOffsetY then db.countTextOffsetY = {} end
    
    -- Hidden icons (state-independent) - hides icon from tracker completely
    if not db.hidden then db.hidden = {} end
    
    return db
end

-- ============================================================================
-- SETTINGS HELPERS
-- ============================================================================

local function IsHighlightEnabled(trackerKey, slotIndex)
    local db = GetDB(trackerKey)
    return db and db.enabled[slotIndex] == true
end

local function SetHighlightEnabled(trackerKey, slotIndex, enabled)
    local db = GetDB(trackerKey)
    if db then db.enabled[slotIndex] = enabled end
end

local function GetStateSetting(trackerKey, slotIndex, state, key)
    local db = GetDB(trackerKey)
    return db and db[state] and db[state][key] and db[state][key][slotIndex]
end

local function SetStateSetting(trackerKey, slotIndex, state, key, value)
    local db = GetDB(trackerKey)
    if db and db[state] and db[state][key] then
        db[state][key][slotIndex] = value
    end
end

local function GetHighlightSize(trackerKey, slotIndex, state)
    return GetStateSetting(trackerKey, slotIndex, state or "active", "size") or DEFAULT_SIZE
end

local function SetHighlightSize(trackerKey, slotIndex, state, size)
    SetStateSetting(trackerKey, slotIndex, state, "size", size)
end

local function GetHighlightOpacity(trackerKey, slotIndex, state)
    local opacity = GetStateSetting(trackerKey, slotIndex, state or "active", "opacity")
    return opacity or 1.0
end

local function SetHighlightOpacity(trackerKey, slotIndex, state, opacity)
    SetStateSetting(trackerKey, slotIndex, state, "opacity", opacity)
end

local function GetHighlightSaturation(trackerKey, slotIndex, state)
    local sat = GetStateSetting(trackerKey, slotIndex, state or "active", "saturation")
    if sat == nil then
        return state == "active"  -- Default: saturated when active, desaturated when inactive
    end
    return sat
end

local function SetHighlightSaturation(trackerKey, slotIndex, state, saturated)
    SetStateSetting(trackerKey, slotIndex, state, "saturation", saturated)
end

local function GetHighlightAspectRatio(trackerKey, slotIndex, state)
    return GetStateSetting(trackerKey, slotIndex, state or "active", "aspectRatio") or "1:1"
end

local function SetHighlightAspectRatio(trackerKey, slotIndex, state, ratio)
    SetStateSetting(trackerKey, slotIndex, state, "aspectRatio", ratio)
end

local function GetShowState(trackerKey, slotIndex, state)
    local show = GetStateSetting(trackerKey, slotIndex, state, "show")
    if show == nil then
        -- Default: show when active (ready), hide when inactive (on cooldown)
        return state == "active"
    end
    return show
end

local function SetShowState(trackerKey, slotIndex, state, show)
    SetStateSetting(trackerKey, slotIndex, state, "show", show)
end

-- Custom label helpers (state-independent, applies to both active/inactive)
local function GetLabelEnabled(trackerKey, slotIndex)
    local db = GetDB(trackerKey)
    return db and db.labelEnabled[slotIndex] == true
end

local function SetLabelEnabled(trackerKey, slotIndex, enabled)
    local db = GetDB(trackerKey)
    if db then db.labelEnabled[slotIndex] = enabled end
end

local function GetLabelText(trackerKey, slotIndex)
    local db = GetDB(trackerKey)
    return db and db.labelText[slotIndex] or ""
end

local function SetLabelText(trackerKey, slotIndex, text)
    local db = GetDB(trackerKey)
    if db then db.labelText[slotIndex] = text end
end

local function GetLabelFontSize(trackerKey, slotIndex)
    local db = GetDB(trackerKey)
    return db and db.labelFontSize[slotIndex] or 14
end

local function SetLabelFontSize(trackerKey, slotIndex, size)
    local db = GetDB(trackerKey)
    if db then db.labelFontSize[slotIndex] = size end
end

local function GetLabelColor(trackerKey, slotIndex)
    local db = GetDB(trackerKey)
    return db and db.labelColor[slotIndex] or {1, 1, 1, 1}  -- Default white
end

local function SetLabelColor(trackerKey, slotIndex, color)
    local db = GetDB(trackerKey)
    if db then db.labelColor[slotIndex] = color end
end

local function GetLabelOffsetX(trackerKey, slotIndex)
    local db = GetDB(trackerKey)
    return db and db.labelOffsetX[slotIndex] or 0
end

local function SetLabelOffsetX(trackerKey, slotIndex, offset)
    local db = GetDB(trackerKey)
    if db then db.labelOffsetX[slotIndex] = offset end
end

local function GetLabelOffsetY(trackerKey, slotIndex)
    local db = GetDB(trackerKey)
    return db and db.labelOffsetY[slotIndex] or 0
end

local function SetLabelOffsetY(trackerKey, slotIndex, offset)
    local db = GetDB(trackerKey)
    if db then db.labelOffsetY[slotIndex] = offset end
end

local function GetHighlightPosition(trackerKey, slotIndex)
    local db = GetDB(trackerKey)
    return db and db.positions[slotIndex]
end

local function SetHighlightPosition(trackerKey, slotIndex, point, relPoint, x, y)
    local db = GetDB(trackerKey)
    if db then
        db.positions[slotIndex] = { point = point, relPoint = relPoint, x = x, y = y }
    end
end

local function IsTrackerHidden(trackerKey)
    local db = GetDB(trackerKey)
    return db and db.hideTracker == true
end

local function SetTrackerHidden(trackerKey, hidden)
    local db = GetDB(trackerKey)
    if db then
        db.hideTracker = hidden
    end
end

-- Per-icon hidden helpers (hides icon completely from tracker)
local function IsIconHidden(trackerKey, slotIndex)
    local db = GetDB(trackerKey)
    return db and db.hidden[slotIndex] == true
end

local function SetIconHidden(trackerKey, slotIndex, hidden)
    local db = GetDB(trackerKey)
    if db then db.hidden[slotIndex] = hidden end
end

-- Per-icon cooldown text helpers (countdown timer on cooldown spiral)
local function GetCooldownTextScale(trackerKey, slotIndex)
    local db = GetDB(trackerKey)
    return db and db.cooldownTextScale[slotIndex] or 1.0
end

local function SetCooldownTextScale(trackerKey, slotIndex, scale)
    local db = GetDB(trackerKey)
    if db then db.cooldownTextScale[slotIndex] = scale end
end

local function GetCooldownTextColor(trackerKey, slotIndex)
    local db = GetDB(trackerKey)
    return db and db.cooldownTextColor[slotIndex] or {1, 1, 1, 1}  -- Default white
end

local function SetCooldownTextColor(trackerKey, slotIndex, color)
    local db = GetDB(trackerKey)
    if db then db.cooldownTextColor[slotIndex] = color end
end

local function GetCooldownTextOffsetX(trackerKey, slotIndex)
    local db = GetDB(trackerKey)
    return db and db.cooldownTextOffsetX[slotIndex] or 0
end

local function SetCooldownTextOffsetX(trackerKey, slotIndex, offset)
    local db = GetDB(trackerKey)
    if db then db.cooldownTextOffsetX[slotIndex] = offset end
end

local function GetCooldownTextOffsetY(trackerKey, slotIndex)
    local db = GetDB(trackerKey)
    return db and db.cooldownTextOffsetY[slotIndex] or 0
end

local function SetCooldownTextOffsetY(trackerKey, slotIndex, offset)
    local db = GetDB(trackerKey)
    if db then db.cooldownTextOffsetY[slotIndex] = offset end
end

-- Per-icon count text helpers (stack/charge numbers)
local function GetCountTextScale(trackerKey, slotIndex)
    local db = GetDB(trackerKey)
    return db and db.countTextScale[slotIndex] or 1.0
end

local function SetCountTextScale(trackerKey, slotIndex, scale)
    local db = GetDB(trackerKey)
    if db then db.countTextScale[slotIndex] = scale end
end

local function GetCountTextColor(trackerKey, slotIndex)
    local db = GetDB(trackerKey)
    return db and db.countTextColor[slotIndex] or {1, 1, 1, 1}  -- Default white
end

local function SetCountTextColor(trackerKey, slotIndex, color)
    local db = GetDB(trackerKey)
    if db then db.countTextColor[slotIndex] = color end
end

local function GetCountTextOffsetX(trackerKey, slotIndex)
    local db = GetDB(trackerKey)
    return db and db.countTextOffsetX[slotIndex] or 0
end

local function SetCountTextOffsetX(trackerKey, slotIndex, offset)
    local db = GetDB(trackerKey)
    if db then db.countTextOffsetX[slotIndex] = offset end
end

local function GetCountTextOffsetY(trackerKey, slotIndex)
    local db = GetDB(trackerKey)
    return db and db.countTextOffsetY[slotIndex] or 0
end

local function SetCountTextOffsetY(trackerKey, slotIndex, offset)
    local db = GetDB(trackerKey)
    if db then db.countTextOffsetY[slotIndex] = offset end
end

-- ============================================================================
-- ICON COLLECTION
-- ============================================================================

local function IsIcon(frame)
    if not frame then return false end
    if frame.Cooldown or frame.cooldown then return true end
    if frame.Icon or frame.icon then return true end
    return false
end

local function GetViewer(trackerKey)
    local trackerType = TRACKER_TYPES[trackerKey]
    if not trackerType then return nil end
    return _G[trackerType.viewerName]
end

local function CollectIcons(trackerKey)
    local icons = {}
    local viewer = GetViewer(trackerKey)
    
    if not viewer or not viewer.GetChildren then return icons end
    
    local numChildren = viewer:GetNumChildren() or 0
    
    for i = 1, numChildren do
        local child = select(i, viewer:GetChildren())
        -- Don't check IsShown - icons might briefly hide during GCD/updates
        if child and IsIcon(child) then
            icons[#icons + 1] = child
        elseif child and child.GetNumChildren then
            local numNested = child:GetNumChildren() or 0
            for j = 1, numNested do
                local nested = select(j, child:GetChildren())
                if nested and IsIcon(nested) then
                    icons[#icons + 1] = nested
                end
            end
        end
    end
    
    -- Sort by visual position (top-to-bottom, left-to-right)
    table.sort(icons, function(a, b)
        local at, bt = a:GetTop() or 0, b:GetTop() or 0
        local al, bl = a:GetLeft() or 0, b:GetLeft() or 0
        if math.abs(at - bt) > 5 then return at > bt end
        return al < bl
    end)
    
    return icons
end

-- ============================================================================
-- VISUAL STATE DETECTION (no secret value math)
-- ============================================================================

local GCD_THRESHOLD = 3000  -- Cooldowns longer than 3000ms (3 sec) are "real" cooldowns, not GCD (~1500ms)

-- Detect visual state by checking if source icon appears "ready" or "on cooldown"
-- This is used for initial state detection; final check happens at end of update
local function GetIconVisualState(icon)
    if not icon then return true end  -- Default to "ready" if no icon
    
    local isReady = true
    
    -- Check cooldown frame times - only count as "on cooldown" if duration > GCD
    -- NOTE: GetCooldownTimes returns MILLISECONDS
    pcall(function()
        local cooldown = icon.Cooldown or icon.cooldown
        if cooldown and cooldown.GetCooldownTimes then
            local start, duration = cooldown:GetCooldownTimes()
            if start and duration and type(start) == "number" and type(duration) == "number" and duration > 0 then
                -- Only count as "on cooldown" if duration > 3000ms (3 sec)
                if duration > GCD_THRESHOLD then
                    -- Convert to seconds for remaining time check
                    local startSec = start / 1000
                    local durationSec = duration / 1000
                    local remaining = (startSec + durationSec) - GetTime()
                    if remaining > 0.1 then
                        isReady = false
                    end
                end
            end
        end
    end)
    
    return isReady
end

local function GetSlotInfo(trackerKey, slotIndex)
    -- Use Cooldowns.GetOrderedIcons if available (same order as layout/list)
    local icons
    local Cooldowns = TweaksUI.ModuleManager and TweaksUI.ModuleManager:GetModule(TweaksUI.MODULE_IDS.COOLDOWNS)
    if Cooldowns and Cooldowns.GetOrderedIcons then
        local viewer = GetViewer(trackerKey)
        if viewer then
            icons = Cooldowns.GetOrderedIcons(viewer, trackerKey)
        else
            icons = {}
        end
    else
        -- Fallback to local CollectIcons
        icons = CollectIcons(trackerKey)
    end
    
    local icon = icons[slotIndex]
    
    if not icon then return nil end
    
    local info = {
        icon = icon,
        isActive = true,  -- Will be set by visual state check
        texture = nil,
        name = "Slot " .. slotIndex,
    }
    
    -- Get visual state (ready vs on cooldown) without doing cooldown math
    info.isActive = GetIconVisualState(icon)
    
    -- Get texture safely
    local textureObj = icon.Icon or icon.icon
    if textureObj then
        pcall(function()
            info.texture = textureObj:GetTexture()
        end)
    end
    
    return info
end

local function GetSlotCount(trackerKey)
    -- Use Cooldowns.GetOrderedIcons if available (same order as layout/list)
    local Cooldowns = TweaksUI.ModuleManager and TweaksUI.ModuleManager:GetModule(TweaksUI.MODULE_IDS.COOLDOWNS)
    if Cooldowns and Cooldowns.GetOrderedIcons then
        local viewer = GetViewer(trackerKey)
        if viewer then
            return #Cooldowns.GetOrderedIcons(viewer, trackerKey)
        end
    end
    -- Fallback
    return #CollectIcons(trackerKey)
end

-- ============================================================================
-- HIGHLIGHT FRAME CREATION
-- ============================================================================

local function CreateHighlightFrame(trackerKey, slotIndex)
    if highlightFrames[trackerKey][slotIndex] then
        return highlightFrames[trackerKey][slotIndex]
    end
    
    local trackerType = TRACKER_TYPES[trackerKey]
    local frameName = trackerType.framePrefix .. slotIndex
    local size = GetHighlightSize(trackerKey, slotIndex)
    
    local frame = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
    frame:SetSize(size, size)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(100)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(false)
    
    -- Background
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.6)
    frame:SetBackdropBorderColor(0, 0, 0, 1)
    
    -- Icon texture
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("TOPLEFT", 2, -2)
    frame.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    -- Cooldown spiral (uses CooldownFrameTemplate which includes countdown text)
    frame.cooldown = CreateFrame("Cooldown", frameName .. "_Cooldown", frame, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints(frame.icon)
    frame.cooldown:SetDrawEdge(true)
    frame.cooldown:SetDrawBling(false)
    frame.cooldown:SetDrawSwipe(true)
    frame.cooldown:SetHideCountdownNumbers(false)
    frame.cooldown:SetSwipeColor(0, 0, 0, 0.8)
    
    -- Charge/stack count text (bottom right corner, explicitly above cooldown)
    frame.count = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    frame.count:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    frame.count:SetJustifyH("RIGHT")
    frame.count:SetDrawLayer("OVERLAY", 7)  -- High sublayer to ensure above cooldown text
    
    -- Proc glow overlay (using Blizzard's built-in glow)
    -- We'll use ActionButton overlay glow system if available
    frame.glowFrame = CreateFrame("Frame", frameName .. "_Glow", frame)
    frame.glowFrame:SetAllPoints()
    frame.glowFrame:SetFrameLevel(frame:GetFrameLevel() + 5)
    frame.glowFrame:Hide()
    
    -- Create the glow texture (yellow spell activation border)
    frame.glowTexture = frame.glowFrame:CreateTexture(nil, "OVERLAY")
    frame.glowTexture:SetPoint("TOPLEFT", -8, 8)
    frame.glowTexture:SetPoint("BOTTOMRIGHT", 8, -8)
    frame.glowTexture:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    frame.glowTexture:SetBlendMode("ADD")
    frame.glowTexture:SetVertexColor(1, 1, 0.6, 0.8)
    
    -- Animated glow ants (the spinning border effect)
    frame.glowAnts = frame.glowFrame:CreateTexture(nil, "OVERLAY")
    frame.glowAnts:SetPoint("TOPLEFT", -4, 4)
    frame.glowAnts:SetPoint("BOTTOMRIGHT", 4, -4)
    frame.glowAnts:SetTexture("Interface\\Cooldown\\star4")
    frame.glowAnts:SetBlendMode("ADD")
    frame.glowAnts:SetVertexColor(1, 1, 0.5, 0.6)
    
    -- Animation group for the glow
    frame.glowAnim = frame.glowAnts:CreateAnimationGroup()
    frame.glowAnim:SetLooping("REPEAT")
    local rotation = frame.glowAnim:CreateAnimation("Rotation")
    rotation:SetDegrees(-360)
    rotation:SetDuration(4)
    
    -- Custom accessibility label (user-defined text overlay)
    frame.customLabel = frame:CreateFontString(nil, "OVERLAY")
    frame.customLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    frame.customLabel:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.customLabel:SetTextColor(1, 1, 1, 1)
    frame.customLabel:SetShadowOffset(1, -1)
    frame.customLabel:SetShadowColor(0, 0, 0, 1)
    frame.customLabel:SetDrawLayer("OVERLAY", 7)
    frame.customLabel:Hide()
    
    -- Store references
    frame.trackerKey = trackerKey
    frame.slotIndex = slotIndex
    
    -- Set initial position
    local pos = GetHighlightPosition(trackerKey, slotIndex)
    if pos then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x, pos.y)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", -200 + (slotIndex * 60), -150)
    end
    
    frame:Hide()
    highlightFrames[trackerKey][slotIndex] = frame
    
    dprint("Created highlight frame:", trackerKey, slotIndex)
    return frame
end

-- ============================================================================
-- ASPECT RATIO
-- ============================================================================

local function ParseAspectRatio(aspectStr, trackerKey, slotIndex, state)
    if aspectStr == "custom" then
        local db = GetDB(trackerKey)
        local w = db and db[state].customAspectW[slotIndex] or 1
        local h = db and db[state].customAspectH[slotIndex] or 1
        return w, h
    end
    
    local w, h = aspectStr:match("(%d+):(%d+)")
    if w and h then
        return tonumber(w), tonumber(h)
    end
    return 1, 1
end

local function ApplyAspectRatio(frame, size, aspectStr, trackerKey, slotIndex, state)
    local ratioW, ratioH = ParseAspectRatio(aspectStr, trackerKey, slotIndex, state)
    local width, height
    
    if ratioW >= ratioH then
        width = size
        height = size * (ratioH / ratioW)
    else
        height = size
        width = size * (ratioW / ratioH)
    end
    
    frame:SetSize(width, height)
end

-- ============================================================================
-- UPDATE LOGIC
-- ============================================================================

local function UpdateHighlightFrame(trackerKey, slotIndex)
    local frame = highlightFrames[trackerKey][slotIndex]
    if not frame then return end
    
    if not IsHighlightEnabled(trackerKey, slotIndex) then
        frame:Hide()
        return
    end
    
    local slotInfo = GetSlotInfo(trackerKey, slotIndex)
    
    -- Check if Layout mode is active
    local isLayoutMode = false
    local layoutContainer = _G["TweaksUI_LayoutContainer"]
    if layoutContainer and layoutContainer:IsShown() then
        isLayoutMode = true
    end
    
    if not slotInfo then
        if isLayoutMode then
            local size = GetHighlightSize(trackerKey, slotIndex, "active")
            local aspectRatio = GetHighlightAspectRatio(trackerKey, slotIndex, "active")
            ApplyAspectRatio(frame, size, aspectRatio, trackerKey, slotIndex, "active")
            frame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            frame.icon:SetDesaturated(true)
            frame.cooldown:Clear()
            if frame.count then frame.count:Hide() end
            if frame.glowFrame then frame.glowFrame:Hide() end
            frame:SetAlpha(0.5)
            
            -- Update custom label even without slot info
            if frame.customLabel then
                if GetLabelEnabled(trackerKey, slotIndex) then
                    local labelText = GetLabelText(trackerKey, slotIndex)
                    local fontSize = GetLabelFontSize(trackerKey, slotIndex)
                    local labelColor = GetLabelColor(trackerKey, slotIndex)
                    local offsetX = GetLabelOffsetX(trackerKey, slotIndex)
                    local offsetY = GetLabelOffsetY(trackerKey, slotIndex)
                    
                    frame.customLabel:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
                    frame.customLabel:SetText(labelText)
                    frame.customLabel:SetTextColor(labelColor[1] or 1, labelColor[2] or 1, labelColor[3] or 1, labelColor[4] or 1)
                    frame.customLabel:ClearAllPoints()
                    frame.customLabel:SetPoint("CENTER", frame, "CENTER", offsetX, offsetY)
                    frame.customLabel:Show()
                else
                    frame.customLabel:Hide()
                end
            end
            
            frame:Show()
        else
            -- DEBUG: slotInfo is nil - this could cause icons to hide incorrectly
            if debugMode then
                dprint(string.format("[%s-%d] slotInfo is NIL - HIDING (not layout mode)", 
                    trackerKey, slotIndex))
            end
            frame:Hide()
        end
        return
    end
    
    -- Determine current state based on cooldown
    local currentState = slotInfo.isActive and "active" or "inactive"
    local showThisState = GetShowState(trackerKey, slotIndex, currentState)
    
    -- DEBUG: Log initial state
    if debugMode then
        dprint(string.format("[%s-%d] Initial state: %s (isActive=%s)", 
            trackerKey, slotIndex, currentState, tostring(slotInfo.isActive)))
    end
    
    -- During layout mode, always show
    if isLayoutMode then
        local size = GetHighlightSize(trackerKey, slotIndex, "active")
        local aspectRatio = GetHighlightAspectRatio(trackerKey, slotIndex, "active")
        ApplyAspectRatio(frame, size, aspectRatio, trackerKey, slotIndex, "active")
        
        if slotInfo.texture then
            frame.icon:SetTexture(slotInfo.texture)
        else
            frame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        
        if not showThisState then
            frame.icon:SetDesaturated(true)
            frame:SetAlpha(0.4)
        else
            local saturated = GetHighlightSaturation(trackerKey, slotIndex, currentState)
            local opacity = GetHighlightOpacity(trackerKey, slotIndex, currentState)
            frame.icon:SetDesaturated(not saturated)
            frame:SetAlpha(opacity)
        end
        
        frame.cooldown:Clear()
        if frame.count then frame.count:Hide() end
        if frame.glowFrame then frame.glowFrame:Hide() end
        
        -- Update custom label in layout mode too
        if frame.customLabel then
            if GetLabelEnabled(trackerKey, slotIndex) then
                local labelText = GetLabelText(trackerKey, slotIndex)
                local fontSize = GetLabelFontSize(trackerKey, slotIndex)
                local labelColor = GetLabelColor(trackerKey, slotIndex)
                local offsetX = GetLabelOffsetX(trackerKey, slotIndex)
                local offsetY = GetLabelOffsetY(trackerKey, slotIndex)
                
                frame.customLabel:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
                frame.customLabel:SetText(labelText)
                frame.customLabel:SetTextColor(labelColor[1] or 1, labelColor[2] or 1, labelColor[3] or 1, labelColor[4] or 1)
                frame.customLabel:ClearAllPoints()
                frame.customLabel:SetPoint("CENTER", frame, "CENTER", offsetX, offsetY)
                frame.customLabel:Show()
            else
                frame.customLabel:Hide()
            end
        end
        
        frame:Show()
        return
    end
    
    -- NOTE: We do NOT hide here based on initial state detection.
    -- The FINAL visibility check at the end handles show/hide per-icon
    -- after we've applied the cooldown and can accurately detect state.
    
    -- Get state-specific settings (use initial state for now, final check will correct)
    local size = GetHighlightSize(trackerKey, slotIndex, currentState)
    local opacity = GetHighlightOpacity(trackerKey, slotIndex, currentState)
    local saturated = GetHighlightSaturation(trackerKey, slotIndex, currentState)
    local aspectRatio = GetHighlightAspectRatio(trackerKey, slotIndex, currentState)
    
    -- Apply size and aspect ratio
    ApplyAspectRatio(frame, size, aspectRatio, trackerKey, slotIndex, currentState)
    
    -- Update icon texture
    if slotInfo.texture then
        frame.icon:SetTexture(slotInfo.texture)
    else
        frame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    
    -- Apply saturation and opacity
    frame.icon:SetDesaturated(not saturated)
    frame:SetAlpha(opacity)
    
    -- =========================================================================
    -- PURE PASS-THROUGH: Copy cooldown from source icon
    -- Use Midnight Duration Object APIs via SpellAPI wrapper
    -- =========================================================================
    local sourceIcon = slotInfo.icon
    local sourceCooldown = sourceIcon.Cooldown or sourceIcon.cooldown
    
    -- Get spellID for SpellAPI
    local spellID = sourceIcon.spellID or sourceIcon.SpellID or sourceIcon.spellId
    if not spellID and sourceIcon.GetSpellID then
        pcall(function() spellID = sourceIcon:GetSpellID() end)
    end
    
    local cooldownApplied = false
    
    -- Method 1: Source cooldown's GetCooldownDuration (Midnight Duration Object)
    if sourceCooldown and sourceCooldown.GetCooldownDuration and frame.cooldown.SetCooldownFromDurationObject then
        local success = pcall(function()
            frame.cooldown:SetCooldownFromDurationObject(sourceCooldown:GetCooldownDuration(), true)
        end)
        if success then cooldownApplied = true end
    end
    
    -- Method 2: Use SpellAPI wrapper (handles Duration Object natively)
    if not cooldownApplied and spellID and SpellAPI then
        cooldownApplied = SpellAPI:ApplyCooldownToFrame(frame.cooldown, spellID, true)
    end
    
    -- =========================================================================
    -- GET CHARGE/COUNT TEXT - Use Midnight's display count API
    -- =========================================================================
    
    -- Get spellID via GetSpellID() method
    local spellID = nil
    if sourceIcon.GetSpellID then
        spellID = sourceIcon:GetSpellID()
    end
    spellID = spellID or sourceIcon.spellID or sourceIcon.SpellID or sourceIcon.spellId
    
    -- Use C_Spell.GetSpellDisplayCount (Midnight API - handles secret values properly)
    if spellID and C_Spell and C_Spell.GetSpellDisplayCount then
        local displayCount = C_Spell.GetSpellDisplayCount(spellID)
        frame.count:SetText(displayCount or "")
        frame.count:Show()
    elseif spellID and C_Spell and C_Spell.GetSpellCharges then
        -- Fallback for non-Midnight: just pass currentCharges through
        local chargeInfo = C_Spell.GetSpellCharges(spellID)
        if chargeInfo then
            frame.count:SetText(chargeInfo.currentCharges or "")
            frame.count:Show()
        else
            frame.count:SetText("")
            frame.count:Hide()
        end
    else
        frame.count:SetText("")
        frame.count:Hide()
    end
    
    -- =========================================================================
    -- Copy glow state from source icon (proc/spell activation glow)
    -- =========================================================================
    local showGlow = false
    pcall(function()
        -- Check for overlay glow frame (standard Blizzard glow)
        if sourceIcon.overlay and sourceIcon.overlay:IsShown() then
            showGlow = true
        elseif sourceIcon.SpellActivationAlert and sourceIcon.SpellActivationAlert:IsShown() then
            showGlow = true
        elseif sourceIcon.OverlayGlow and sourceIcon.OverlayGlow:IsShown() then
            showGlow = true
        -- Check for children that might be glow frames
        elseif sourceIcon.GetChildren then
            for i = 1, sourceIcon:GetNumChildren() do
                local child = select(i, sourceIcon:GetChildren())
                if child and child:IsShown() then
                    local name = child:GetName() or ""
                    if name:find("Glow") or name:find("Overlay") or name:find("Activation") then
                        showGlow = true
                        break
                    end
                end
            end
        end
    end)
    
    -- Apply glow state to our frame
    if frame.glowFrame then
        if showGlow then
            frame.glowFrame:Show()
            if frame.glowAnim and not frame.glowAnim:IsPlaying() then
                frame.glowAnim:Play()
            end
        else
            frame.glowFrame:Hide()
            if frame.glowAnim and frame.glowAnim:IsPlaying() then
                frame.glowAnim:Stop()
            end
        end
    end
    
    -- =========================================================================
    -- Copy vertex color from source for visual consistency (greyed out on cooldown etc)
    -- Blizzard's native range/usability overlays pass through automatically
    -- =========================================================================
    pcall(function()
        local sourceIconTex = sourceIcon.Icon or sourceIcon.icon
        if not sourceIconTex and sourceIcon.GetRegions then
            for i = 1, sourceIcon:GetNumRegions() do
                local region = select(i, sourceIcon:GetRegions())
                if region and region:IsShown() and region:GetObjectType() == "Texture" and region.GetVertexColor then
                    sourceIconTex = region
                    break
                end
            end
        end
        
        if sourceIconTex and sourceIconTex.GetVertexColor and frame.icon then
            local r, g, b, a = sourceIconTex:GetVertexColor()
            if r and g and b then
                frame.icon:SetVertexColor(r, g, b, a or 1)
            end
        end
    end)
    
    -- =========================================================================
    -- Custom accessibility label
    -- =========================================================================
    if frame.customLabel then
        if GetLabelEnabled(trackerKey, slotIndex) then
            local labelText = GetLabelText(trackerKey, slotIndex)
            local fontSize = GetLabelFontSize(trackerKey, slotIndex)
            local labelColor = GetLabelColor(trackerKey, slotIndex)
            local offsetX = GetLabelOffsetX(trackerKey, slotIndex)
            local offsetY = GetLabelOffsetY(trackerKey, slotIndex)
            
            frame.customLabel:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
            frame.customLabel:SetText(labelText)
            frame.customLabel:SetTextColor(labelColor[1] or 1, labelColor[2] or 1, labelColor[3] or 1, labelColor[4] or 1)
            frame.customLabel:ClearAllPoints()
            frame.customLabel:SetPoint("CENTER", frame, "CENTER", offsetX, offsetY)
            frame.customLabel:Show()
        else
            frame.customLabel:Hide()
        end
    end
    
    -- =========================================================================
    -- Apply per-icon text scale, color, and offset settings
    -- =========================================================================
    local cooldownTextScale = GetCooldownTextScale(trackerKey, slotIndex)
    local cooldownTextColor = GetCooldownTextColor(trackerKey, slotIndex)
    local cooldownTextOffsetX = GetCooldownTextOffsetX(trackerKey, slotIndex)
    local cooldownTextOffsetY = GetCooldownTextOffsetY(trackerKey, slotIndex)
    local countTextScale = GetCountTextScale(trackerKey, slotIndex)
    local countTextColor = GetCountTextColor(trackerKey, slotIndex)
    local countTextOffsetX = GetCountTextOffsetX(trackerKey, slotIndex)
    local countTextOffsetY = GetCountTextOffsetY(trackerKey, slotIndex)
    
    -- Scale, color, and offset cooldown text (countdown numbers on the cooldown spiral)
    if frame.cooldown then
        pcall(function()
            -- Try to find the countdown text in the cooldown frame
            local cdText = frame.cooldown.Text or frame.cooldown.text
            if not cdText then
                -- Search regions for FontString
                for i = 1, frame.cooldown:GetNumRegions() do
                    local region = select(i, frame.cooldown:GetRegions())
                    if region and region:GetObjectType() == "FontString" then
                        cdText = region
                        break
                    end
                end
            end
            
            if cdText then
                if cdText.GetFont then
                    local fontPath, _, fontFlags = cdText:GetFont()
                    if fontPath then
                        local baseSize = 14  -- Base font size for cooldown text
                        cdText:SetFont(fontPath, baseSize * cooldownTextScale, fontFlags or "OUTLINE")
                    end
                end
                if cdText.SetTextColor then
                    cdText:SetTextColor(cooldownTextColor[1] or 1, cooldownTextColor[2] or 1, cooldownTextColor[3] or 1, cooldownTextColor[4] or 1)
                end
                -- Apply offset
                if (cooldownTextOffsetX ~= 0 or cooldownTextOffsetY ~= 0) and cdText.ClearAllPoints then
                    cdText:ClearAllPoints()
                    cdText:SetPoint("CENTER", frame.cooldown, "CENTER", cooldownTextOffsetX, cooldownTextOffsetY)
                end
            end
        end)
    end
    
    -- Scale, color, and offset count text (stack/charge numbers)
    if frame.count then
        pcall(function()
            local fontPath, _, fontFlags = frame.count:GetFont()
            if fontPath then
                local baseSize = 12  -- Base font size for count text
                frame.count:SetFont(fontPath, baseSize * countTextScale, fontFlags or "OUTLINE")
            end
            frame.count:SetTextColor(countTextColor[1] or 1, countTextColor[2] or 1, countTextColor[3] or 1, countTextColor[4] or 1)
            -- Apply offset (count is normally at BOTTOMRIGHT)
            if countTextOffsetX ~= 0 or countTextOffsetY ~= 0 then
                frame.count:ClearAllPoints()
                frame.count:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2 + countTextOffsetX, 2 + countTextOffsetY)
            end
        end)
    end
    
    -- =========================================================================
    -- FINAL VISIBILITY: Check cooldown state per-icon and hide/show accordingly
    -- Only hide if we can CONFIRM this specific icon has a real cooldown > GCD
    -- Default to SHOWING if we can't determine cooldown state
    -- =========================================================================
    local showInactive = GetShowState(trackerKey, slotIndex, "inactive")
    local showActive = GetShowState(trackerKey, slotIndex, "active")
    
    -- Default to "ready" (not on cooldown) - only set to true if we CONFIRM a real cooldown
    local thisIconOnCooldown = false
    local detectedDuration = 0
    
    -- Try to get actual cooldown duration from our highlight frame
    -- NOTE: GetCooldownTimes returns MILLISECONDS (start and duration)
    pcall(function()
        if frame.cooldown and frame.cooldown.GetCooldownTimes then
            local start, duration = frame.cooldown:GetCooldownTimes()
            
            if start and duration and type(start) == "number" and type(duration) == "number" and duration > 0 then
                detectedDuration = duration
                -- Convert ms to seconds for comparison with GetTime()
                local startSec = start / 1000
                local durationSec = duration / 1000
                local remaining = (startSec + durationSec) - GetTime()
                
                -- Only count as "on cooldown" if duration > 3000ms (3 sec) - ignore GCD (~1500ms)
                if remaining > 0.1 and duration > GCD_THRESHOLD then
                    thisIconOnCooldown = true
                end
            end
        end
    end)
    
    -- Fallback: Try source icon's cooldown if we haven't confirmed yet
    if not thisIconOnCooldown and detectedDuration == 0 then
        pcall(function()
            if sourceCooldown and sourceCooldown.GetCooldownTimes then
                local start, duration = sourceCooldown:GetCooldownTimes()
                
                if start and duration and type(start) == "number" and type(duration) == "number" and duration > 0 then
                    detectedDuration = duration
                    -- Convert ms to seconds for comparison with GetTime()
                    local startSec = start / 1000
                    local durationSec = duration / 1000
                    local remaining = (startSec + durationSec) - GetTime()
                    
                    -- Only count as "on cooldown" if duration > 3000ms (3 sec)
                    if remaining > 0.1 and duration > GCD_THRESHOLD then
                        thisIconOnCooldown = true
                    end
                end
            end
        end)
    end
    
    -- DEBUG: Print when we're about to hide an icon
    if debugMode and (thisIconOnCooldown or detectedDuration > 0) then
        dprint(string.format("[%s-%d] Duration=%dms (%.1fs), OnCD=%s, showInactive=%s, showActive=%s",
            trackerKey, slotIndex, detectedDuration, detectedDuration/1000,
            tostring(thisIconOnCooldown), tostring(showInactive), tostring(showActive)))
    end
    
    -- Store state for debugging
    iconCooldownState[trackerKey][slotIndex] = thisIconOnCooldown
    
    -- Determine visibility based on confirmed cooldown state
    local shouldShow = true
    if thisIconOnCooldown then
        -- CONFIRMED on a real cooldown (> GCD) - check if user wants inactive state shown
        if not showInactive then
            shouldShow = false
            if debugMode then
                dprint(string.format("[%s-%d] HIDING: On cooldown (%dms) and showInactive=false", 
                    trackerKey, slotIndex, detectedDuration))
            end
        end
    else
        -- Either ready OR couldn't confirm cooldown - treat as ready
        -- Check if user wants active state shown
        if not showActive then
            shouldShow = false
            if debugMode then
                dprint(string.format("[%s-%d] HIDING: Ready and showActive=false", 
                    trackerKey, slotIndex))
            end
        end
    end
    
    if shouldShow then
        -- Apply correct state's visual settings
        local actualState = thisIconOnCooldown and "inactive" or "active"
        local actualOpacity = GetHighlightOpacity(trackerKey, slotIndex, actualState)
        local actualSaturated = GetHighlightSaturation(trackerKey, slotIndex, actualState)
        frame:SetAlpha(actualOpacity)
        frame.icon:SetDesaturated(not actualSaturated)
        frame:Show()
    else
        frame:Hide()
    end
end

local function UpdateAllHighlights(trackerKey)
    local db = GetDB(trackerKey)
    if not db then return end
    
    local inCombat = InCombatLockdown()
    
    for slotIndex, enabled in pairs(db.enabled) do
        if enabled then
            -- Only create frames outside of combat to avoid taint
            if not highlightFrames[trackerKey][slotIndex] then
                if not inCombat then
                    pcall(CreateHighlightFrame, trackerKey, slotIndex)
                end
            end
            -- Only update if frame exists
            if highlightFrames[trackerKey][slotIndex] then
                local success, err = pcall(UpdateHighlightFrame, trackerKey, slotIndex)
                if not success and debugMode then
                    dprint("UpdateHighlightFrame error:", trackerKey, slotIndex, tostring(err))
                end
            end
        end
    end
end

-- ============================================================================
-- LAYOUT INTEGRATION
-- ============================================================================

local function CreateLayoutWrapper(trackerKey, slotIndex)
    local frame = highlightFrames[trackerKey][slotIndex]
    if not frame then return nil end
    
    local trackerType = TRACKER_TYPES[trackerKey]
    local wrapperId = trackerType.framePrefix .. slotIndex
    
    local wrapper = {
        id = wrapperId,
        name = trackerType.displayName .. " #" .. slotIndex,
        category = "Cooldowns",
        frame = frame,
        hideSizeMatching = true,
        defaultPosition = {
            point = "CENTER",
            x = -200 + (slotIndex * 60),
            y = -150,
        },
        contentFrames = {},
        
        onPositionChanged = function(self, point, relFrame, relPoint, x, y)
            frame:ClearAllPoints()
            frame:SetPoint(point, UIParent, point, x, y)
            SetHighlightPosition(trackerKey, slotIndex, point, point, x, y)
        end,
        
        GetPosition = function(self)
            local point, relTo, relPoint, x, y = frame:GetPoint(1)
            return { point = point, relFrame = relTo, relPoint = relPoint, x = x, y = y }
        end,
        
        SetPosition = function(self, point, relFrame, relPoint, x, y)
            frame:ClearAllPoints()
            frame:SetPoint(point, relFrame or UIParent, relPoint or point, x or 0, y or 0)
            if self.onPositionChanged then
                self:onPositionChanged(point, relFrame, relPoint, x, y)
            end
        end,
        
        LoadSaveData = function(self, data)
            if not data then return end
            local point = data.point or "CENTER"
            self:SetPosition(point, UIParent, point, data.x, data.y)
            if data.scale then
                self:SetScale(data.scale)
            end
        end,
        
        SetScale = function(self, scale)
            if frame and scale then
                frame:SetScale(scale)
            end
        end,
        
        GetScale = function(self)
            return frame:GetScale() or 1
        end,
        
        GetSize = function(self)
            return frame:GetSize()
        end,
        
        SetSize = function(self, width, height)
            if frame and width and height then
                frame:SetSize(width, height)
            end
        end,
        
        IsShown = function(self)
            local layoutContainer = _G["TweaksUI_LayoutContainer"]
            if layoutContainer and layoutContainer:IsShown() then
                return true
            end
            return frame and frame:IsShown()
        end,
        
        GetSaveData = function(self)
            local left = frame:GetLeft()
            local bottom = frame:GetBottom()
            if not left or not bottom then
                local point, _, _, x, y = frame:GetPoint(1)
                return {
                    point = point or "CENTER",
                    x = x or 0,
                    y = y or 0,
                    scale = self:GetScale(),
                }
            end
            return {
                point = "BOTTOMLEFT",
                x = left,
                y = bottom,
                scale = self:GetScale(),
            }
        end,
        
        GetSnapTarget = function(self, tolerance)
            local FlyPaper = LibStub and LibStub("LibFlyPaper-2.0", true)
            if not FlyPaper then return nil end
            tolerance = tolerance or 15
            local point, relFrame, relPoint, x, y = FlyPaper.GetBestAnchorForGroup(
                frame,
                "TweaksUI",
                tolerance
            )
            if point and relFrame then
                return relFrame, point, relPoint, x, y
            end
            return nil
        end,
        
        sizeLocked = false,
        SetSizeLocked = function(self, locked)
            self.sizeLocked = locked
        end,
        IsSizeLocked = function(self)
            return self.sizeLocked
        end,
        
        ForceSetSize = function(self, width, height)
            if frame and width and height then
                frame:SetSize(width, height)
            end
        end,
        
        GetWidth = function(self)
            return frame:GetWidth()
        end,
        GetHeight = function(self)
            return frame:GetHeight()
        end,
        SetWidth = function(self, width)
            if frame and width then
                frame:SetWidth(width)
            end
        end,
        SetHeight = function(self, height)
            if frame and height then
                frame:SetHeight(height)
            end
        end,
    }
    
    return wrapper
end

local function RegisterWithLayout(trackerKey, slotIndex)
    local frame = highlightFrames[trackerKey][slotIndex]
    if not frame then return end
    
    local trackerType = TRACKER_TYPES[trackerKey]
    local wrapperId = trackerType.framePrefix .. slotIndex
    
    if layoutWrappers[trackerKey][slotIndex] then
        return layoutWrappers[trackerKey][slotIndex]
    end
    
    local wrapper = CreateLayoutWrapper(trackerKey, slotIndex)
    if not wrapper then return nil end
    
    layoutWrappers[trackerKey][slotIndex] = wrapper
    
    local Layout = TweaksUI.Layout
    if Layout and Layout.RegisterElement then
        Layout:RegisterElement(wrapperId, {
            name = wrapper.name,
            category = "Cooldowns",
            tuiFrame = wrapper,
            defaultPosition = wrapper.defaultPosition,
            onPositionChanged = function(id, pos)
                if wrapper.onPositionChanged then
                    wrapper:onPositionChanged(pos.point, pos.relFrame, pos.relPoint, pos.x, pos.y)
                end
            end,
        })
        dprint("Registered with Layout:", trackerKey, slotIndex)
    end
    
    return wrapper
end

local function UnregisterFromLayout(trackerKey, slotIndex)
    local trackerType = TRACKER_TYPES[trackerKey]
    local wrapperId = trackerType.framePrefix .. slotIndex
    
    local Layout = TweaksUI.Layout
    if Layout and Layout.UnregisterElement then
        Layout:UnregisterElement(wrapperId)
    end
    
    layoutWrappers[trackerKey][slotIndex] = nil
    dprint("Unregistered from Layout:", trackerKey, slotIndex)
end

local function RegisterAllWithLayout(trackerKey)
    local db = GetDB(trackerKey)
    if not db then return end
    
    for slotIndex, enabled in pairs(db.enabled) do
        if enabled then
            if highlightFrames[trackerKey][slotIndex] then
                RegisterWithLayout(trackerKey, slotIndex)
            end
        end
    end
end

-- ============================================================================
-- UPDATE TICKER
-- ============================================================================

local function StartUpdateTicker(trackerKey)
    if updateTickers[trackerKey] then return end
    
    updateTickers[trackerKey] = C_Timer.NewTicker(UPDATE_INTERVAL, function()
        pcall(UpdateAllHighlights, trackerKey)
    end)
    dprint("Started update ticker:", trackerKey)
end

local function StopUpdateTicker(trackerKey)
    if updateTickers[trackerKey] then
        updateTickers[trackerKey]:Cancel()
        updateTickers[trackerKey] = nil
        dprint("Stopped update ticker:", trackerKey)
    end
end

-- ============================================================================
-- TRACKER HIDE ENFORCEMENT
-- Uses alpha 0 + non-interactable instead of blocking Show()
-- This allows the tracker to function normally so per-icon clones can read it
-- ============================================================================

local hideEnforcementTickers = {}
local hookedFrames = {}  -- Track which frames have been hooked

-- Hook a frame's SetAlpha to block making visible when tracker is hidden
local function HookFrameAlpha(frame, trackerKey)
    if not frame or hookedFrames[frame] then return end
    
    local originalSetAlpha = frame.SetAlpha
    frame.SetAlpha = function(self, alpha, ...)
        -- Check if we should force alpha to 0
        if IsTrackerHidden(trackerKey) and alpha > 0 then
            -- Allow during layout mode
            local Layout = TweaksUI.Layout
            if Layout and Layout:IsActive() then
                return originalSetAlpha(self, alpha, ...)
            end
            -- Force alpha to 0
            return originalSetAlpha(self, 0, ...)
        end
        return originalSetAlpha(self, alpha, ...)
    end
    
    hookedFrames[frame] = true
    dprint("Hooked SetAlpha on frame for tracker:", trackerKey)
end

local function StartHideEnforcement(trackerKey)
    -- Determine the correct frames
    local container, viewer
    if trackerKey == "custom" then
        container = _G["TweaksUI_CustomTrackerFrame"]
    else
        container = _G["TweaksUI_CDContainer_" .. trackerKey]
        viewer = GetViewer(trackerKey)
    end
    
    -- Hook SetAlpha on both container and viewer
    if container then HookFrameAlpha(container, trackerKey) end
    if viewer then HookFrameAlpha(viewer, trackerKey) end
    
    -- Immediately apply hidden state (alpha 0, non-interactable)
    if container then
        container:SetAlpha(0)
        container:EnableMouse(false)
    end
    if viewer then
        viewer:SetAlpha(0)
        viewer:EnableMouse(false)
    end
    
    -- Backup ticker to catch any frames that get created later
    if hideEnforcementTickers[trackerKey] then return end
    
    hideEnforcementTickers[trackerKey] = C_Timer.NewTicker(0.5, function()
        if not IsTrackerHidden(trackerKey) then
            StopHideEnforcement(trackerKey)
            return
        end
        
        -- Skip during layout mode
        local Layout = TweaksUI.Layout
        if Layout and Layout:IsActive() then
            return
        end
        
        -- Ensure frames stay at alpha 0
        local frameToManage
        if trackerKey == "custom" then
            frameToManage = _G["TweaksUI_CustomTrackerFrame"]
        else
            frameToManage = _G["TweaksUI_CDContainer_" .. trackerKey]
        end
        
        if frameToManage and frameToManage:GetAlpha() > 0 then
            frameToManage:SetAlpha(0)
            frameToManage:EnableMouse(false)
        end
        
        -- Also check viewer
        if trackerKey ~= "custom" then
            local viewerFrame = GetViewer(trackerKey)
            if viewerFrame and viewerFrame:GetAlpha() > 0 then
                viewerFrame:SetAlpha(0)
                viewerFrame:EnableMouse(false)
            end
        end
    end)
end

StopHideEnforcement = function(trackerKey)
    if hideEnforcementTickers[trackerKey] then
        hideEnforcementTickers[trackerKey]:Cancel()
        hideEnforcementTickers[trackerKey] = nil
    end
    
    -- Restore visibility
    local container, viewer
    if trackerKey == "custom" then
        container = _G["TweaksUI_CustomTrackerFrame"]
    else
        container = _G["TweaksUI_CDContainer_" .. trackerKey]
        viewer = GetViewer(trackerKey)
    end
    
    if container then
        container:SetAlpha(1)
        container:EnableMouse(true)
    end
    if viewer then
        viewer:SetAlpha(1)
        viewer:EnableMouse(true)
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function CooldownHighlights:EnableHighlight(trackerKey, slotIndex, enabled)
    SetHighlightEnabled(trackerKey, slotIndex, enabled)
    
    if enabled then
        -- Set default show states if not already set
        -- By default: show when ready (active), hide when on cooldown (inactive)
        local db = GetDB(trackerKey)
        if db then
            if db.active.show[slotIndex] == nil then
                db.active.show[slotIndex] = true
            end
            if db.inactive.show[slotIndex] == nil then
                db.inactive.show[slotIndex] = false
            end
        end
        
        -- Only create frames outside combat to avoid taint
        if not highlightFrames[trackerKey][slotIndex] and not InCombatLockdown() then
            CreateHighlightFrame(trackerKey, slotIndex)
        end
        if highlightFrames[trackerKey][slotIndex] then
            RegisterWithLayout(trackerKey, slotIndex)
        end
        
        -- Start ticker if needed
        local hasEnabled = false
        for _, e in pairs(db.enabled) do
            if e then hasEnabled = true break end
        end
        if hasEnabled then
            StartUpdateTicker(trackerKey)
        end
    else
        if highlightFrames[trackerKey][slotIndex] then
            highlightFrames[trackerKey][slotIndex]:Hide()
        end
        UnregisterFromLayout(trackerKey, slotIndex)
        
        -- Stop ticker if no highlights enabled
        local db = GetDB(trackerKey)
        local hasEnabled = false
        for _, e in pairs(db.enabled) do
            if e then hasEnabled = true break end
        end
        if not hasEnabled then
            StopUpdateTicker(trackerKey)
        end
    end
    
    UpdateHighlightFrame(trackerKey, slotIndex)
end

function CooldownHighlights:SetShowState(trackerKey, slotIndex, state, show)
    SetShowState(trackerKey, slotIndex, state, show)
end

function CooldownHighlights:GetShowState(trackerKey, slotIndex, state)
    return GetShowState(trackerKey, slotIndex, state)
end

function CooldownHighlights:SetSize(trackerKey, slotIndex, state, size)
    SetHighlightSize(trackerKey, slotIndex, state, size)
end

function CooldownHighlights:GetSize(trackerKey, slotIndex, state)
    return GetHighlightSize(trackerKey, slotIndex, state)
end

function CooldownHighlights:SetOpacity(trackerKey, slotIndex, state, opacity)
    SetHighlightOpacity(trackerKey, slotIndex, state, opacity)
end

function CooldownHighlights:GetOpacity(trackerKey, slotIndex, state)
    return GetHighlightOpacity(trackerKey, slotIndex, state)
end

function CooldownHighlights:SetSaturation(trackerKey, slotIndex, state, saturated)
    SetHighlightSaturation(trackerKey, slotIndex, state, saturated)
end

function CooldownHighlights:GetSaturation(trackerKey, slotIndex, state)
    return GetHighlightSaturation(trackerKey, slotIndex, state)
end

function CooldownHighlights:SetAspectRatio(trackerKey, slotIndex, state, ratio)
    SetHighlightAspectRatio(trackerKey, slotIndex, state, ratio)
end

function CooldownHighlights:GetAspectRatio(trackerKey, slotIndex, state)
    return GetHighlightAspectRatio(trackerKey, slotIndex, state)
end

function CooldownHighlights:SetCustomAspectRatio(trackerKey, slotIndex, state, width, height)
    local db = GetDB(trackerKey)
    if db then
        db[state].customAspectW[slotIndex] = width
        db[state].customAspectH[slotIndex] = height
    end
    SetHighlightAspectRatio(trackerKey, slotIndex, state, "custom")
end

function CooldownHighlights:GetCustomAspectRatio(trackerKey, slotIndex, state)
    local db = GetDB(trackerKey)
    return db and db[state].customAspectW[slotIndex] or 1, db and db[state].customAspectH[slotIndex] or 1
end

function CooldownHighlights:IsTrackerHidden(trackerKey)
    return IsTrackerHidden(trackerKey)
end

function CooldownHighlights:SetTrackerHidden(trackerKey, hidden)
    SetTrackerHidden(trackerKey, hidden)
    self:ApplyTrackerVisibility(trackerKey)
end

function CooldownHighlights:ApplyTrackerVisibility(trackerKey)
    -- Determine the correct frames
    local container, viewer
    if trackerKey == "custom" then
        container = _G["TweaksUI_CustomTrackerFrame"]
    else
        container = _G["TweaksUI_CDContainer_" .. trackerKey]
        viewer = GetViewer(trackerKey)
    end
    
    if IsTrackerHidden(trackerKey) then
        -- Use alpha 0 instead of Hide() so frames stay functional
        -- This allows per-icon highlights to still read icon data
        if container then
            container:SetAlpha(0)
            container:EnableMouse(false)
        end
        if viewer then
            viewer:SetAlpha(0)
            viewer:EnableMouse(false)
        end
        -- Start enforcement ticker
        if trackerKey ~= "custom" then
            StartHideEnforcement(trackerKey)
        end
    else
        -- Stop enforcement and restore visibility
        if trackerKey ~= "custom" then
            StopHideEnforcement(trackerKey)
        end
        if container then
            container:SetAlpha(1)
            container:EnableMouse(true)
        end
        if viewer then
            viewer:SetAlpha(1)
            viewer:EnableMouse(true)
        end
    end
end

function CooldownHighlights:GetSlotCount(trackerKey)
    return GetSlotCount(trackerKey)
end

function CooldownHighlights:GetSlotInfo(trackerKey, slotIndex)
    return GetSlotInfo(trackerKey, slotIndex)
end

function CooldownHighlights:IsEnabled(trackerKey, slotIndex)
    return IsHighlightEnabled(trackerKey, slotIndex)
end

function CooldownHighlights:GetTrackerTypes()
    return TRACKER_TYPES
end

-- Custom label API
function CooldownHighlights:SetLabelEnabled(trackerKey, slotIndex, enabled)
    SetLabelEnabled(trackerKey, slotIndex, enabled)
    UpdateHighlightFrame(trackerKey, slotIndex)
end

function CooldownHighlights:GetLabelEnabled(trackerKey, slotIndex)
    return GetLabelEnabled(trackerKey, slotIndex)
end

function CooldownHighlights:SetLabelText(trackerKey, slotIndex, text)
    SetLabelText(trackerKey, slotIndex, text)
    UpdateHighlightFrame(trackerKey, slotIndex)
end

function CooldownHighlights:GetLabelText(trackerKey, slotIndex)
    return GetLabelText(trackerKey, slotIndex)
end

function CooldownHighlights:SetLabelFontSize(trackerKey, slotIndex, size)
    SetLabelFontSize(trackerKey, slotIndex, size)
    UpdateHighlightFrame(trackerKey, slotIndex)
end

function CooldownHighlights:GetLabelFontSize(trackerKey, slotIndex)
    return GetLabelFontSize(trackerKey, slotIndex)
end

function CooldownHighlights:SetLabelColor(trackerKey, slotIndex, color)
    SetLabelColor(trackerKey, slotIndex, color)
    UpdateHighlightFrame(trackerKey, slotIndex)
end

function CooldownHighlights:GetLabelColor(trackerKey, slotIndex)
    return GetLabelColor(trackerKey, slotIndex)
end

function CooldownHighlights:SetLabelOffsetX(trackerKey, slotIndex, offset)
    SetLabelOffsetX(trackerKey, slotIndex, offset)
    UpdateHighlightFrame(trackerKey, slotIndex)
end

function CooldownHighlights:GetLabelOffsetX(trackerKey, slotIndex)
    return GetLabelOffsetX(trackerKey, slotIndex)
end

function CooldownHighlights:SetLabelOffsetY(trackerKey, slotIndex, offset)
    SetLabelOffsetY(trackerKey, slotIndex, offset)
    UpdateHighlightFrame(trackerKey, slotIndex)
end

function CooldownHighlights:GetLabelOffsetY(trackerKey, slotIndex)
    return GetLabelOffsetY(trackerKey, slotIndex)
end

-- Per-icon hidden API (hides icon completely from tracker)
function CooldownHighlights:IsIconHidden(trackerKey, slotIndex)
    return IsIconHidden(trackerKey, slotIndex)
end

function CooldownHighlights:SetIconHidden(trackerKey, slotIndex, hidden)
    SetIconHidden(trackerKey, slotIndex, hidden)
    UpdateHighlightFrame(trackerKey, slotIndex)
    -- Refresh the tracker layout to apply alpha=0 on hidden icons
    if TweaksUI.Cooldowns and TweaksUI.Cooldowns.RefreshTrackerLayout then
        TweaksUI.Cooldowns.RefreshTrackerLayout(trackerKey)
    end
end

-- Per-icon cooldown text API
function CooldownHighlights:GetCooldownTextScale(trackerKey, slotIndex)
    return GetCooldownTextScale(trackerKey, slotIndex)
end

function CooldownHighlights:SetCooldownTextScale(trackerKey, slotIndex, scale)
    SetCooldownTextScale(trackerKey, slotIndex, scale)
    UpdateHighlightFrame(trackerKey, slotIndex)
end

function CooldownHighlights:GetCooldownTextColor(trackerKey, slotIndex)
    return GetCooldownTextColor(trackerKey, slotIndex)
end

function CooldownHighlights:SetCooldownTextColor(trackerKey, slotIndex, color)
    SetCooldownTextColor(trackerKey, slotIndex, color)
    UpdateHighlightFrame(trackerKey, slotIndex)
end

function CooldownHighlights:GetCooldownTextOffsetX(trackerKey, slotIndex)
    return GetCooldownTextOffsetX(trackerKey, slotIndex)
end

function CooldownHighlights:SetCooldownTextOffsetX(trackerKey, slotIndex, offset)
    SetCooldownTextOffsetX(trackerKey, slotIndex, offset)
    UpdateHighlightFrame(trackerKey, slotIndex)
end

function CooldownHighlights:GetCooldownTextOffsetY(trackerKey, slotIndex)
    return GetCooldownTextOffsetY(trackerKey, slotIndex)
end

function CooldownHighlights:SetCooldownTextOffsetY(trackerKey, slotIndex, offset)
    SetCooldownTextOffsetY(trackerKey, slotIndex, offset)
    UpdateHighlightFrame(trackerKey, slotIndex)
end

-- Per-icon count text API
function CooldownHighlights:GetCountTextScale(trackerKey, slotIndex)
    return GetCountTextScale(trackerKey, slotIndex)
end

function CooldownHighlights:SetCountTextScale(trackerKey, slotIndex, scale)
    SetCountTextScale(trackerKey, slotIndex, scale)
    UpdateHighlightFrame(trackerKey, slotIndex)
end

function CooldownHighlights:GetCountTextColor(trackerKey, slotIndex)
    return GetCountTextColor(trackerKey, slotIndex)
end

function CooldownHighlights:SetCountTextColor(trackerKey, slotIndex, color)
    SetCountTextColor(trackerKey, slotIndex, color)
    UpdateHighlightFrame(trackerKey, slotIndex)
end

function CooldownHighlights:GetCountTextOffsetX(trackerKey, slotIndex)
    return GetCountTextOffsetX(trackerKey, slotIndex)
end

function CooldownHighlights:SetCountTextOffsetX(trackerKey, slotIndex, offset)
    SetCountTextOffsetX(trackerKey, slotIndex, offset)
    UpdateHighlightFrame(trackerKey, slotIndex)
end

function CooldownHighlights:GetCountTextOffsetY(trackerKey, slotIndex)
    return GetCountTextOffsetY(trackerKey, slotIndex)
end

function CooldownHighlights:SetCountTextOffsetY(trackerKey, slotIndex, offset)
    SetCountTextOffsetY(trackerKey, slotIndex, offset)
    UpdateHighlightFrame(trackerKey, slotIndex)
end

function CooldownHighlights:ToggleDebug()
    debugMode = not debugMode
    print("|cff00ff00TweaksUI CooldownHighlights:|r Debug mode", debugMode and "ENABLED" or "DISABLED")
end

function CooldownHighlights:DumpCooldownInfo(trackerKey, slotIndex)
    -- Use Cooldowns.GetOrderedIcons if available (same order as layout/list)
    local icons
    local Cooldowns = TweaksUI.ModuleManager and TweaksUI.ModuleManager:GetModule(TweaksUI.MODULE_IDS.COOLDOWNS)
    if Cooldowns and Cooldowns.GetOrderedIcons then
        local viewer = GetViewer(trackerKey)
        if viewer then
            icons = Cooldowns.GetOrderedIcons(viewer, trackerKey)
        else
            icons = {}
        end
    else
        icons = CollectIcons(trackerKey)
    end
    local icon = icons[slotIndex or 1]
    
    if not icon then
        print("|cffff0000[CooldownHighlights]|r No icon found at slot", slotIndex or 1)
        return
    end
    
    print("|cff00ff00[CooldownHighlights]|r Dumping info for", trackerKey, "slot", slotIndex or 1)
    print("  Icon:", icon:GetName() or "unnamed")
    
    -- Check spellID
    local spellID = icon.spellID or icon.SpellID or icon.spellId
    if not spellID and icon.GetSpellID then
        pcall(function() spellID = icon:GetSpellID() end)
    end
    print("  SpellID:", spellID or "(not found)")
    
    -- Try C_Spell.GetSpellDisplayCount if we have spellID
    if spellID and C_Spell and C_Spell.GetSpellDisplayCount then
        local success, result = pcall(function()
            return C_Spell.GetSpellDisplayCount(spellID)
        end)
        print("  C_Spell.GetSpellDisplayCount:", success and (result or "(nil)") or ("ERROR: " .. tostring(result)))
    end
    
    -- Check C_Spell cooldown APIs
    print("  C_Spell cooldown APIs:")
    print("    C_Spell.GetSpellCooldown:", (C_Spell and C_Spell.GetSpellCooldown) and "YES" or "no")
    print("    C_Spell.GetSpellCooldownDuration:", (C_Spell and C_Spell.GetSpellCooldownDuration) and "YES" or "no")
    
    -- Try C_Spell.GetSpellCooldown if we have spellID
    if spellID and C_Spell and C_Spell.GetSpellCooldown then
        local success, result = pcall(function()
            return C_Spell.GetSpellCooldown(spellID)
        end)
        if success and result then
            print("    GetSpellCooldown result:")
            print("      startTime:", result.startTime)
            print("      duration:", result.duration)
            print("      isEnabled:", result.isEnabled)
            print("      modRate:", result.modRate)
        else
            print("    GetSpellCooldown:", success and "(nil)" or ("ERROR: " .. tostring(result)))
        end
    end
    
    -- Try C_Spell.GetSpellCooldownDuration if it exists
    if spellID and C_Spell and C_Spell.GetSpellCooldownDuration then
        local success, result = pcall(function()
            return C_Spell.GetSpellCooldownDuration(spellID)
        end)
        print("    GetSpellCooldownDuration:", success and (result and "Duration Object" or "(nil)") or ("ERROR: " .. tostring(result)))
    end
    
    -- Try C_Spell.GetSpellCharges if we have spellID
    if spellID and C_Spell and C_Spell.GetSpellCharges then
        local success, result = pcall(function()
            return C_Spell.GetSpellCharges(spellID)
        end)
        if success and result then
            print("  C_Spell.GetSpellCharges: currentCharges=", result.currentCharges, "maxCharges=", result.maxCharges)
        else
            print("  C_Spell.GetSpellCharges:", success and "(nil)" or ("ERROR: " .. tostring(result)))
        end
    end
    
    -- Try GetSpellCharges global function
    if spellID and GetSpellCharges then
        local success, current, max = pcall(function()
            return GetSpellCharges(spellID)
        end)
        if success then
            print("  GetSpellCharges:", current or "(nil)", "/", max or "(nil)")
        end
    end
    
    -- Check direct fields
    local fields = {}
    if icon.Count then table.insert(fields, "Count") end
    if icon.count then table.insert(fields, "count") end
    if icon.Icon then table.insert(fields, "Icon") end
    if icon.icon then table.insert(fields, "icon") end
    if icon.Cooldown then table.insert(fields, "Cooldown") end
    if icon.cooldown then table.insert(fields, "cooldown") end
    if icon.spellID then table.insert(fields, "spellID") end
    if icon.SpellID then table.insert(fields, "SpellID") end
    if icon.charges then table.insert(fields, "charges") end
    if icon.Charges then table.insert(fields, "Charges") end
    print("  Direct fields:", #fields > 0 and table.concat(fields, ", ") or "(none)")
    
    -- Check for numeric charges value
    if type(icon.charges) == "number" then
        print("  icon.charges (number):", icon.charges)
    end
    if type(icon.Charges) == "number" then
        print("  icon.Charges (number):", icon.Charges)
    end
    if type(icon.currentCharges) == "number" then
        print("  icon.currentCharges:", icon.currentCharges)
    end
    if type(icon.maxCharges) == "number" then
        print("  icon.maxCharges:", icon.maxCharges)
    end
    
    -- Check direct Count field
    local directCount = icon.Count or icon.count
    if directCount then
        print("  icon.Count text:", directCount:GetText() or "(nil)", "visible:", directCount:IsShown())
    end
    
    -- Check cooldown frame
    local cooldown = icon.Cooldown or icon.cooldown
    if cooldown then
        print("  Cooldown frame:", cooldown:GetName() or "unnamed")
        
        -- Check for Midnight Duration Object API
        print("  Cooldown APIs available:")
        print("    GetCooldownDuration:", cooldown.GetCooldownDuration and "YES" or "no")
        print("    GetCooldownTimes:", cooldown.GetCooldownTimes and "YES" or "no")
        print("    SetCooldownFromDurationObject:", cooldown.SetCooldownFromDurationObject and "YES" or "no")
        
        -- Try GetCooldownDuration if available
        if cooldown.GetCooldownDuration then
            local success, result = pcall(function()
                return cooldown:GetCooldownDuration()
            end)
            print("    GetCooldownDuration result:", success and (result and "Duration Object" or "(nil)") or ("ERROR: " .. tostring(result)))
        end
        
        -- Try GetCooldownTimes if available
        if cooldown.GetCooldownTimes then
            local success, start, duration = pcall(function()
                return cooldown:GetCooldownTimes()
            end)
            if success then
                print("    GetCooldownTimes: start=", start, "duration=", duration)
            else
                print("    GetCooldownTimes: ERROR:", start)
            end
        end
        
        -- Check cooldown's count fields
        local cdCount = cooldown.Count or cooldown.count or cooldown.Charges or cooldown.charges
        if cdCount then
            print("  cooldown.Count text:", cdCount:GetText() or "(nil)", "visible:", cdCount:IsShown())
        end
        
        -- Check cooldown children
        if cooldown.GetChildren then
            print("  Cooldown children:", cooldown:GetNumChildren())
            for i = 1, cooldown:GetNumChildren() do
                local child = select(i, cooldown:GetChildren())
                local childName = child:GetName() or child:GetObjectType()
                print("    Child:", childName)
                if child.GetRegions then
                    for j = 1, child:GetNumRegions() do
                        local region = select(j, child:GetRegions())
                        if region:GetObjectType() == "FontString" then
                            print("      FontString:", region:GetName() or "unnamed", "text:", region:GetText() or "(nil)")
                        end
                    end
                end
            end
        end
    end
    
    -- Check icon's regions
    print("  Icon regions:")
    if icon.GetRegions then
        for i = 1, icon:GetNumRegions() do
            local region = select(i, icon:GetRegions())
            if region:GetObjectType() == "FontString" then
                print("    FontString:", region:GetName() or "unnamed", "text:", region:GetText() or "(nil)", "visible:", region:IsShown())
            end
        end
    end
    
    -- Check icon's children
    print("  Icon children:", icon:GetNumChildren())
    if icon.GetChildren then
        for i = 1, icon:GetNumChildren() do
            local child = select(i, icon:GetChildren())
            local childName = child:GetName() or child:GetObjectType()
            print("    Child:", childName)
            
            -- Check child's count field
            local childCount = child.Count or child.count
            if childCount then
                print("      Count field:", childCount:GetText() or "(nil)")
            end
            
            -- Check child's regions
            if child.GetRegions then
                for j = 1, child:GetNumRegions() do
                    local region = select(j, child:GetRegions())
                    if region:GetObjectType() == "FontString" then
                        print("      FontString:", region:GetName() or "unnamed", "text:", region:GetText() or "(nil)")
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function CooldownHighlights:Initialize(trackerKey)
    if isInitialized[trackerKey] then return end
    isInitialized[trackerKey] = true
    
    dprint("Initializing CooldownHighlights:", trackerKey)
    
    -- Create frames for any enabled highlights (only outside combat)
    local db = GetDB(trackerKey)
    if not db then return end
    
    if not InCombatLockdown() then
        for slotIndex, enabled in pairs(db.enabled) do
            if enabled then
                CreateHighlightFrame(trackerKey, slotIndex)
            end
        end
    end
    
    -- Start update ticker if we have any enabled
    local hasEnabled = false
    for _, enabled in pairs(db.enabled) do
        if enabled then hasEnabled = true break end
    end
    
    if hasEnabled then
        StartUpdateTicker(trackerKey)
    end
    
    -- Apply tracker visibility
    self:ApplyTrackerVisibility(trackerKey)
    
    -- Register callbacks
    local Layout = TweaksUI.Layout
    if Layout then
        Layout:RegisterCallback("OnLayoutModeEnter", function()
            RegisterAllWithLayout(trackerKey)
            UpdateAllHighlights(trackerKey)
        end)
        
        Layout:RegisterCallback("OnLayoutModeExit", function()
            UpdateAllHighlights(trackerKey)
        end)
    end
end

function CooldownHighlights:InitializeAll()
    for trackerKey, _ in pairs(TRACKER_TYPES) do
        self:Initialize(trackerKey)
    end
end

-- Apply hooks early on PLAYER_ENTERING_WORLD (before full initialization)
local earlyHookFrame = CreateFrame("Frame")
earlyHookFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
earlyHookFrame:SetScript("OnEvent", function(self, event)
    -- Apply hooks immediately for any trackers that should be hidden
    for trackerKey, trackerType in pairs(TRACKER_TYPES) do
        local dbKey = trackerType.dbKey
        if TweaksUI_CharDB and TweaksUI_CharDB[dbKey] then
            local db = TweaksUI_CharDB[dbKey]
            if db.hideTracker then
                dprint("Early hook application for:", trackerKey)
                StartHideEnforcement(trackerKey)
            end
        end
    end
end)

-- Auto-initialize after a delay (for full functionality)
C_Timer.After(2, function()
    CooldownHighlights:InitializeAll()
end)

-- ============================================================================
-- DEBUG SLASH COMMAND FOR OVERLAY INSPECTION
-- ============================================================================

SLASH_TUICDOVERLAY1 = "/tuicdoverlay"
SlashCmdList["TUICDOVERLAY"] = function(msg)
    print("|cff00ff00=== TweaksUI Cooldown Overlay Debug ===|r")
    
    -- Check EssentialCooldownViewer icons
    local viewer = _G["EssentialCooldownViewer"]
    if not viewer then
        print("|cffff0000EssentialCooldownViewer not found|r")
        return
    end
    
    print("Scanning EssentialCooldownViewer children...")
    
    for i = 1, viewer:GetNumChildren() do
        local icon = select(i, viewer:GetChildren())
        if icon and (icon.Icon or icon.icon) then
            local iconTex = icon.Icon or icon.icon
            local iconName = icon:GetName() or ("Icon" .. i)
            
            print("|cffffcc00Icon:|r", iconName)
            
            -- Check known overlay frames
            local overlayNames = {"OutOfRange", "NotUsable", "InsufficientResources", "RangeOverlay", "NotUsableOverlay", "Unusable", "NoResource", "InsufficientMana"}
            for _, name in ipairs(overlayNames) do
                if icon[name] then
                    print("  |cff00ff00Found:|r", name, "shown:", icon[name]:IsShown())
                end
            end
            
            -- List ALL children frames
            print("  Children frames:")
            if icon.GetChildren then
                for j = 1, icon:GetNumChildren() do
                    local child = select(j, icon:GetChildren())
                    local childName = child:GetName() or ""
                    local childType = child:GetObjectType()
                    local shown = child:IsShown()
                    local alpha = child:GetAlpha()
                    
                    -- Color code: green if shown, grey if hidden
                    local color = shown and "|cff00ff00" or "|cff888888"
                    print("    ", color, childName ~= "" and childName or ("unnamed " .. childType), "|r", 
                          "shown:", shown, "alpha:", string.format("%.2f", alpha))
                    
                    -- Check child's Count reference
                    if child.Count and child.Count.GetText then
                        local text = child.Count:GetText() or ""
                        print("      |cff00ccffChild.Count text:|r", text, "shown:", child.Count:IsShown())
                    end
                    
                    -- Check child's regions for FontStrings
                    if child.GetRegions then
                        for k = 1, child:GetNumRegions() do
                            local region = select(k, child:GetRegions())
                            if region and region:GetObjectType() == "FontString" then
                                local text = region:GetText() or ""
                                local rShown = region:IsShown()
                                print("      |cffff00ffFontString:|r text='" .. text .. "' shown:", rShown)
                            end
                        end
                    end
                end
            end
            
            -- List ALL regions (textures and fontstrings)
            print("  Regions/Textures:")
            if icon.GetRegions then
                for j = 1, icon:GetNumRegions() do
                    local region = select(j, icon:GetRegions())
                    local regionName = region:GetName() or ""
                    local regionType = region:GetObjectType()
                    local shown = region:IsShown()
                    local alpha = region:GetAlpha()
                    
                    -- Get extra info based on type
                    local extraInfo = ""
                    if regionType == "Texture" and region.GetVertexColor then
                        local r, g, b, a = region:GetVertexColor()
                        if r and g and b then
                            extraInfo = string.format(" vertexColor:(%.2f,%.2f,%.2f,%.2f)", r, g, b, a or 1)
                        end
                    elseif regionType == "FontString" and region.GetText then
                        local text = region:GetText() or ""
                        extraInfo = " text='" .. text .. "'"
                    end
                    
                    local color = shown and "|cff00ff00" or "|cff888888"
                    print("    ", color, regionName ~= "" and regionName or ("unnamed " .. regionType), "|r",
                          "shown:", shown, "alpha:", string.format("%.2f", alpha), extraInfo)
                end
            end
            
            print("")  -- Blank line between icons
        end
    end
    
    print("|cff00ff00=== End Debug ===|r")
end

-- Debug command specifically for charge text
SLASH_TUICDCHARGES1 = "/tuicdcharges"
SlashCmdList["TUICDCHARGES"] = function(msg)
    print("|cff00ff00=== TweaksUI Charge Text Debug ===|r")
    
    local viewer = _G["EssentialCooldownViewer"]
    if not viewer then
        print("|cffff0000EssentialCooldownViewer not found|r")
        return
    end
    
    for i = 1, viewer:GetNumChildren() do
        local icon = select(i, viewer:GetChildren())
        if icon and (icon.Icon or icon.icon or icon.Cooldown or icon.cooldown) then
            local iconName = icon:GetName() or ("Icon" .. i)
            print("|cffffcc00" .. iconName .. "|r")
            
            -- Check all common spellID properties
            local spellID = icon.spellID or icon.SpellID or icon.spellId or icon.cooldownSpellID or icon.spell
            print("  spellID props:", icon.spellID, icon.SpellID, icon.spellId, icon.cooldownSpellID, icon.spell)
            
            -- Try GetSpellID method
            if icon.GetSpellID then
                local success, result = pcall(function() return icon:GetSpellID() end)
                print("  GetSpellID():", success and result or ("ERROR: " .. tostring(result)))
            end
            
            -- Check data table
            if icon.data then
                print("  icon.data:", type(icon.data))
                if type(icon.data) == "table" then
                    for k, v in pairs(icon.data) do
                        print("    data." .. tostring(k) .. ":", tostring(v))
                    end
                end
            end
            
            -- Check for Count text directly
            if icon.Count then
                print("  icon.Count:", icon.Count:GetText() or "(empty)", "shown:", icon.Count:IsShown())
            end
            if icon.count then
                print("  icon.count:", icon.count:GetText() or "(empty)", "shown:", icon.count:IsShown())
            end
            
            -- Check cooldown frame
            local cd = icon.Cooldown or icon.cooldown
            if cd then
                if cd.Count then
                    print("  cooldown.Count:", cd.Count:GetText() or "(empty)", "shown:", cd.Count:IsShown())
                end
                if cd.count then
                    print("  cooldown.count:", cd.count:GetText() or "(empty)", "shown:", cd.count:IsShown())
                end
            end
            
            -- Deep search for any FontString with numbers
            local function searchFS(parent, path, depth)
                if depth > 4 then return end
                if parent.GetRegions then
                    for j = 1, parent:GetNumRegions() do
                        local r = select(j, parent:GetRegions())
                        if r and r:GetObjectType() == "FontString" then
                            -- Use pcall to handle secret values during combat
                            local success, text = pcall(function() return r:GetText() end)
                            if success then
                                local hasText = pcall(function() return text and text ~= "" end)
                                if hasText and text then
                                    print("  |cff00ff00FOUND FontString|r at", path, "text:", tostring(text), "shown:", r:IsShown())
                                end
                            else
                                print("  |cffff8800SECRET FontString|r at", path, "(value hidden during combat)")
                            end
                        end
                    end
                end
                if parent.GetChildren then
                    for j = 1, parent:GetNumChildren() do
                        local c = select(j, parent:GetChildren())
                        if c then
                            searchFS(c, path .. ".child" .. j, depth + 1)
                        end
                    end
                end
            end
            searchFS(icon, "icon", 0)
            
            print("")
        end
    end
    
    print("|cff00ff00=== End Charge Debug ===|r")
end
