--[[
  Standalone Radial Swipe Implementation
  Extracted from WeakAuras for use in other addons
  
  This provides the core functionality for circular/radial progress animations
  similar to cooldown swipes on spell icons.
]]

local addonName, TweaksUI = ...
local RadialSwipe = {}

-- Register in TweaksUI namespace
TweaksUI.RadialSwipe = RadialSwipe

-- =====================================================
-- TEXTURE COORDINATE UTILITIES
-- =====================================================

local TextureCoords = {}
TextureCoords.__index = TextureCoords

-- Creates a texture coordinate handler for a texture
function TextureCoords:New(texture)
  local coords = setmetatable({}, TextureCoords)
  coords.texture = texture
  coords.ULx, coords.ULy = 0, 0
  coords.LLx, coords.LLy = 0, 1
  coords.URx, coords.URy = 1, 0
  coords.LRx, coords.LRy = 1, 1
  return coords
end

-- Apply the current coordinates to the texture
function TextureCoords:Show()
  self.texture:SetTexCoord(self.ULx, self.ULy, self.LLx, self.LLy,
                           self.URx, self.URy, self.LRx, self.LRy)
  self.texture:Show()
end

function TextureCoords:Hide()
  self.texture:Hide()
end

-- Set coordinates to show full texture
function TextureCoords:SetFull()
  self.ULx, self.ULy = 0, 0
  self.LLx, self.LLy = 0, 1
  self.URx, self.URy = 1, 0
  self.LRx, self.LRy = 1, 1
end

-- Transform point for rotation, mirroring, and cropping
local function TransformPoint(x, y, width, height, crop_x, crop_y, texRotation, mirror_h, mirror_v)
  local rx = x / width
  local ry = y / height
  
  -- Apply cropping
  rx = (rx - 0.5) * crop_x + 0.5
  ry = (ry - 0.5) * crop_y + 0.5
  
  -- Apply rotation
  if texRotation and texRotation ~= 0 then
    local angle = math.rad(texRotation)
    local cos_angle = math.cos(angle)
    local sin_angle = math.sin(angle)
    rx, ry = rx - 0.5, ry - 0.5
    rx, ry = rx * cos_angle - ry * sin_angle, rx * sin_angle + ry * cos_angle
    rx, ry = rx + 0.5, ry + 0.5
  end
  
  -- Apply mirroring
  if mirror_h then rx = 1 - rx end
  if mirror_v then ry = 1 - ry end
  
  return rx, ry
end

-- Set coordinates for a circular slice between two angles
function TextureCoords:SetAngle(width, height, angle1, angle2)
  angle1 = angle1 % 360
  angle2 = angle2 % 360
  
  if angle2 < angle1 then
    angle2 = angle2 + 360
  end
  
  local segments = {{angle1, angle2}}
  
  -- Calculate center and corner points
  local x1, y1 = width / 2, height / 2  -- Center point
  
  -- Calculate edge points based on angles
  local function AngleToPoint(angle)
    local rad = math.rad(angle)
    local cos = math.cos(rad)
    local sin = math.sin(rad)
    
    -- Determine which edge the angle intersects
    local x, y
    if math.abs(cos) > math.abs(sin) then
      if cos > 0 then
        x = width
        y = height / 2 - width / 2 * sin / cos
      else
        x = 0
        y = height / 2 + width / 2 * sin / cos
      end
    else
      if sin > 0 then
        y = 0
        x = width / 2 - height / 2 * cos / sin
      else
        y = height
        x = width / 2 + height / 2 * cos / sin
      end
    end
    return x, y
  end
  
  local x2, y2 = AngleToPoint(angle1)
  local x3, y3 = AngleToPoint(angle2)
  
  -- Store the triangle coordinates (center, start, end)
  self.x1, self.y1 = x1, y1
  self.x2, self.y2 = x2, y2
  self.x3, self.y3 = x3, y3
  
  -- Set texture coordinates for the triangle
  self.ULx, self.ULy = x1 / width, y1 / height
  self.LLx, self.LLy = x2 / width, y2 / height
  self.URx, self.URy = x1 / width, y1 / height
  self.LRx, self.LRy = x3 / width, y3 / height
end

-- Apply transformations to the coordinates
function TextureCoords:Transform(crop_x, crop_y, texRotation, mirror_h, mirror_v)
  local width, height = self.texture:GetSize()
  if width == 0 or height == 0 then
    width, height = 100, 100  -- Default size
  end
  
  self.ULx, self.ULy = TransformPoint(self.x1 or 0, self.y1 or 0, width, height, crop_x, crop_y, texRotation, mirror_h, mirror_v)
  self.LLx, self.LLy = TransformPoint(self.x2 or 0, self.y2 or height, width, height, crop_x, crop_y, texRotation, mirror_h, mirror_v)
  self.URx, self.URy = TransformPoint(self.x3 or width, self.y3 or 0, width, height, crop_x, crop_y, texRotation, mirror_h, mirror_v)
  self.LRx, self.LRy = TransformPoint(self.x3 or width, self.y3 or height, width, height, crop_x, crop_y, texRotation, mirror_h, mirror_v)
end

-- =====================================================
-- CIRCULAR PROGRESS TEXTURE
-- =====================================================

function RadialSwipe:CreateSpinner(parent)
  local spinner = {
    parent = parent,
    textures = {},
    coords = {},
    angle1 = 0,
    angle2 = 360,
    crop_x = 1,
    crop_y = 1,
    texRotation = 0,
    mirror = false,
    visible = true,
    width = 100,
    height = 100
  }
  
  -- Create 3 textures to handle different angular segments
  for i = 1, 3 do
    local texture = parent:CreateTexture(nil, "OVERLAY", nil, 2)
    texture:SetSnapToPixelGrid(false)
    texture:SetTexelSnappingBias(0)
    texture:SetAllPoints(parent)
    spinner.textures[i] = texture
    spinner.coords[i] = TextureCoords:New(texture)
  end
  
  setmetatable(spinner, {__index = RadialSwipe})
  return spinner
end

-- Set the texture for the spinner
function RadialSwipe:SetTexture(texturePath)
  for i = 1, 3 do
    self.textures[i]:SetTexture(texturePath)
  end
end

-- Set the color of the spinner
function RadialSwipe:SetColor(r, g, b, a)
  for i = 1, 3 do
    self.textures[i]:SetVertexColor(r, g, b, a)
  end
end

-- Set the blend mode
function RadialSwipe:SetBlendMode(blendMode)
  for i = 1, 3 do
    self.textures[i]:SetBlendMode(blendMode)
  end
end

-- Show the spinner
function RadialSwipe:Show()
  self.visible = true
  self:UpdateTextures()
end

-- Hide the spinner
function RadialSwipe:Hide()
  self.visible = false
  for i = 1, 3 do
    self.textures[i]:Hide()
  end
end

-- Update the texture coordinates based on current angles
function RadialSwipe:UpdateTextures()
  if not self.visible then return end
  
  local angle1 = self.angle1
  local angle2 = self.angle2
  
  if not angle1 or not angle2 then return end
  
  -- Show full circle
  if angle2 - angle1 >= 360 then
    self.coords[1]:SetFull()
    self.coords[1]:Transform(self.crop_x, self.crop_y, self.texRotation, self.mirror, false)
    self.coords[1]:Show()
    self.coords[2]:Hide()
    self.coords[3]:Hide()
    return
  end
  
  -- No progress
  if angle1 == angle2 then
    self.coords[1]:Hide()
    self.coords[2]:Hide()
    self.coords[3]:Hide()
    return
  end
  
  -- Determine how many texture segments we need
  local index1 = math.floor((angle1 + 45) / 90)
  local index2 = math.floor((angle2 + 45) / 90)
  
  if index1 + 1 >= index2 then
    -- Single segment
    self.coords[1]:SetAngle(self.width, self.height, angle1, angle2)
    self.coords[1]:Transform(self.crop_x, self.crop_y, self.texRotation, self.mirror, false)
    self.coords[1]:Show()
    self.coords[2]:Hide()
    self.coords[3]:Hide()
  elseif index1 + 3 >= index2 then
    -- Two segments
    local firstEndAngle = (index1 + 1) * 90 + 45
    self.coords[1]:SetAngle(self.width, self.height, angle1, firstEndAngle)
    self.coords[1]:Transform(self.crop_x, self.crop_y, self.texRotation, self.mirror, false)
    self.coords[1]:Show()
    
    self.coords[2]:SetAngle(self.width, self.height, firstEndAngle, angle2)
    self.coords[2]:Transform(self.crop_x, self.crop_y, self.texRotation, self.mirror, false)
    self.coords[2]:Show()
    
    self.coords[3]:Hide()
  else
    -- Three segments
    local firstEndAngle = (index1 + 1) * 90 + 45
    local secondEndAngle = firstEndAngle + 180
    
    self.coords[1]:SetAngle(self.width, self.height, angle1, firstEndAngle)
    self.coords[1]:Transform(self.crop_x, self.crop_y, self.texRotation, self.mirror, false)
    self.coords[1]:Show()
    
    self.coords[2]:SetAngle(self.width, self.height, firstEndAngle, secondEndAngle)
    self.coords[2]:Transform(self.crop_x, self.crop_y, self.texRotation, self.mirror, false)
    self.coords[2]:Show()
    
    self.coords[3]:SetAngle(self.width, self.height, secondEndAngle, angle2)
    self.coords[3]:Transform(self.crop_x, self.crop_y, self.texRotation, self.mirror, false)
    self.coords[3]:Show()
  end
end

-- Set the progress (angles) for the spinner
function RadialSwipe:SetProgress(angle1, angle2)
  self.angle1 = angle1
  self.angle2 = angle2
  self:UpdateTextures()
end

-- Set progress as a percentage (0-1) in clockwise direction
function RadialSwipe:SetProgressValue(progress, startAngle, endAngle)
  startAngle = startAngle or 0
  endAngle = endAngle or 360
  progress = math.max(0, math.min(1, progress))
  
  local angle = (endAngle - startAngle) * progress + startAngle
  self:SetProgress(startAngle, angle)
end

-- Set progress as a percentage (0-1) in counter-clockwise direction
function RadialSwipe:SetProgressValueInverse(progress, startAngle, endAngle)
  startAngle = startAngle or 0
  endAngle = endAngle or 360
  progress = math.max(0, math.min(1, progress))
  progress = 1 - progress
  
  local angle = (endAngle - startAngle) * progress + startAngle
  self:SetProgress(angle, endAngle)
end

-- Set size of the spinner
function RadialSwipe:SetSize(width, height)
  self.width = width
  self.height = height
  self:UpdateTextures()
end

-- =====================================================
-- EXAMPLE USAGE
-- =====================================================

--[[
  Example: Adding a radial swipe to an existing cooldown icon
  
  -- Create a frame (or use your existing icon frame)
  local iconFrame = CreateFrame("Frame", nil, UIParent)
  iconFrame:SetSize(64, 64)
  iconFrame:SetPoint("CENTER")
  
  -- Create a texture for the icon
  local iconTexture = iconFrame:CreateTexture(nil, "BACKGROUND")
  iconTexture:SetAllPoints()
  iconTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
  
  -- Create the radial swipe overlay
  local swipe = RadialSwipe:CreateSpinner(iconFrame)
  swipe:SetTexture("Interface\\AddOns\\WeakAuras\\PowerAurasMedia\\Auras\\Aura3")
  swipe:SetColor(0, 0, 0, 0.8)  -- Dark overlay
  swipe:SetBlendMode("BLEND")
  swipe:SetSize(64, 64)
  swipe:Show()
  
  -- Animate the swipe (cooldown effect)
  local start = GetTime()
  local duration = 10  -- 10 second cooldown
  
  iconFrame:SetScript("OnUpdate", function()
    local elapsed = GetTime() - start
    local progress = elapsed / duration
    
    if progress >= 1 then
      swipe:Hide()
      iconFrame:SetScript("OnUpdate", nil)
    else
      -- Clockwise swipe (emptying)
      swipe:SetProgressValueInverse(progress, 0, 360)
    end
  end)
]]

-- Don't return, we've already registered in TweaksUI namespace
