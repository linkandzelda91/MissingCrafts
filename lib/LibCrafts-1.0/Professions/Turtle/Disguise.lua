local lib = LibCraftsGetLibrary()
local name, version = "Professions-Disguise", 2
local module = --[[---@type LcProfessionModule]] lib:RegisterProfessionModule(name, version, "Disguise")
if not module then return end

local Quality = lib.constants.qualities
local SpellSource = lib.constants.spell_sources
local RecipeSource = lib.constants.recipe_sources

if lib.env.is_turtle_wow then
    module:NewCraft(5169, "Defias Disguise", 1, {})
        :SetMinCharacterLevel(13)
        :AddRecipe(5126, Quality.Common, {RecipeSource.Vendor})
        
    :AddReagent(2589, 1)
    :Save()

    module:NewCraft(5264, "South Seas Pirate Disguise", 1, {})
        :SetMinCharacterLevel(13)
        :AddRecipe(5127, Quality.Common, {RecipeSource.Vendor})
        
    :AddReagent(2589, 1)
    :Save()

    module:NewCraft(5265, "Stonesplinter Trogg Disguise", 1, {})
        :SetMinCharacterLevel(13)
        :AddRecipe(5131, Quality.Common, {RecipeSource.Vendor})
        
    :AddReagent(2589, 1)
    :Save()

    module:NewCraft(5266, "Syndicate Disguise", 1, {})
        :SetMinCharacterLevel(22)
        :AddRecipe(5132, Quality.Common, {RecipeSource.Vendor})
        
    :AddReagent(2592, 1)
    :Save()

    module:NewCraft(5267, "Dalaran Wizard Disguise", 1, {})
        :SetMinCharacterLevel(13)
        :AddRecipe(5130, Quality.Common, {RecipeSource.Vendor})
        
    :AddReagent(2589, 1)
    :Save()

    module:NewCraft(5268, "Dark Iron Dwarf Disguise", 1, {})
        :SetMinCharacterLevel(22)
        :AddRecipe(5129, Quality.Common, {RecipeSource.Vendor})
        
    :AddReagent(2592, 1)
    :Save()

    module:NewCraft(5668, "Peasant Disguise", 1, {SpellSource.LearnedAutomatically})
        :SetMinCharacterLevel(2)
        :AddReagent(2589, 1) -- Linen Cloth
        :Save()

    module:NewCraft(5669, "Peon Disguise", 1, {SpellSource.LearnedAutomatically})
        :SetMinCharacterLevel(2)
        :AddReagent(2589, 1) -- Linen Cloth
        :Save()
end
