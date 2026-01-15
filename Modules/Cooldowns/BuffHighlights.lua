-- ============================================================================
-- TweaksUI BuffHighlights.lua
-- Creates positionable highlight clones for tracked buffs
-- Detects active/inactive state via auraInstanceID (no secret value math)
-- ============================================================================

local addonName, TweaksUI = ...
TweaksUI.BuffHighlights = TweaksUI.BuffHighlights or {}
local BuffHighlights = TweaksUI.BuffHighlights

-- ============================================================================
-- MIDNIGHT API WRAPPERS (v2.0.0)
-- ============================================================================

local AuraAPI = TweaksUI.AuraAPI
local DurationAPI = TweaksUI.DurationAPI

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local UPDATE_INTERVAL = 0.2  -- 5 Hz update rate (balance of responsiveness and performance)
local DEFAULT_SIZE = 48
local FRAME_PREFIX = "TweaksUI_BuffHighlight_"

-- ============================================================================
-- STATE
-- ============================================================================

local highlightFrames = {}  -- [slotIndex] = frame
local updateTicker = nil
local isInitialized = false

-- Debug mode
local debugMode = false
local function dprint(...)
    if debugMode then
        print("|cff00ccff[BuffHighlights]|r", ...)
    end
end

-- ============================================================================
-- DATABASE
-- ============================================================================

local function GetDB()
    if not TweaksUI_CharDB then TweaksUI_CharDB = {} end
    if not TweaksUI_CharDB.buffHighlights then
        TweaksUI_CharDB.buffHighlights = {
            hideTracker = false,  -- Hide the main buff tracker
            enabled = {},  -- [slotIndex] = true/false
            positions = {}, -- [slotIndex] = {point, relPoint, x, y}
            -- Active state settings (when buff is present)
            active = {
                size = {},          -- [slotIndex] = size
                opacity = {},       -- [slotIndex] = 0.0-1.0
                saturation = {},    -- [slotIndex] = true/false
                aspectRatio = {},   -- [slotIndex] = "1:1", "custom", etc.
                customAspectW = {}, -- [slotIndex] = width
                customAspectH = {}, -- [slotIndex] = height
                show = {},          -- [slotIndex] = true/false (show when active)
            },
            -- Inactive state settings (when buff is missing)
            inactive = {
                size = {},
                opacity = {},
                saturation = {},
                aspectRatio = {},
                customAspectW = {},
                customAspectH = {},
                show = {},          -- [slotIndex] = true/false (show when inactive)
            },
        }
    end
    -- Ensure all fields exist (for existing databases)
    local db = TweaksUI_CharDB.buffHighlights
    if not db.enabled then db.enabled = {} end
    if not db.positions then db.positions = {} end
    
    -- Migrate old format to new format
    if db.triggerOn or db.sizes then
        -- Old format detected, migrate
        if not db.active then db.active = {} end
        if not db.inactive then db.inactive = {} end
        
        for _, state in ipairs({"active", "inactive"}) do
            if not db[state].size then db[state].size = {} end
            if not db[state].opacity then db[state].opacity = {} end
            if not db[state].saturation then db[state].saturation = {} end
            if not db[state].aspectRatio then db[state].aspectRatio = {} end
            if not db[state].customAspectW then db[state].customAspectW = {} end
            if not db[state].customAspectH then db[state].customAspectH = {} end
            if not db[state].show then db[state].show = {} end
        end
        
        -- Migrate old settings to active state
        if db.sizes then
            for k, v in pairs(db.sizes) do
                db.active.size[k] = v
                db.inactive.size[k] = v
            end
            db.sizes = nil
        end
        if db.opacity then
            for k, v in pairs(db.opacity) do
                db.active.opacity[k] = v
                db.inactive.opacity[k] = 0.3  -- Default inactive to lower opacity
            end
            db.opacity = nil
        end
        if db.saturation then
            for k, v in pairs(db.saturation) do
                db.active.saturation[k] = v
                db.inactive.saturation[k] = false  -- Default inactive to desaturated
            end
            db.saturation = nil
        end
        if db.aspectRatio then
            for k, v in pairs(db.aspectRatio) do
                db.active.aspectRatio[k] = v
                db.inactive.aspectRatio[k] = v
            end
            db.aspectRatio = nil
        end
        if db.triggerOn then
            for k, v in pairs(db.triggerOn) do
                if v == "active" then
                    db.active.show[k] = true
                    db.inactive.show[k] = false
                else
                    db.active.show[k] = false
                    db.inactive.show[k] = true
                end
            end
            db.triggerOn = nil
        end
    end
    
    -- Ensure nested tables exist
    if not db.active then db.active = {} end
    if not db.inactive then db.inactive = {} end
    for _, state in ipairs({"active", "inactive"}) do
        if not db[state].size then db[state].size = {} end
        if not db[state].opacity then db[state].opacity = {} end
        if not db[state].saturation then db[state].saturation = {} end
        if not db[state].aspectRatio then db[state].aspectRatio = {} end
        if not db[state].customAspectW then db[state].customAspectW = {} end
        if not db[state].customAspectH then db[state].customAspectH = {} end
        if not db[state].show then db[state].show = {} end
    end
    
    -- Custom label fields (state-independent)
    if not db.labelEnabled then db.labelEnabled = {} end
    if not db.labelText then db.labelText = {} end
    if not db.labelFontSize then db.labelFontSize = {} end
    if not db.labelColor then db.labelColor = {} end
    if not db.labelOffsetX then db.labelOffsetX = {} end
    if not db.labelOffsetY then db.labelOffsetY = {} end
    
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

local function IsHighlightEnabled(slotIndex)
    local db = GetDB()
    return db.enabled[slotIndex] == true
end

local function SetHighlightEnabled(slotIndex, enabled)
    local db = GetDB()
    db.enabled[slotIndex] = enabled
end

-- State-aware getters/setters
local function GetStateSetting(slotIndex, state, key)
    local db = GetDB()
    return db[state] and db[state][key] and db[state][key][slotIndex]
end

local function SetStateSetting(slotIndex, state, key, value)
    local db = GetDB()
    if db[state] and db[state][key] then
        db[state][key][slotIndex] = value
    end
end

local function GetHighlightSize(slotIndex, state)
    return GetStateSetting(slotIndex, state or "active", "size") or DEFAULT_SIZE
end

local function SetHighlightSize(slotIndex, state, size)
    SetStateSetting(slotIndex, state, "size", size)
end

local function GetHighlightOpacity(slotIndex, state)
    local default = (state == "inactive") and 0.4 or 1.0
    return GetStateSetting(slotIndex, state or "active", "opacity") or default
end

local function SetHighlightOpacity(slotIndex, state, opacity)
    SetStateSetting(slotIndex, state, "opacity", opacity)
end

local function GetHighlightSaturation(slotIndex, state)
    local default = (state == "inactive") and false or true
    local val = GetStateSetting(slotIndex, state or "active", "saturation")
    if val == nil then return default end
    return val
end

local function SetHighlightSaturation(slotIndex, state, saturated)
    SetStateSetting(slotIndex, state, "saturation", saturated)
end

local function GetHighlightAspectRatio(slotIndex, state)
    return GetStateSetting(slotIndex, state or "active", "aspectRatio") or "1:1"
end

local function SetHighlightAspectRatio(slotIndex, state, ratio)
    SetStateSetting(slotIndex, state, "aspectRatio", ratio)
end

local function GetShowState(slotIndex, state)
    local val = GetStateSetting(slotIndex, state, "show")
    if val == nil then
        -- Default: show active, hide inactive
        return (state == "active")
    end
    return val
end

local function SetShowState(slotIndex, state, show)
    SetStateSetting(slotIndex, state, "show", show)
end

local function GetHighlightPosition(slotIndex)
    local db = GetDB()
    return db.positions[slotIndex]
end

local function SetHighlightPosition(slotIndex, point, relPoint, x, y)
    local db = GetDB()
    db.positions[slotIndex] = {point = point, relPoint = relPoint, x = x, y = y}
end

local function IsTrackerHidden()
    local db = GetDB()
    return db.hideTracker == true
end

local function SetTrackerHidden(hidden)
    local db = GetDB()
    db.hideTracker = hidden
end

-- Custom label helpers (state-independent)
local function GetLabelEnabled(slotIndex)
    local db = GetDB()
    return db.labelEnabled[slotIndex] == true
end

local function SetLabelEnabled(slotIndex, enabled)
    local db = GetDB()
    db.labelEnabled[slotIndex] = enabled
end

local function GetLabelText(slotIndex)
    local db = GetDB()
    return db.labelText[slotIndex] or ""
end

local function SetLabelText(slotIndex, text)
    local db = GetDB()
    db.labelText[slotIndex] = text
end

local function GetLabelFontSize(slotIndex)
    local db = GetDB()
    return db.labelFontSize[slotIndex] or 14
end

local function SetLabelFontSize(slotIndex, size)
    local db = GetDB()
    db.labelFontSize[slotIndex] = size
end

local function GetLabelColor(slotIndex)
    local db = GetDB()
    return db.labelColor[slotIndex] or {1, 1, 1, 1}  -- Default white
end

local function SetLabelColor(slotIndex, color)
    local db = GetDB()
    db.labelColor[slotIndex] = color
end

local function GetLabelOffsetX(slotIndex)
    local db = GetDB()
    return db.labelOffsetX[slotIndex] or 0
end

local function SetLabelOffsetX(slotIndex, offset)
    local db = GetDB()
    db.labelOffsetX[slotIndex] = offset
end

local function GetLabelOffsetY(slotIndex)
    local db = GetDB()
    return db.labelOffsetY[slotIndex] or 0
end

local function SetLabelOffsetY(slotIndex, offset)
    local db = GetDB()
    db.labelOffsetY[slotIndex] = offset
end

-- Per-icon hidden helpers (hides icon completely from tracker)
local function IsIconHidden(slotIndex)
    local db = GetDB()
    return db.hidden[slotIndex] == true
end

local function SetIconHidden(slotIndex, hidden)
    local db = GetDB()
    db.hidden[slotIndex] = hidden
end

-- Per-icon cooldown text helpers (countdown timer on cooldown spiral)
local function GetCooldownTextScale(slotIndex)
    local db = GetDB()
    return db.cooldownTextScale[slotIndex] or 1.0
end

local function SetCooldownTextScale(slotIndex, scale)
    local db = GetDB()
    db.cooldownTextScale[slotIndex] = scale
end

local function GetCooldownTextColor(slotIndex)
    local db = GetDB()
    return db.cooldownTextColor[slotIndex] or {1, 1, 1, 1}  -- Default white
end

local function SetCooldownTextColor(slotIndex, color)
    local db = GetDB()
    db.cooldownTextColor[slotIndex] = color
end

local function GetCooldownTextOffsetX(slotIndex)
    local db = GetDB()
    return db.cooldownTextOffsetX[slotIndex] or 0
end

local function SetCooldownTextOffsetX(slotIndex, offset)
    local db = GetDB()
    db.cooldownTextOffsetX[slotIndex] = offset
end

local function GetCooldownTextOffsetY(slotIndex)
    local db = GetDB()
    return db.cooldownTextOffsetY[slotIndex] or 0
end

local function SetCooldownTextOffsetY(slotIndex, offset)
    local db = GetDB()
    db.cooldownTextOffsetY[slotIndex] = offset
end

-- Per-icon count text helpers (stack/charge numbers)
local function GetCountTextScale(slotIndex)
    local db = GetDB()
    return db.countTextScale[slotIndex] or 1.0
end

local function SetCountTextScale(slotIndex, scale)
    local db = GetDB()
    db.countTextScale[slotIndex] = scale
end

local function GetCountTextColor(slotIndex)
    local db = GetDB()
    return db.countTextColor[slotIndex] or {1, 1, 1, 1}  -- Default white
end

local function SetCountTextColor(slotIndex, color)
    local db = GetDB()
    db.countTextColor[slotIndex] = color
end

local function GetCountTextOffsetX(slotIndex)
    local db = GetDB()
    return db.countTextOffsetX[slotIndex] or 0
end

local function SetCountTextOffsetX(slotIndex, offset)
    local db = GetDB()
    db.countTextOffsetX[slotIndex] = offset
end

local function GetCountTextOffsetY(slotIndex)
    local db = GetDB()
    return db.countTextOffsetY[slotIndex] or 0
end

local function SetCountTextOffsetY(slotIndex, offset)
    local db = GetDB()
    db.countTextOffsetY[slotIndex] = offset
end

-- ============================================================================
-- BUFF SLOT ACCESS
-- ============================================================================

-- Get the buff viewer frame
local function GetBuffViewer()
    return _G["BuffIconCooldownViewer"]
end

-- Collect all icons from the buff viewer (reuses Cooldowns logic)
-- Note: We collect icons even if they're hidden (alpha 0) because we need their data
local function CollectBuffIcons()
    local viewer = GetBuffViewer()
    if not viewer then return {} end
    
    -- Don't check IsShown because we hide the tracker with alpha 0
    -- The icons still exist and have data even when hidden
    
    local icons = {}
    local numChildren = 0
    pcall(function() numChildren = viewer:GetNumChildren() or 0 end)
    
    for i = 1, numChildren do
        local child = select(i, viewer:GetChildren())
        -- Check if this looks like an icon (don't require IsShown)
        if child then
            local hasIcon = child.Icon or child.icon
            local hasCooldown = child.Cooldown or child.cooldown
            if hasIcon or hasCooldown then
                icons[#icons + 1] = child
            elseif child.GetNumChildren then
                -- Check nested children
                local numNested = 0
                pcall(function() numNested = child:GetNumChildren() or 0 end)
                for j = 1, numNested do
                    local nested = select(j, child:GetChildren())
                    if nested then
                        local nestedHasIcon = nested.Icon or nested.icon
                        local nestedHasCooldown = nested.Cooldown or nested.cooldown
                        if nestedHasIcon or nestedHasCooldown then
                            icons[#icons + 1] = nested
                        end
                    end
                end
            end
        end
    end
    
    -- Sort by visual position (top-to-bottom, left-to-right) to match Cooldowns module order
    table.sort(icons, function(a, b)
        local at, bt = 0, 0
        local al, bl = 0, 0
        pcall(function() at = a:GetTop() or 0 end)
        pcall(function() bt = b:GetTop() or 0 end)
        pcall(function() al = a:GetLeft() or 0 end)
        pcall(function() bl = b:GetLeft() or 0 end)
        
        -- Sort top-to-bottom first (higher Y = higher on screen)
        if math.abs(at - bt) > 5 then return at > bt end
        
        -- Then left-to-right for icons in same row
        return al < bl
    end)
    
    return icons
end

-- Get info about a specific buff slot
local function GetBuffSlotInfo(slotIndex)
    local icons = CollectBuffIcons()
    local icon = icons[slotIndex]
    
    if not icon then return nil end
    
    local info = {
        icon = icon,
        isActive = false,
        auraInstanceID = nil,
        texture = nil,
        name = "Buff Slot " .. slotIndex,
    }
    
    -- Get auraInstanceID safely (this is the key to detecting active state)
    pcall(function()
        info.auraInstanceID = icon.auraInstanceID
        info.isActive = (icon.auraInstanceID ~= nil)
    end)
    
    -- Get texture safely
    local textureObj = icon.Icon or icon.icon
    if textureObj then
        pcall(function()
            info.texture = textureObj:GetTexture()
        end)
    end
    
    return info
end

-- Get count of buff slots
local function GetBuffSlotCount()
    return #CollectBuffIcons()
end

-- ============================================================================
-- HIGHLIGHT FRAME CREATION (Clone-based - we create our own frame and copy data)
-- ============================================================================

local function CreateHighlightFrame(slotIndex)
    if highlightFrames[slotIndex] then
        return highlightFrames[slotIndex]
    end
    
    local frameName = FRAME_PREFIX .. slotIndex
    local size = GetHighlightSize(slotIndex)
    
    local frame = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
    frame:SetSize(size, size)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(100)
    
    -- CRITICAL: Make frame movable for Layout mode
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(false)  -- Don't eat mouse clicks - Layout overlay handles that
    
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
    
    -- Cooldown spiral
    frame.cooldown = CreateFrame("Cooldown", frameName .. "_Cooldown", frame, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints(frame.icon)
    frame.cooldown:SetDrawEdge(true)
    frame.cooldown:SetDrawBling(false)
    frame.cooldown:SetDrawSwipe(true)
    frame.cooldown:SetHideCountdownNumbers(false)
    frame.cooldown:SetSwipeColor(0, 0, 0, 0.8)
    
    -- Stack count text (bottom right, larger font)
    frame.count = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    frame.count:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.count:SetJustifyH("RIGHT")
    
    -- Proc glow overlay (using Blizzard's built-in glow style)
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
    
    -- Store slot reference
    frame.slotIndex = slotIndex
    
    -- Apply saved position or default
    local pos = GetHighlightPosition(slotIndex)
    if pos then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        -- Default position - center with offset based on slot
        frame:SetPoint("CENTER", UIParent, "CENTER", -200 + (slotIndex * 60), -100)
    end
    
    -- Initially hidden
    frame:Hide()
    
    highlightFrames[slotIndex] = frame
    dprint("Created highlight frame for slot", slotIndex)
    
    return frame
end

-- ============================================================================
-- HIGHLIGHT FRAME UPDATE
-- ============================================================================

-- Parse aspect ratio string to get width/height multipliers
local function ParseAspectRatio(aspectStr, slotIndex, state)
    if not aspectStr or aspectStr == "1:1" then
        return 1, 1
    end
    
    -- Check for "custom" which uses per-slot custom values
    if aspectStr == "custom" and slotIndex and state then
        local db = GetDB()
        local customW = db[state].customAspectW[slotIndex] or 1
        local customH = db[state].customAspectH[slotIndex] or 1
        return customW, customH
    end
    
    local w, h = aspectStr:match("(%d+):(%d+)")
    if w and h then
        return tonumber(w), tonumber(h)
    end
    return 1, 1
end

-- Apply aspect ratio to frame
local function ApplyAspectRatio(frame, size, aspectStr, slotIndex, state)
    local aspectW, aspectH = ParseAspectRatio(aspectStr, slotIndex, state)
    local width, height = size, size
    
    if aspectW > aspectH then
        -- Wide (e.g., 16:9)
        height = size * aspectH / aspectW
    elseif aspectH > aspectW then
        -- Tall (e.g., 9:16)
        width = size * aspectW / aspectH
    end
    
    frame:SetSize(width, height)
end

local function UpdateHighlightFrame(slotIndex)
    local frame = highlightFrames[slotIndex]
    if not frame then return end
    
    if not IsHighlightEnabled(slotIndex) then
        frame:Hide()
        return
    end
    
    local slotInfo = GetBuffSlotInfo(slotIndex)
    
    -- Check if Layout mode is active
    local isLayoutMode = false
    local layoutContainer = _G["TweaksUI_LayoutContainer"]
    if layoutContainer and layoutContainer:IsShown() then
        isLayoutMode = true
    end
    
    if not slotInfo then
        -- No slot info - show placeholder during layout mode, hide otherwise
        if isLayoutMode then
            local size = GetHighlightSize(slotIndex, "active")
            local aspectRatio = GetHighlightAspectRatio(slotIndex, "active")
            ApplyAspectRatio(frame, size, aspectRatio, slotIndex, "active")
            frame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            frame.icon:SetDesaturated(true)
            frame.count:Hide()
            frame.cooldown:Clear()
            if frame.glowFrame then frame.glowFrame:Hide() end
            frame:SetAlpha(0.5)
            frame:Show()
        else
            frame:Hide()
        end
        return
    end
    
    -- Determine current state based on buff activity
    local currentState = slotInfo.isActive and "active" or "inactive"
    local showThisState = GetShowState(slotIndex, currentState)
    
    -- During layout mode, always show (using active state settings)
    if isLayoutMode then
        local size = GetHighlightSize(slotIndex, "active")
        local aspectRatio = GetHighlightAspectRatio(slotIndex, "active")
        ApplyAspectRatio(frame, size, aspectRatio, slotIndex, "active")
        
        if slotInfo.texture then
            frame.icon:SetTexture(slotInfo.texture)
        else
            frame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        
        -- Show with slight desaturation if current state wouldn't normally show
        if not showThisState then
            frame.icon:SetDesaturated(true)
            frame:SetAlpha(0.4)
        else
            local saturated = GetHighlightSaturation(slotIndex, currentState)
            local opacity = GetHighlightOpacity(slotIndex, currentState)
            frame.icon:SetDesaturated(not saturated)
            frame:SetAlpha(opacity)
        end
        
        frame.count:Hide()
        frame.cooldown:Clear()
        if frame.glowFrame then frame.glowFrame:Hide() end
        frame:Show()
        return
    end
    
    -- Normal mode: only show if this state is enabled
    if not showThisState then
        frame:Hide()
        return
    end
    
    -- Get state-specific settings
    local size = GetHighlightSize(slotIndex, currentState)
    local opacity = GetHighlightOpacity(slotIndex, currentState)
    local saturated = GetHighlightSaturation(slotIndex, currentState)
    local aspectRatio = GetHighlightAspectRatio(slotIndex, currentState)
    
    -- Apply size and aspect ratio
    ApplyAspectRatio(frame, size, aspectRatio, slotIndex, currentState)
    
    -- Update icon texture
    if slotInfo.texture then
        frame.icon:SetTexture(slotInfo.texture)
    else
        frame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    
    -- Apply saturation and opacity
    frame.icon:SetDesaturated(not saturated)
    frame:SetAlpha(opacity)
    
    -- Always try to update count from the source icon's auraInstanceID
    -- No conditionals - just pass through to the API and let it handle everything
    local sourceIcon = slotInfo.icon
    pcall(function()
        local auraID = sourceIcon.auraInstanceID
        local countStr = AuraAPI:GetApplicationDisplayCount("player", auraID, 2)
        frame.count:SetText(countStr)
    end)
    frame.count:Show()  -- Always show - empty string displays nothing
    
    -- Copy cooldown sweep from source icon using Duration Object pass-through
    pcall(function()
        local sourceCooldown = sourceIcon.Cooldown or sourceIcon.cooldown
        if sourceCooldown then
            -- Try Duration Object API first (Midnight native)
            if sourceCooldown.GetCooldownDuration then
                local durationObj = sourceCooldown:GetCooldownDuration()
                if durationObj and frame.cooldown.SetCooldownFromDurationObject then
                    frame.cooldown:SetCooldownFromDurationObject(durationObj, true)
                end
            else
                local start, duration = sourceCooldown:GetCooldownTimes()
                if start and duration then
                    frame.cooldown:SetCooldown(start / 1000, duration / 1000)
                end
            end
        end
    end)
    
    -- Copy glow state from source icon (proc/spell activation glow)
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
    
    -- Custom accessibility label
    if frame.customLabel then
        if GetLabelEnabled(slotIndex) then
            local labelText = GetLabelText(slotIndex)
            local fontSize = GetLabelFontSize(slotIndex)
            local labelColor = GetLabelColor(slotIndex)
            local offsetX = GetLabelOffsetX(slotIndex)
            local offsetY = GetLabelOffsetY(slotIndex)
            
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
    
    -- Apply per-icon text scale, color, and offset settings
    local cooldownTextScale = GetCooldownTextScale(slotIndex)
    local cooldownTextColor = GetCooldownTextColor(slotIndex)
    local cooldownTextOffsetX = GetCooldownTextOffsetX(slotIndex)
    local cooldownTextOffsetY = GetCooldownTextOffsetY(slotIndex)
    local countTextScale = GetCountTextScale(slotIndex)
    local countTextColor = GetCountTextColor(slotIndex)
    local countTextOffsetX = GetCountTextOffsetX(slotIndex)
    local countTextOffsetY = GetCountTextOffsetY(slotIndex)
    
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
    
    frame:Show()
end

local function UpdateAllHighlights()
    local db = GetDB()
    for slotIndex, enabled in pairs(db.enabled) do
        if enabled then
            -- Ensure frame exists
            if not highlightFrames[slotIndex] then
                pcall(CreateHighlightFrame, slotIndex)
            end
            -- Use pcall to prevent combat errors from breaking the ticker
            local success, err = pcall(UpdateHighlightFrame, slotIndex)
            if not success and debugMode then
                dprint("UpdateHighlightFrame error for slot " .. slotIndex .. ": " .. tostring(err))
            end
        end
    end
end

-- ============================================================================
-- LAYOUT INTEGRATION
-- ============================================================================

local layoutWrappers = {}  -- [slotIndex] = wrapper

local function CreateLayoutWrapper(slotIndex)
    local frame = highlightFrames[slotIndex]
    if not frame then return nil end
    
    local wrapperId = "BuffHighlight_" .. slotIndex
    
    local wrapper = {
        id = wrapperId,
        name = "Buff Highlight " .. slotIndex,
        category = "Cooldowns",
        frame = frame,
        hideSizeMatching = true,  -- Don't show "Match Size to Parent" options for Per-Icon frames
        defaultPosition = {
            point = "CENTER",
            x = -200 + (slotIndex * 60),
            y = -100,
        },
        contentFrames = {},
        
        onPositionChanged = function(self, point, relFrame, relPoint, x, y)
            frame:ClearAllPoints()
            frame:SetPoint(point, UIParent, point, x, y)
            SetHighlightPosition(slotIndex, point, point, x, y)
        end,
        
        -- TUIFrame API
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
            -- For buff highlights, size changes should go through aspect ratio
            -- Just apply directly for now
            if frame and width and height then
                frame:SetSize(width, height)
            end
        end,
        
        IsShown = function(self)
            -- Always report as shown during layout mode so overlay appears
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
        
        -- Size locking
        sizeLocked = false,
        SetSizeLocked = function(self, locked)
            self.sizeLocked = locked
        end,
        IsSizeLocked = function(self)
            return self.sizeLocked
        end,
        
        -- ForceSetSize - required by SnapLocking for size matching
        ForceSetSize = function(self, width, height)
            if frame and width and height then
                frame:SetSize(width, height)
            end
        end,
        
        -- GetWidth/GetHeight - required for size calculations
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
    
    frame.tuiFrame = wrapper
    layoutWrappers[slotIndex] = wrapper
    
    -- Register with FlyPaper for snap highlighting
    local FlyPaper = LibStub and LibStub("LibFlyPaper-2.0", true)
    if FlyPaper and FlyPaper.AddFrame then
        FlyPaper.AddFrame("TweaksUI", wrapperId, frame)
    end
    
    return wrapper
end

local function RegisterWithLayout(slotIndex)
    if not TweaksUI.Layout then
        dprint("Layout module not available")
        return false
    end
    
    local Layout = TweaksUI.Layout
    
    -- Ensure frame and wrapper exist
    local frame = highlightFrames[slotIndex]
    if not frame then return false end
    
    local wrapper = layoutWrappers[slotIndex]
    if not wrapper then
        wrapper = CreateLayoutWrapper(slotIndex)
    end
    
    if not wrapper then return false end
    
    local wrapperId = "BuffHighlight_" .. slotIndex
    
    -- Register with FlyPaper if available
    local FlyPaper = LibStub and LibStub("LibFlyPaper-2.0", true)
    if FlyPaper then
        FlyPaper.AddFrame("TweaksUI", wrapperId, frame)
    end
    
    -- Register with Layout
    Layout:RegisterElement(wrapperId, {
        name = "Buff Highlight " .. slotIndex,
        category = "Cooldowns",
        tuiFrame = wrapper,
        defaultPosition = wrapper.defaultPosition,
    })
    
    dprint("Registered", wrapperId, "with Layout")
    return true
end

local function UnregisterFromLayout(slotIndex)
    if not TweaksUI.Layout then return end
    
    local wrapperId = "BuffHighlight_" .. slotIndex
    if TweaksUI.Layout.UnregisterElement then
        TweaksUI.Layout:UnregisterElement(wrapperId)
    end
    
    -- Remove from FlyPaper
    local FlyPaper = LibStub and LibStub("LibFlyPaper-2.0", true)
    if FlyPaper and FlyPaper.RemoveFrame then
        FlyPaper.RemoveFrame("TweaksUI", wrapperId)
    end
    
    layoutWrappers[slotIndex] = nil
end

local function RegisterAllWithLayout()
    if not TweaksUI.Layout then
        dprint("Layout module not available")
        return
    end
    
    local db = GetDB()
    for slotIndex, enabled in pairs(db.enabled) do
        if enabled and highlightFrames[slotIndex] then
            RegisterWithLayout(slotIndex)
        end
    end
end

-- ============================================================================
-- UPDATE TICKER
-- ============================================================================

local function StartUpdateTicker()
    if updateTicker then return end
    
    updateTicker = C_Timer.NewTicker(UPDATE_INTERVAL, function()
        pcall(UpdateAllHighlights)
    end)
    
    dprint("Update ticker started")
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function BuffHighlights:EnableHighlight(slotIndex, enabled)
    SetHighlightEnabled(slotIndex, enabled)
    
    if enabled then
        local frame = CreateHighlightFrame(slotIndex)
        
        -- Set default show states if not set
        local db = GetDB()
        if db.active.show[slotIndex] == nil then
            db.active.show[slotIndex] = true
        end
        if db.inactive.show[slotIndex] == nil then
            db.inactive.show[slotIndex] = false
        end
        
        -- Show frame immediately so user can see it
        frame:Show()
        
        -- Do initial update
        UpdateHighlightFrame(slotIndex)
        
        RegisterWithLayout(slotIndex)
        StartUpdateTicker()
        
        -- Notify user (without auto-opening Layout Mode)
        print("|cff00ff00TweaksUI:|r Per-Icon #" .. slotIndex .. " created. Use /tui layout to position.")
    else
        if highlightFrames[slotIndex] then
            highlightFrames[slotIndex]:Hide()
        end
        UnregisterFromLayout(slotIndex)
    end
end

function BuffHighlights:SetShowState(slotIndex, state, show)
    SetShowState(slotIndex, state, show)
    UpdateHighlightFrame(slotIndex)
end

function BuffHighlights:GetShowState(slotIndex, state)
    return GetShowState(slotIndex, state)
end

function BuffHighlights:SetSize(slotIndex, state, size)
    SetHighlightSize(slotIndex, state, size)
    UpdateHighlightFrame(slotIndex)
end

function BuffHighlights:GetSize(slotIndex, state)
    return GetHighlightSize(slotIndex, state)
end

function BuffHighlights:SetOpacity(slotIndex, state, opacity)
    SetHighlightOpacity(slotIndex, state, opacity)
    UpdateHighlightFrame(slotIndex)
end

function BuffHighlights:GetOpacity(slotIndex, state)
    return GetHighlightOpacity(slotIndex, state)
end

function BuffHighlights:SetSaturation(slotIndex, state, saturated)
    SetHighlightSaturation(slotIndex, state, saturated)
    UpdateHighlightFrame(slotIndex)
end

function BuffHighlights:GetSaturation(slotIndex, state)
    return GetHighlightSaturation(slotIndex, state)
end

function BuffHighlights:SetAspectRatio(slotIndex, state, ratio)
    SetHighlightAspectRatio(slotIndex, state, ratio)
    UpdateHighlightFrame(slotIndex)
end

function BuffHighlights:GetAspectRatio(slotIndex, state)
    return GetHighlightAspectRatio(slotIndex, state)
end

function BuffHighlights:SetCustomAspectRatio(slotIndex, state, width, height)
    local db = GetDB()
    db[state].customAspectW[slotIndex] = width or 1
    db[state].customAspectH[slotIndex] = height or 1
    SetHighlightAspectRatio(slotIndex, state, "custom")
    UpdateHighlightFrame(slotIndex)
end

function BuffHighlights:GetCustomAspectRatio(slotIndex, state)
    local db = GetDB()
    return db[state].customAspectW[slotIndex] or 1, db[state].customAspectH[slotIndex] or 1
end

-- Custom label API
function BuffHighlights:SetLabelEnabled(slotIndex, enabled)
    SetLabelEnabled(slotIndex, enabled)
    UpdateHighlightFrame(slotIndex)
end

function BuffHighlights:GetLabelEnabled(slotIndex)
    return GetLabelEnabled(slotIndex)
end

function BuffHighlights:SetLabelText(slotIndex, text)
    SetLabelText(slotIndex, text)
    UpdateHighlightFrame(slotIndex)
end

function BuffHighlights:GetLabelText(slotIndex)
    return GetLabelText(slotIndex)
end

function BuffHighlights:SetLabelFontSize(slotIndex, size)
    SetLabelFontSize(slotIndex, size)
    UpdateHighlightFrame(slotIndex)
end

function BuffHighlights:GetLabelFontSize(slotIndex)
    return GetLabelFontSize(slotIndex)
end

function BuffHighlights:SetLabelColor(slotIndex, color)
    SetLabelColor(slotIndex, color)
    UpdateHighlightFrame(slotIndex)
end

function BuffHighlights:GetLabelColor(slotIndex)
    return GetLabelColor(slotIndex)
end

function BuffHighlights:SetLabelOffsetX(slotIndex, offset)
    SetLabelOffsetX(slotIndex, offset)
    UpdateHighlightFrame(slotIndex)
end

function BuffHighlights:GetLabelOffsetX(slotIndex)
    return GetLabelOffsetX(slotIndex)
end

function BuffHighlights:SetLabelOffsetY(slotIndex, offset)
    SetLabelOffsetY(slotIndex, offset)
    UpdateHighlightFrame(slotIndex)
end

function BuffHighlights:GetLabelOffsetY(slotIndex)
    return GetLabelOffsetY(slotIndex)
end

function BuffHighlights:IsTrackerHidden()
    return IsTrackerHidden()
end

function BuffHighlights:ApplyTrackerVisibility()
    local viewer = _G["BuffIconCooldownViewer"]
    local container = _G["TweaksUI_BuffsContainer"]
    local hidden = IsTrackerHidden()
    
    -- Also check layout mode - always show during layout mode
    local isLayoutMode = false
    local layoutContainer = _G["TweaksUI_LayoutContainer"]
    if layoutContainer and layoutContainer:IsShown() then
        isLayoutMode = true
    end
    local Layout = TweaksUI.Layout
    if Layout and Layout:IsActive() then
        isLayoutMode = true
    end
    
    if hidden and not isLayoutMode then
        -- Hide tracker but keep it functional (alpha 0, non-interactable)
        if viewer then
            viewer:SetAlpha(0)
            viewer:EnableMouse(false)
        end
        if container then
            container:SetAlpha(0)
            container:EnableMouse(false)
        end
    else
        -- Show tracker - restore alpha and mouse
        if viewer then
            viewer:SetAlpha(1)
            viewer:EnableMouse(true)
        end
        if container then
            container:SetAlpha(1)
            container:EnableMouse(true)
        end
    end
end

-- Ticker to enforce hide state (runs every 0.5 seconds as backup)
local hideEnforcementTicker = nil
local hookedBuffFrames = {}  -- Track which frames have been hooked

-- Hook a frame to block visibility when tracker is hidden
local function HookBuffFrameVisibility(frame)
    if not frame or hookedBuffFrames[frame] then return end
    
    -- Hook SetAlpha to block making visible when hidden
    local originalSetAlpha = frame.SetAlpha
    frame.SetAlpha = function(self, alpha, ...)
        if IsTrackerHidden() and alpha > 0 then
            -- Allow during layout mode
            local layoutContainer = _G["TweaksUI_LayoutContainer"]
            if layoutContainer and layoutContainer:IsShown() then
                return originalSetAlpha(self, alpha, ...)
            end
            local Layout = TweaksUI.Layout
            if Layout and Layout:IsActive() then
                return originalSetAlpha(self, alpha, ...)
            end
            -- Force alpha to 0
            return originalSetAlpha(self, 0, ...)
        end
        return originalSetAlpha(self, alpha, ...)
    end
    
    hookedBuffFrames[frame] = true
end

local function StartHideEnforcement()
    -- Hook the viewer and container
    local viewer = _G["BuffIconCooldownViewer"]
    local container = _G["TweaksUI_BuffsContainer"]
    
    if viewer then HookBuffFrameVisibility(viewer) end
    if container then HookBuffFrameVisibility(container) end
    
    -- Immediately enforce hide
    if viewer then
        viewer:SetAlpha(0)
        viewer:EnableMouse(false)
    end
    if container then
        container:SetAlpha(0)
        container:EnableMouse(false)
    end
    
    -- Also use a backup ticker in case hooks miss something
    if hideEnforcementTicker then return end
    
    hideEnforcementTicker = C_Timer.NewTicker(0.5, function()
        if not IsTrackerHidden() then
            -- Stop ticker if no longer hidden
            if hideEnforcementTicker then
                hideEnforcementTicker:Cancel()
                hideEnforcementTicker = nil
            end
            return
        end
        
        -- Check layout mode
        local layoutContainer = _G["TweaksUI_LayoutContainer"]
        if layoutContainer and layoutContainer:IsShown() then
            return  -- Don't enforce during layout mode
        end
        local Layout = TweaksUI.Layout
        if Layout and Layout:IsActive() then
            return
        end
        
        -- Force hide the tracker
        local viewerFrame = _G["BuffIconCooldownViewer"]
        local containerFrame = _G["TweaksUI_BuffsContainer"]
        
        if viewerFrame and viewerFrame:GetAlpha() > 0 then
            viewerFrame:SetAlpha(0)
            viewerFrame:EnableMouse(false)
        end
        if containerFrame and containerFrame:GetAlpha() > 0 then
            containerFrame:SetAlpha(0)
            containerFrame:EnableMouse(false)
        end
    end)
end

local function StopHideEnforcement()
    if hideEnforcementTicker then
        hideEnforcementTicker:Cancel()
        hideEnforcementTicker = nil
    end
end

-- Override SetTrackerHidden to manage the enforcement ticker
local origSetTrackerHidden = BuffHighlights.SetTrackerHidden
function BuffHighlights:SetTrackerHidden(hidden)
    SetTrackerHidden(hidden)
    self:ApplyTrackerVisibility()
    
    if hidden then
        StartHideEnforcement()
    else
        StopHideEnforcement()
        -- Restore normal visibility
        local viewer = _G["BuffIconCooldownViewer"]
        local container = _G["TweaksUI_BuffsContainer"]
        if viewer then
            viewer:SetAlpha(1)
            viewer:EnableMouse(true)
        end
        if container then
            container:SetAlpha(1)
            container:EnableMouse(true)
        end
    end
end

function BuffHighlights:GetSlotCount()
    return GetBuffSlotCount()
end

function BuffHighlights:GetSlotInfo(slotIndex)
    return GetBuffSlotInfo(slotIndex)
end

function BuffHighlights:IsEnabled(slotIndex)
    return IsHighlightEnabled(slotIndex)
end

function BuffHighlights:ToggleDebug()
    debugMode = not debugMode
    print("|cff00ff00TweaksUI BuffHighlights:|r Debug mode", debugMode and "ENABLED" or "DISABLED")
end

-- Per-icon hidden API (hides icon completely from tracker)
function BuffHighlights:IsIconHidden(slotIndex)
    return IsIconHidden(slotIndex)
end

function BuffHighlights:SetIconHidden(slotIndex, hidden)
    SetIconHidden(slotIndex, hidden)
    UpdateHighlightFrame(slotIndex)
    -- Refresh the tracker layout to apply alpha=0 on hidden icons
    if TweaksUI.Cooldowns and TweaksUI.Cooldowns.RefreshTrackerLayout then
        TweaksUI.Cooldowns.RefreshTrackerLayout("buffs")
    end
    -- When unhiding, invalidate the buff state cache so visual state gets reapplied
    if not hidden and TweaksUI.Cooldowns and TweaksUI.Cooldowns.InvalidateBuffStateCache then
        TweaksUI.Cooldowns.InvalidateBuffStateCache(slotIndex)
    end
end

-- Per-icon cooldown text API
function BuffHighlights:GetCooldownTextScale(slotIndex)
    return GetCooldownTextScale(slotIndex)
end

function BuffHighlights:SetCooldownTextScale(slotIndex, scale)
    SetCooldownTextScale(slotIndex, scale)
    UpdateHighlightFrame(slotIndex)
end

function BuffHighlights:GetCooldownTextColor(slotIndex)
    return GetCooldownTextColor(slotIndex)
end

function BuffHighlights:SetCooldownTextColor(slotIndex, color)
    SetCooldownTextColor(slotIndex, color)
    UpdateHighlightFrame(slotIndex)
end

function BuffHighlights:GetCooldownTextOffsetX(slotIndex)
    return GetCooldownTextOffsetX(slotIndex)
end

function BuffHighlights:SetCooldownTextOffsetX(slotIndex, offset)
    SetCooldownTextOffsetX(slotIndex, offset)
    UpdateHighlightFrame(slotIndex)
end

function BuffHighlights:GetCooldownTextOffsetY(slotIndex)
    return GetCooldownTextOffsetY(slotIndex)
end

function BuffHighlights:SetCooldownTextOffsetY(slotIndex, offset)
    SetCooldownTextOffsetY(slotIndex, offset)
    UpdateHighlightFrame(slotIndex)
end

-- Per-icon count text API
function BuffHighlights:GetCountTextScale(slotIndex)
    return GetCountTextScale(slotIndex)
end

function BuffHighlights:SetCountTextScale(slotIndex, scale)
    SetCountTextScale(slotIndex, scale)
    UpdateHighlightFrame(slotIndex)
end

function BuffHighlights:GetCountTextColor(slotIndex)
    return GetCountTextColor(slotIndex)
end

function BuffHighlights:SetCountTextColor(slotIndex, color)
    SetCountTextColor(slotIndex, color)
    UpdateHighlightFrame(slotIndex)
end

function BuffHighlights:GetCountTextOffsetX(slotIndex)
    return GetCountTextOffsetX(slotIndex)
end

function BuffHighlights:SetCountTextOffsetX(slotIndex, offset)
    SetCountTextOffsetX(slotIndex, offset)
    UpdateHighlightFrame(slotIndex)
end

function BuffHighlights:GetCountTextOffsetY(slotIndex)
    return GetCountTextOffsetY(slotIndex)
end

function BuffHighlights:SetCountTextOffsetY(slotIndex, offset)
    SetCountTextOffsetY(slotIndex, offset)
    UpdateHighlightFrame(slotIndex)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function BuffHighlights:Initialize()
    if isInitialized then return end
    isInitialized = true
    
    dprint("Initializing BuffHighlights")
    
    -- Create frames for any enabled highlights
    local db = GetDB()
    for slotIndex, enabled in pairs(db.enabled) do
        if enabled then
            CreateHighlightFrame(slotIndex)
        end
    end
    
    -- Start update ticker if we have any enabled
    local hasEnabled = false
    for _, enabled in pairs(db.enabled) do
        if enabled then hasEnabled = true break end
    end
    if hasEnabled then
        StartUpdateTicker()
    end
    
    -- Register with Layout after a delay
    C_Timer.After(2, RegisterAllWithLayout)
    
    -- Apply initial tracker visibility and show icons after buff tracker is ready
    C_Timer.After(2.5, function()
        self:ApplyTrackerVisibility()
        -- Start hide enforcement if enabled
        if IsTrackerHidden() then
            StartHideEnforcement()
        end
        -- Initial update to show any enabled icons
        UpdateAllHighlights()
    end)
    
    -- Also update when entering world (in case buff tracker loads later)
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    initFrame:SetScript("OnEvent", function()
        C_Timer.After(3, function()
            UpdateAllHighlights()
        end)
    end)
    
    -- Hook into layout mode callbacks to show/hide frames
    if TweaksUI.Layout and TweaksUI.Layout.RegisterCallback then
        TweaksUI.Layout:RegisterCallback("OnLayoutModeEnter", function()
            -- Show tracker during layout mode (temporarily)
            local viewer = _G["BuffIconCooldownViewer"]
            local container = _G["TweaksUI_BuffsContainer"]
            if viewer then
                viewer:SetAlpha(1)
                viewer:EnableMouse(true)
            end
            if container then
                container:SetAlpha(1)
                container:EnableMouse(true)
            end
            
            -- Show all enabled highlight frames during layout mode
            local db = GetDB()
            for slotIndex, enabled in pairs(db.enabled) do
                if enabled then
                    local frame = highlightFrames[slotIndex]
                    if frame then
                        frame:Show()
                        -- Update appearance
                        UpdateHighlightFrame(slotIndex)
                    end
                end
            end
        end)
        
        TweaksUI.Layout:RegisterCallback("OnLayoutModeExit", function()
            -- Update all frames to respect their actual conditions
            UpdateAllHighlights()
            -- Re-apply tracker visibility setting
            self:ApplyTrackerVisibility()
        end)
    end
    
    dprint("BuffHighlights initialized")
end

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================

SLASH_TUIBUFFHIGHLIGHTS1 = "/tuibh"
SLASH_TUIBUFFHIGHLIGHTS2 = "/tuibuffhighlights"
SlashCmdList["TUIBUFFHIGHLIGHTS"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        args[#args + 1] = word:lower()
    end
    
    local cmd = args[1]
    
    if cmd == "config" or not cmd then
        BuffHighlights:ShowConfig()
    elseif cmd == "debug" then
        BuffHighlights:ToggleDebug()
    elseif cmd == "refresh" then
        BuffHighlights:RefreshConfigUI()
    elseif cmd == "dump" then
        -- Dump structure of first buff icon
        local slotIndex = tonumber(args[2]) or 1
        local icons = CollectBuffIcons()
        local icon = icons[slotIndex]
        if icon then
            print("|cff00ff00=== Buff Icon Slot " .. slotIndex .. " Structure ===|r")
            print("Frame: " .. tostring(icon:GetName() or "unnamed"))
            print("auraInstanceID: " .. tostring(icon.auraInstanceID))
            
            -- Check count properties specifically
            print("|cffff9900Count Properties:|r")
            print("  icon.Count: " .. tostring(icon.Count))
            print("  icon.count: " .. tostring(icon.count))
            print("  icon.CountText: " .. tostring(icon.CountText))
            print("  icon.countText: " .. tostring(icon.countText))
            
            -- If we found a count object, show its text
            local countObj = icon.Count or icon.count or icon.CountText or icon.countText
            if countObj then
                local text = ""
                local shown = false
                pcall(function() text = countObj:GetText() or "" end)
                pcall(function() shown = countObj:IsShown() end)
                print("  Count text: '" .. tostring(text) .. "', shown: " .. tostring(shown))
            end
            
            -- Try to get aura data via API
            if icon.auraInstanceID then
                print("|cffff9900Aura Data (from API):|r")
                pcall(function()
                    local auraData = AuraAPI:GetAuraDataByInstanceID("player", icon.auraInstanceID)
                    if auraData then
                        print("  name: " .. tostring(auraData.name))
                        print("  applications (stacks): " .. tostring(auraData.applications))
                        print("  duration: " .. tostring(auraData.duration))
                        print("  expirationTime: " .. tostring(auraData.expirationTime))
                    else
                        print("  No aura data returned")
                    end
                end)
            end
            
            -- Dump all regions
            print("|cffff9900Regions:|r")
            if icon.GetRegions then
                pcall(function()
                    for i, region in ipairs({icon:GetRegions()}) do
                        local rType = region:GetObjectType()
                        local rName = region:GetName() or "unnamed"
                        local rText = ""
                        if rType == "FontString" then
                            pcall(function() rText = region:GetText() or "" end)
                        end
                        print(string.format("  %d: %s (%s) text='%s'", i, tostring(rName), tostring(rType), tostring(rText)))
                    end
                end)
            end
            
            -- Dump children (wrapped in pcall to handle secret values)
            print("|cffff9900Children:|r")
            if icon.GetChildren then
                pcall(function()
                    for i, child in ipairs({icon:GetChildren()}) do
                        local cName = "unnamed"
                        local cType = "unknown"
                        pcall(function() cName = child:GetName() or "unnamed" end)
                        pcall(function() cType = child:GetObjectType() end)
                        print(string.format("  %d: %s (%s)", i, tostring(cName), tostring(cType)))
                        
                        -- Check child regions
                        if child.GetRegions then
                            pcall(function()
                                for j, region in ipairs({child:GetRegions()}) do
                                    local rType = "unknown"
                                    local rName = "unnamed"
                                    local rText = ""
                                    pcall(function() rType = region:GetObjectType() end)
                                    pcall(function() rName = region:GetName() or "unnamed" end)
                                    if rType == "FontString" then
                                        pcall(function() rText = region:GetText() or "" end)
                                    end
                                    print(string.format("    %d.%d: %s (%s) text='%s'", i, j, tostring(rName), tostring(rType), tostring(rText)))
                                end
                            end)
                        end
                    end
                end)
            end
        else
            print("|cffff0000No icon found at slot " .. slotIndex .. "|r")
        end
    elseif cmd == "status" then
        -- Show current status of everything
        print("|cff00ff00=== BuffHighlights Status ===|r")
        print("Initialized: " .. tostring(isInitialized))
        print("Update ticker running: " .. tostring(updateTicker ~= nil))
        print("Hide enforcement running: " .. tostring(hideEnforcementTicker ~= nil))
        print("Tracker hidden setting: " .. tostring(IsTrackerHidden()))
        print("In combat: " .. tostring(InCombatLockdown()))
        print("Debug mode: " .. tostring(debugMode))
        
        local viewer = _G["BuffIconCooldownViewer"]
        print("Viewer exists: " .. tostring(viewer ~= nil))
        if viewer then
            print("Viewer alpha: " .. tostring(viewer:GetAlpha()))
            print("Viewer shown: " .. tostring(viewer:IsShown()))
            print("Viewer children: " .. tostring(viewer:GetNumChildren() or 0))
        end
        
        local icons = CollectBuffIcons()
        print("Icons collected: " .. #icons)
        
        -- Show details about each collected icon
        for i, icon in ipairs(icons) do
            local auraID = icon.auraInstanceID
            local name = icon:GetName() or "unnamed"
            print(string.format("  Icon %d: %s, auraInstanceID=%s", i, name, tostring(auraID)))
        end
        
        local db = GetDB()
        local enabledCount = 0
        print("|cffff9900Enabled Per-Icon slots:|r")
        for slotIndex, enabled in pairs(db.enabled) do
            if enabled then
                enabledCount = enabledCount + 1
                local slotInfo = GetBuffSlotInfo(slotIndex)
                local frame = highlightFrames[slotIndex]
                local showActive = GetShowState(slotIndex, "active")
                local showInactive = GetShowState(slotIndex, "inactive")
                print(string.format("  Slot %d: frame=%s, isActive=%s, shown=%s", 
                    slotIndex,
                    tostring(frame ~= nil),
                    slotInfo and tostring(slotInfo.isActive) or "NO INFO",
                    frame and tostring(frame:IsShown()) or "no frame"))
                print(string.format("    showActive=%s, showInactive=%s", 
                    tostring(showActive), tostring(showInactive)))
            end
        end
        print("Total enabled slots: " .. enabledCount)
    elseif cmd == "force" then
        -- Force update all highlights
        print("|cff00ff00Forcing update of all highlights...|r")
        UpdateAllHighlights()
        print("Done!")
    elseif cmd == "watch" then
        -- Toggle watch mode - print every update
        if not BuffHighlights._watchMode then
            BuffHighlights._watchMode = true
            BuffHighlights._watchTicker = C_Timer.NewTicker(0.5, function()
                local db = GetDB()
                local msg = "Watch: "
                for slotIndex, enabled in pairs(db.enabled) do
                    if enabled then
                        local slotInfo = GetBuffSlotInfo(slotIndex)
                        local frame = highlightFrames[slotIndex]
                        msg = msg .. string.format("[%d:%s/%s] ", 
                            slotIndex,
                            slotInfo and (slotInfo.isActive and "A" or "I") or "?",
                            frame and (frame:IsShown() and "V" or "H") or "X")
                    end
                end
                print(msg)
            end)
            print("|cff00ff00Watch mode ON - will print state every 0.5s. /tuibh watch to stop|r")
        else
            BuffHighlights._watchMode = false
            if BuffHighlights._watchTicker then
                BuffHighlights._watchTicker:Cancel()
                BuffHighlights._watchTicker = nil
            end
            print("|cffff0000Watch mode OFF|r")
        end
    else
        print("|cff00ff00TweaksUI BuffHighlights Commands:|r")
        print("  /tuibh - Open config UI")
        print("  /tuibh debug - Toggle debug mode")
        print("  /tuibh dump [slot] - Dump icon structure")
        print("  /tuibh status - Show current status")
        print("  /tuibh force - Force update all highlights")
        print("  /tuibh watch - Toggle real-time state monitoring")
    end
end

-- Auto-initialize when Cooldowns module loads
if TweaksUI.Modules and TweaksUI.Modules.Cooldowns then
    -- Hook into Cooldowns initialization
    local origInit = TweaksUI.Modules.Cooldowns.Initialize
    if origInit then
        TweaksUI.Modules.Cooldowns.Initialize = function(...)
            local result = origInit(...)
            C_Timer.After(1, function()
                BuffHighlights:Initialize()
            end)
            return result
        end
    end
else
    -- Fallback: Initialize on PLAYER_LOGIN
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_LOGIN")
    initFrame:SetScript("OnEvent", function()
        C_Timer.After(3, function()
            BuffHighlights:Initialize()
        end)
    end)
end

-- Apply hide enforcement early on PLAYER_ENTERING_WORLD (before full initialization)
local earlyBuffHookFrame = CreateFrame("Frame")
earlyBuffHookFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
earlyBuffHookFrame:SetScript("OnEvent", function()
    -- Check if tracker should be hidden and apply hooks immediately
    if TweaksUI_CharDB and TweaksUI_CharDB.buffHighlights then
        local db = TweaksUI_CharDB.buffHighlights
        if db.hideTracker then
            StartHideEnforcement()
        end
    end
end)
