setfenv(1, MissingCrafts)

---@shape Coords
---@field x number
---@field y number

---@shape Anchor
---@field framePoint WidgetAnchorPoint
---@field selfPoint WidgetAnchorPoint
---@field selfCoords Coords

---@shape Geometry
---@field width number
---@field height number
---@field top number
---@field left number

---@class PlacementPolicy
PlacementPolicy = {}

local FrameType = LibCraftingProfessionsConstants.FrameType

---@return boolean
local function pfUI()
    return IsAddOnLoaded("pfUI") == 1
end

---@param frameType LcpProfessionFrameType
---@return boolean
local function frameTypeSupportedByPfUI(frameType)
    return frameType == FrameType.VanillaCraftFrame or
           frameType == FrameType.VanillaTradeSkillFrame or
           frameType == FrameType.TurtleTradeSkillFrame
end

---@return boolean
local function MTSL()
    return getglobal("MTSLUI_TOGGLE_BUTTON") ~= nil
end

---@param frameType LcpProfessionFrameType
---@return Anchor
function PlacementPolicy:GetOpenButtonAnchor(frameType)
    ---@type Anchor
    local anchor = {
        framePoint = "TOPRIGHT",
        selfPoint = "TOPRIGHT",
        selfCoords = {x = 0, y = 0},
    }

    if pfUI() and frameTypeSupportedByPfUI(frameType) then
        if MTSL() then
            anchor.selfCoords = {x = -15, y = -70}
        else
            anchor.selfCoords = {x = -30, y = -1}
        end
    elseif frameType == FrameType.AdvancedTradeSkillWindow then
        anchor.selfCoords = {x = -54, y = -91}
    elseif frameType == FrameType.AdvancedTradeSkillWindow2 then
        anchor.selfCoords = {x = -48, y = -77}
    elseif frameType == FrameType.Artisan then
        anchor.selfCoords = {x = -44, y = -60}
    elseif frameType == FrameType.TurtleTradeSkillFrame then
        anchor.selfCoords = {x = -96, y = -61}
    elseif frameType == FrameType.VanillaTradeSkillFrame then
        if MTSL() then
            anchor.selfCoords = {x = -93, y = 20}
        else
            anchor.selfCoords = {x = -38, y = 20}
        end
    elseif frameType == FrameType.VanillaCraftFrame then
        anchor.selfCoords = {x = -44, y = -60}
    end

    return anchor
end

---@param frame Frame
---@return number
local function getEffectiveScale(frame)
    local ok, scale = pcall(function()
        if frame ~= nil and frame.GetEffectiveScale ~= nil then
            return frame:GetEffectiveScale()
        end
        if frame ~= nil and frame.GetScale ~= nil then
            return frame:GetScale()
        end
        return 1
    end)
    if not ok or type(scale) ~= "number" or scale <= 0 then
        return 1
    end
    return scale
end

---@param frame Frame
---@return number|nil, number|nil, number|nil, number|nil, number|nil, number|nil
local function safeFrameBounds(frame)
    if frame == nil then
        return nil
    end
    local frameType = type(frame)
    if frameType ~= "table" and frameType ~= "userdata" then
        return nil
    end

    local ok, left, right, top, bottom, visible = pcall(function()
        if frame.GetLeft == nil or frame.GetRight == nil or frame.GetTop == nil or frame.GetBottom == nil then
            return nil, nil, nil, nil, false
        end
        return frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom(), frame:IsVisible()
    end)
    if not ok or not visible or left == nil or right == nil or top == nil or bottom == nil then
        return nil
    end

    -- GetLeft/GetRight/GetTop/GetBottom are expressed in the frame's own
    -- effective coordinate scale. Comparing values from frames that use
    -- different scales makes a nearby side tab look hundreds of pixels away.
    -- Normalize every candidate into UIParent coordinates before doing any
    -- overlap/placement math. This is especially important with Turtle/Octo
    -- profession-tab addons and scaled profession UIs.
    local uiScale = getEffectiveScale(UIParent)
    local frameScale = getEffectiveScale(frame)
    local scale = frameScale / uiScale

    left = left * scale
    right = right * scale
    top = top * scale
    bottom = bottom * scale

    return left, right, top, bottom, right - left, top - bottom
end

---@param professionFrame Frame
---@return number, number
local function getExternalTabPadding(professionFrame)
    local frameLeft, frameRight, frameTop, frameBottom = safeFrameBounds(professionFrame)
    if frameLeft == nil then
        return 0, 0
    end

    local leftPadding = 0
    local rightPadding = 0
    local visited = {}

    local function inspect(candidate)
        if candidate == nil or candidate == professionFrame or visited[candidate] then
            return
        end
        visited[candidate] = true

        local left, right, top, bottom, width, height = safeFrameBounds(candidate)
        if left ~= nil and width ~= nil and height ~= nil
            and width >= 12 and width <= 72 and height >= 12 and height <= 96 then
            local overlap = math.min(frameTop, top) - math.max(frameBottom, bottom)
            if overlap > 0 then
                -- Only treat small frames that actually hug an outer edge as
                -- external tabs. The extra near-edge bound avoids unrelated
                -- global buttons being mistaken for profession tabs.
                if left < frameLeft and right >= frameLeft - 24 and right <= frameLeft + 24 then
                    leftPadding = math.max(leftPadding, frameLeft - left)
                end
                if right > frameRight and left <= frameRight + 24 and left >= frameRight - 24 then
                    rightPadding = math.max(rightPadding, right - frameRight)
                end
            end
        end
    end

    -- Check children first. External profession-tab addons commonly parent
    -- their buttons directly to the profession frame, and those buttons do
    -- not need to have global names. Two levels also catches tab containers.
    local ok, children = pcall(function()
        return {professionFrame:GetChildren()}
    end)
    if ok and children ~= nil then
        for _, child in ipairs(children) do
            inspect(child)
            local childOk, grandchildren = pcall(function()
                return {child:GetChildren()}
            end)
            if childOk and grandchildren ~= nil then
                for _, grandchild in ipairs(grandchildren) do
                    inspect(grandchild)
                end
            end
        end
    end

    -- Also check named/global frames for addons that parent their tabs to
    -- UIParent rather than to the profession frame itself.
    for _, candidate in pairs(_G) do
        inspect(candidate)
    end

    if leftPadding > 0 then
        leftPadding = math.min(leftPadding + 4, 96)
    end
    if rightPadding > 0 then
        rightPadding = math.min(rightPadding + 4, 96)
    end
    return leftPadding, rightPadding
end

---@param frameType LcpProfessionFrameType
---@return number
local function getWindowHeight(frameType)
    if pfUI() and frameTypeSupportedByPfUI(frameType) then
        return 450
    elseif frameType == FrameType.AdvancedTradeSkillWindow2 then
        return 494
    elseif frameType == FrameType.Artisan then
        return 469
    end
    return 430
end

---@param professionFrame Frame
---@param frameType LcpProfessionFrameType
---@return Geometry
function PlacementPolicy:GetMainWindowGeometry(professionFrame, frameType)
    -- Keep the profession frame itself in the same normalized UIParent
    -- coordinate space used by external-tab detection. Mixing raw coordinates
    -- from scaled frames was the cause of the MissingCrafts window jumping
    -- sideways when switching profession tabs.
    local frameLeft, frameRight, frameTop = safeFrameBounds(professionFrame)
    if frameLeft == nil or frameRight == nil or frameTop == nil then
        frameLeft = professionFrame:GetLeft() or 0
        frameRight = professionFrame:GetRight() or frameLeft
        frameTop = professionFrame:GetTop() or 0
    end

    local width = 384
    local height = getWindowHeight(frameType)
    local gap = 4
    local leftPadding, rightPadding = getExternalTabPadding(professionFrame)

    local uiLeft = UIParent:GetLeft() or 0
    local uiRight = UIParent:GetRight() or UIParent:GetWidth()
    local rightLeft = frameRight + gap + rightPadding
    local leftLeft = frameLeft - gap - leftPadding - width
    local rightFits = rightLeft + width <= uiRight
    local leftFits = leftLeft >= uiLeft

    local left
    if rightFits then
        left = rightLeft
    elseif leftFits then
        left = leftLeft
    else
        -- If neither side fully fits, use the side with more room and clamp to
        -- the screen. This is safer for scaled UIs and narrow resolutions.
        local roomRight = uiRight - frameRight - rightPadding
        local roomLeft = frameLeft - uiLeft - leftPadding
        if roomRight >= roomLeft then
            left = math.max(uiLeft, math.min(rightLeft, uiRight - width))
        else
            left = math.max(uiLeft, math.min(leftLeft, uiRight - width))
        end
    end

    local top = frameTop - 10
    if pfUI() and frameTypeSupportedByPfUI(frameType) then
        top = frameTop + 5
    end

    return {width = width, height = height, top = top, left = left}
end
