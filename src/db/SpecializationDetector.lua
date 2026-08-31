setfenv(1, MissingCrafts)

---@alias CraftSpecialization "Goldsmith" | "Gemology"

---@class SpecializationDetector
---@field _tooltip GameTooltip
---@field _itemRequirementCache table<number, CraftSpecialization|false>
---@field _spellRequirementCache table<number, CraftSpecialization|false>
SpecializationDetector = {}

local TOOLTIP_NAME = "MissingCraftsSpecializationTooltip"

---@param text string|nil
---@return CraftSpecialization|nil
local function parseSpecialization(text)
    if type(text) ~= "string" then
        return nil
    end

    local lower = strlower(text)
    if strfind(lower, "goldsmith", 1, true) ~= nil then
        return "Goldsmith"
    end
    -- Match Gemology, Gemologist, Gemological, etc.
    if strfind(lower, "gemolog", 1, true) ~= nil then
        return "Gemology"
    end
    return nil
end

---@return self
function SpecializationDetector:Create()
    local object = --[[---@type self]] {}
    setmetatable(object, {__index = SpecializationDetector})

    local tooltip = getglobal(TOOLTIP_NAME)
    if tooltip == nil then
        tooltip = CreateFrame("GameTooltip", TOOLTIP_NAME, UIParent, "GameTooltipTemplate")
    end
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:Hide()

    object._tooltip = tooltip
    object._itemRequirementCache = {}
    object._spellRequirementCache = {}
    return object
end

---@return CraftSpecialization|nil, boolean
function SpecializationDetector:_ReadTooltipSpecialization()
    local numLines = self._tooltip:NumLines() or 0
    local hadText = false

    for i = 1, numLines do
        local left = getglobal(TOOLTIP_NAME .. "TextLeft" .. i)
        local right = getglobal(TOOLTIP_NAME .. "TextRight" .. i)

        if left ~= nil and left.GetText ~= nil then
            local text = left:GetText()
            if type(text) == "string" and text ~= "" then
                hadText = true
                local specialization = parseSpecialization(text)
                if specialization ~= nil then
                    return specialization, true
                end
            end
        end

        if right ~= nil and right.GetText ~= nil then
            local text = right:GetText()
            if type(text) == "string" and text ~= "" then
                hadText = true
                local specialization = parseSpecialization(text)
                if specialization ~= nil then
                    return specialization, true
                end
            end
        end
    end

    return nil, hadText
end

---@param hyperlink string
---@return CraftSpecialization|nil, boolean
function SpecializationDetector:_ScanHyperlink(hyperlink)
    self._tooltip:ClearLines()
    local ok = pcall(function()
        self._tooltip:SetHyperlink(hyperlink)
    end)
    if not ok then
        self._tooltip:Hide()
        return nil, false
    end

    local specialization, hadText = self:_ReadTooltipSpecialization()
    self._tooltip:Hide()
    return specialization, hadText
end

---@param itemId number
---@return CraftSpecialization|nil
function SpecializationDetector:_GetItemRequirement(itemId)
    local cached = self._itemRequirementCache[itemId]
    if cached ~= nil then
        if cached == false then
            return nil
        end
        return --[[---@type CraftSpecialization]] cached
    end

    local specialization, hadText = self:_ScanHyperlink("item:" .. itemId)
    if specialization ~= nil then
        self._itemRequirementCache[itemId] = specialization
    elseif hadText and GetItemInfo ~= nil then
        -- Do not permanently cache an incomplete uncached-item tooltip.
        -- Once GetItemInfo knows the item, a negative result is stable.
        local itemName = GetItemInfo(itemId)
        if itemName ~= nil then
            self._itemRequirementCache[itemId] = false
        end
    end
    return specialization
end

---@param spellId number
---@return CraftSpecialization|nil
function SpecializationDetector:_GetSpellRequirement(spellId)
    -- Survival placeholder IDs are deliberately outside the real spell range.
    if spellId >= 900000 then
        return nil
    end

    local cached = self._spellRequirementCache[spellId]
    if cached ~= nil then
        if cached == false then
            return nil
        end
        return --[[---@type CraftSpecialization]] cached
    end

    local specialization, hadText = self:_ScanHyperlink("spell:" .. spellId)
    if specialization ~= nil then
        self._spellRequirementCache[spellId] = specialization
    end
    -- Spell hyperlinks are not equally complete on every 1.12 client, so do
    -- not negative-cache them. Positive matches are still cached.
    return specialization
end

---@param englishProfessionName string
---@param skills LcpKnownSkill[]
---@return CraftSpecialization|nil
function SpecializationDetector:DetectPlayerProfessionSpecialization(englishProfessionName, skills)
    if englishProfessionName ~= "Jewelcrafting" then
        return nil
    end

    -- Some custom clients expose the specialization in the skill list.
    local numSkillLines = GetNumSkillLines and GetNumSkillLines() or 0
    for i = 1, numSkillLines do
        local localizedName = GetSkillLineInfo(i)
        local specialization = parseSpecialization(localizedName)
        if specialization ~= nil then
            return specialization
        end
    end

    -- Turtle/Octo specialization rewards are spells (for example Artisan
    -- Goldsmith), so the spellbook is the most reliable live source.
    if GetNumSpellTabs ~= nil and GetSpellTabInfo ~= nil and GetSpellName ~= nil then
        local numTabs = GetNumSpellTabs() or 0
        for tab = 1, numTabs do
            local _, _, offset, numSpells = GetSpellTabInfo(tab)
            if type(offset) == "number" and type(numSpells) == "number" then
                for slot = offset + 1, offset + numSpells do
                    local spellName = GetSpellName(slot, BOOKTYPE_SPELL or "spell")
                    local specialization = parseSpecialization(spellName)
                    if specialization ~= nil then
                        return specialization
                    end
                end
            end
        end
    end

    -- Fallback: known craft/result tooltips can carry the specialization
    -- requirement even when the specialization spell name is unavailable.
    for _, skill in ipairs(skills or {}) do
        local specialization = parseSpecialization(skill.localized_name)
        if specialization ~= nil then
            return specialization
        end
        if type(skill.item_link) == "string" and skill.item_link ~= "" then
            local tooltipSpecialization, _ = self:_ScanHyperlink(skill.item_link)
            if tooltipSpecialization ~= nil then
                return tooltipSpecialization
            end
        end
    end

    return nil
end

---@param craft LcCraft
---@return CraftSpecialization|nil
function SpecializationDetector:GetCraftRequiredSpecialization(craft)
    if craft.en_profession_name ~= "Jewelcrafting" then
        return nil
    end

    -- Goldsmith/Gemology is chosen at artisan level, so pre-225 crafts are
    -- common to both paths and do not need tooltip probing.
    if craft.skill_level < 225 then
        return nil
    end

    -- Recipe items are the strongest source: Turtle/Octo displays lines such
    -- as "Requires Goldsmith" / "Requires Gemology" directly on them.
    for _, recipe in ipairs(craft.recipes or {}) do
        local specialization = self:_GetItemRequirement(recipe.id)
        if specialization ~= nil then
            return specialization
        end
    end

    -- Some specialization crafts are trainer/quest taught and have no recipe
    -- item. Their crafted item or spell tooltip may still expose the same
    -- requirement, so check both before treating the craft as unrestricted.
    if craft.result ~= nil then
        local specialization = self:_GetItemRequirement(craft.result.id)
        if specialization ~= nil then
            return specialization
        end
    end

    return self:_GetSpellRequirement(craft.spell_id)
end
