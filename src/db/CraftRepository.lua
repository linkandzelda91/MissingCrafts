setfenv(1, MissingCrafts)

---@class CraftRepository
---@field _db Database
---@field _characterRepository CharacterRepository
---@field _libCrafts LibCrafts
---@field _specializationDetector SpecializationDetector
CraftRepository = {}

---@alias CraftSource "Chest" | "Craft" | "Drop" | "Fishing" | "Gift" | "Pickpocketing" | "Quest" | "Trainer" | "Vendor" | "WorldObject" | "Unknown"
---@type table<CraftSource, CraftSource>
CraftSource = {
    Chest = "Chest",
    Craft = "Craft",
    Drop = "Drop",
    Fishing = "Fishing",
    Gift = "Gift",
    Pickpocketing = "Pickpocketing",
    Quest = "Quest",
    Trainer = "Trainer",
    Vendor = "Vendor",
    WorldObject = "WorldObject",
    Unknown = "Unknown",
}

---@shape Craft
---@field spellId number
---@field localizedProfessionName string
---@field localizedName string
---@field skillLevel number
---@field isAvailable boolean
---@field recipeId number|nil
---@field resultId number|nil
---@field requiredSpecialization CraftSpecialization|nil
---@field sources CraftSource[]

---@param database Database
---@param LibCrafts LibCrafts
---@param specializationDetector SpecializationDetector
function CraftRepository:Create(database, characterRepository, LibCrafts, specializationDetector)
    self._db = database
    self._characterRepository = characterRepository
    self._libCrafts = LibCrafts
    self._specializationDetector = specializationDetector
    return self
end

---@type table<LcRecipeSource, CraftSource>
local RECIPE_SOURCE_TO_CRAFT_SOURCE = {}
---@type table<LcSpellSource, CraftSource>
local SPELL_SOURCE_TO_CRAFT_SOURCE = {}

---@param craft LcCraft
---@param LibCrafts LibCrafts
---@return CraftSource[]
local function parseSources(craft, LibCrafts)
    if next(RECIPE_SOURCE_TO_CRAFT_SOURCE) == nil then
        local RecipeSource = LibCrafts.constants.recipe_sources
        RECIPE_SOURCE_TO_CRAFT_SOURCE[RecipeSource.Chest] = CraftSource.Chest
        RECIPE_SOURCE_TO_CRAFT_SOURCE[RecipeSource.CraftedByEngineer] = CraftSource.Craft
        RECIPE_SOURCE_TO_CRAFT_SOURCE[RecipeSource.Drop] = CraftSource.Drop
        RECIPE_SOURCE_TO_CRAFT_SOURCE[RecipeSource.Fishing] = CraftSource.Fishing
        RECIPE_SOURCE_TO_CRAFT_SOURCE[RecipeSource.GiftedToReturningEngineers] = CraftSource.Gift
        RECIPE_SOURCE_TO_CRAFT_SOURCE[RecipeSource.Pickpocketing] = CraftSource.Pickpocketing
        RECIPE_SOURCE_TO_CRAFT_SOURCE[RecipeSource.Quest] = CraftSource.Quest
        RECIPE_SOURCE_TO_CRAFT_SOURCE[RecipeSource.Vendor] = CraftSource.Vendor
    end

    if next(SPELL_SOURCE_TO_CRAFT_SOURCE) == nil then
        local SpellSource = LibCrafts.constants.spell_sources
        SPELL_SOURCE_TO_CRAFT_SOURCE[SpellSource.LearnedAutomatically] = CraftSource.Trainer
        SPELL_SOURCE_TO_CRAFT_SOURCE[SpellSource.Quest] = CraftSource.Quest
        SPELL_SOURCE_TO_CRAFT_SOURCE[SpellSource.Trainer] = CraftSource.Trainer
        SPELL_SOURCE_TO_CRAFT_SOURCE[SpellSource.WorldObject] = CraftSource.WorldObject
    end

    ---@type table<CraftSource, boolean>
    local craftSourcesSet = {}
    for _, recipe in ipairs(craft.recipes) do
        for _, recipeSource in ipairs(recipe.sources) do
            local craftSource = RECIPE_SOURCE_TO_CRAFT_SOURCE[recipeSource]
            if craftSource ~= nil then
                craftSourcesSet[craftSource] = true
            end
        end
    end
    for _, spellSource in ipairs(craft.sources) do
        local craftSource = SPELL_SOURCE_TO_CRAFT_SOURCE[spellSource]
        if craftSource ~= nil then
            craftSourcesSet[craftSource] = true
        end
    end

    ---@type CraftSource[]
    local craftSources = {}
    for source, _ in pairs(craftSourcesSet) do
        tinsert(craftSources, source)
    end
    return craftSources
end

---@param craft LcCraft
---@param professionRank number
---@param LibCrafts LibCrafts
---@param specializationDetector SpecializationDetector
---@return Craft
local function create(craft, professionRank, LibCrafts, specializationDetector)
    ---@type number|nil
    local recipeId
    for _, recipe in ipairs(craft.recipes) do
        recipeId = recipe.id
        break
    end

    ---@type number|nil
    local resultId
    if craft.result ~= nil then
        resultId = (--[[---@not nil]] craft.result).id
    end

    return {
        spellId = craft.spell_id,
        localizedProfessionName = craft.localized_profession_name,
        localizedName = craft.localized_spell_name,
        skillLevel = craft.skill_level,
        isAvailable = craft.skill_level <= professionRank,
        recipeId = recipeId,
        resultId = resultId,
        requiredSpecialization = specializationDetector:GetCraftRequiredSpecialization(craft),
        sources = parseSources(craft, LibCrafts)
    }
end


---@param name string
---@return string
local function normalizeSkillName(name)
    local normalized = strlower(name or "")
    normalized = string.gsub(normalized, "’", "'")
    normalized = string.gsub(normalized, "‘", "'")
    normalized = string.gsub(normalized, "´", "'")
    normalized = string.gsub(normalized, "`", "'")
    normalized = string.gsub(normalized, "–", "-")
    normalized = string.gsub(normalized, "—", "-")
    normalized = string.gsub(normalized, " ", " ")
    normalized = string.gsub(normalized, "%s+", " ")
    normalized = string.gsub(normalized, "^%s+", "")
    normalized = string.gsub(normalized, "%s+$", "")
    return normalized
end

---@param characterName string
---@param localizedProfessionName string
---@param searchQuery string
---@return Craft[]
function CraftRepository:FindMissing(characterName, localizedProfessionName, searchQuery)
    local professionRank = 0
    local characterSpecialization
    local character = self._characterRepository:Find(characterName)
    if character ~= nil then
        professionRank = (--[[---@not nil]] character):GetProfessionRank(localizedProfessionName)
        characterSpecialization = (--[[---@not nil]] character):GetProfessionSpecialization(localizedProfessionName)
    end

    ---@type table<string, boolean>
    local characterSkillSet = {}
    for _, skillName in ipairs(self._db:GetLocalizedSkillNames(characterName, localizedProfessionName)) do
        characterSkillSet[normalizeSkillName(skillName)] = true
    end

    ---@type table<number, boolean>
    local knownResultItemSet = {}
    for _, resultItemId in ipairs(self._db:GetKnownResultItemIds(characterName, localizedProfessionName)) do
        knownResultItemSet[resultItemId] = true
    end

    local lcSearchQuery = strlower(searchQuery)

    ---@type Craft[]
    local crafts = {}
    for _, craft in ipairs(self._libCrafts:GetCraftsByProfession(localizedProfessionName)) do
        local normalizedCraftName = normalizeSkillName(craft.localized_spell_name)
        local resultId = craft.result ~= nil and craft.result.id or nil
        local alreadyKnown = characterSkillSet[normalizedCraftName] ~= nil
            or (resultId ~= nil and knownResultItemSet[resultId] ~= nil)

        if not alreadyKnown then
            local mappedCraft = create(craft, professionRank, self._libCrafts, self._specializationDetector)
            local specializationMatches = characterSpecialization == nil
                or mappedCraft.requiredSpecialization == nil
                or mappedCraft.requiredSpecialization == characterSpecialization

            local match = false
            if lcSearchQuery ~= "" then
                local lcSpellName = strlower(craft.localized_spell_name)
                local a, b = strfind(lcSpellName, lcSearchQuery, 1, true)
                match = a ~= nil and b ~= nil
            else
                match = true
            end
            if match and specializationMatches then
                tinsert(crafts, mappedCraft)
            end
        end
    end

    return crafts
end

---@param itemId number
---@return Craft[]
function CraftRepository:FindByRecipeId(itemId)
    local playerName, _ = UnitName("player")
    local character = self._characterRepository:Find(playerName)

    ---@type Craft[]
    local crafts = {}
    for _, craft in ipairs(self._libCrafts:GetCraftsByRecipeId(itemId)) do
        local professionRank = 0
        if character ~= nil then
            professionRank = (--[[---@not nil]] character):GetProfessionRank(craft.localized_profession_name)
        end
        tinsert(crafts, create(craft, professionRank, self._libCrafts, self._specializationDetector))
    end

    return crafts
end
