setfenv(1, MissingCrafts)

---@class Database
---@field _db DatabaseSavedVariable
Database = {}

---@shape DatabaseProfession
---@field rank number
---@field knownLocalizedSkillNames string[]
---@field knownResultItemIds number[]
---@field specialization CraftSpecialization|nil

---@shape DatabaseCharacter
---@field realm string
---@field english_faction string
---@field localized_faction string
---@field name string
---@field professionsByLocalizedName table<string, DatabaseProfession>

---@shape DatabaseSavedVariable
---@field global {realmToNameToCharacter: table<string, table<string, DatabaseCharacter>>}

---@param AceDB LibAceDBDef
---@return self
function Database:Create(AceDB)
    ---@type DatabaseSavedVariable
    local defaults = {
        global = {
            realmToNameToCharacter = {
                ["*"] = {
                    ["*"] = {
                        ["realm"] = "",
                        ["english_faction"] = "",
                        ["localized_faction"] = "",
                        ["name"] = "",
                        ["professionsByLocalizedName"] = {}
                    }
                },
            },
        },
    }

    self._db = --[[---@type DatabaseSavedVariable]] AceDB:New("MissingCraftsDatabase", defaults)

    return self
end

---@return DatabaseCharacter[]
function Database:GetCharacters()
    self:_SavePlayer()

    ---@type DatabaseCharacter[]
    local characters = {}
    for _, nameToCharacter in pairs(self._db.global.realmToNameToCharacter) do
        for _, character in pairs(nameToCharacter) do
            tinsert(characters, character)
        end
    end
    return characters
end

---@param characterName string
---@param localizedProfessionName string
---@return string[]
function Database:GetLocalizedSkillNames(characterName, localizedProfessionName)
    ---@type DatabaseProfession
    local profession
    for _, nameToCharacter in pairs(self._db.global.realmToNameToCharacter) do
        if nameToCharacter[characterName] ~= nil then
            profession = nameToCharacter[characterName].professionsByLocalizedName[localizedProfessionName]
        end
    end
    return (profession or {}).knownLocalizedSkillNames or {}
end


---@param characterName string
---@param localizedProfessionName string
---@return number[]
function Database:GetKnownResultItemIds(characterName, localizedProfessionName)
    ---@type DatabaseProfession
    local profession
    for _, nameToCharacter in pairs(self._db.global.realmToNameToCharacter) do
        if nameToCharacter[characterName] ~= nil then
            profession = nameToCharacter[characterName].professionsByLocalizedName[localizedProfessionName]
        end
    end
    return (profession or {}).knownResultItemIds or {}
end


---@param characterName string
---@param localizedProfessionName string
---@return CraftSpecialization|nil
function Database:GetProfessionSpecialization(characterName, localizedProfessionName)
    for _, nameToCharacter in pairs(self._db.global.realmToNameToCharacter) do
        if nameToCharacter[characterName] ~= nil then
            local profession = nameToCharacter[characterName].professionsByLocalizedName[localizedProfessionName]
            if profession ~= nil then
                return profession.specialization
            end
        end
    end
    return nil
end

---@param localizedProfessionName string
---@param professionRank number
---@param localizedSkillNames string[]
---@param knownResultItemIds number[]
---@param specialization CraftSpecialization|nil
function Database:SaveCurrentPlayerSkills(localizedProfessionName, professionRank, localizedSkillNames, knownResultItemIds, specialization)
    local player = self:_SavePlayer()
    local previous = player.professionsByLocalizedName[localizedProfessionName]
    if specialization == nil and previous ~= nil then
        specialization = previous.specialization
    end

    player.professionsByLocalizedName[localizedProfessionName] = {
        rank = professionRank,
        knownLocalizedSkillNames = localizedSkillNames,
        knownResultItemIds = knownResultItemIds or {},
        specialization = specialization
    }
end

---@param localizedProfessionNames string[]
function Database:SaveCurrentPlayerProfessions(localizedProfessionNames)
    ---@type table<string, boolean>
    local set = {}
    for _, localizedProfessionName in ipairs(localizedProfessionNames) do
        set[localizedProfessionName] = true
    end

    local player = self:_SavePlayer()
    for localizedProfessionName, _ in pairs(player.professionsByLocalizedName) do
        if set[localizedProfessionName] == nil then
            player.professionsByLocalizedName[localizedProfessionName] = nil
        end
    end
end

---@return DatabaseCharacter
function Database:_SavePlayer()
    local realm = GetRealmName()
    local name, _ = UnitName("player")
    local english_faction, localized_faction = UnitFactionGroup("player")

    local player = self._db.global.realmToNameToCharacter[realm][name]
    player.realm = realm
    player.english_faction = english_faction
    player.localized_faction = localized_faction
    player.name = name
    return player
end
