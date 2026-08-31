setfenv(1, MissingCrafts)

---@shape AddonInfo
---@field name string
---@field version string

---@type AddonInfo
local addonInfo = {
    name = ADDON_NAME,
    version = ADDON_VERSION
}

---@type LibStubDef
local LibStub = getglobal("LibStub")
assert(LibStub ~= nil, "LibStub is required to run this addon")

local AceAddon, _ = LibStub("AceAddon-3.0")
local AceDB, _ = LibStub("AceDB-3.0")
local AceGUI, _ = LibStub("AceGUI-3.0")
local AceHook, _ = LibStub("AceHook-3.0")

local AceLocale, _ = LibStub("AceLocale-3.0")
local L = --[[---@type MissingCraftsLocale]] AceLocale:GetLocale(ADDON_NAME, false)

local LibCraftingProfessions = --[[---@type LibCraftingProfessions]] LibStub("LibCraftingProfessions-1.0")
local LibCrafts = --[[---@type LibCrafts]] LibStub("LibCrafts-1.0")
local LibItemTooltip = --[[---@type LibItemTooltip]] LibStub("LibItemTooltip-1.0")

---@shape Repositories
---@field characterRepository CharacterRepository
---@field professionRepository ProfessionRepository
---@field craftRepository CraftRepository

---@shape Libraries
---@field AceGUI LibAceGUI
---@field AceHook LibAceHookDef
---@field LibCrafts LibCrafts
---@field LibItemTooltip LibItemTooltip

---@class MissingCrafts: AceAddonDef
---@field database Database
---@field uiManager UIManager

---@type MissingCrafts
local addon = --[[---@type MissingCrafts]] AceAddon:NewAddon("MissingCrafts")

function addon:OnEnable()
    ---@type Libraries
    local libraries = {
        AceGUI = AceGUI,
        AceHook = AceHook,
        LibCrafts = LibCrafts,
        LibItemTooltip = LibItemTooltip,
    }

    self.database = Database:Create(AceDB)

    local characterRepository = CharacterRepository:Create(self.database)
    local specializationDetector = SpecializationDetector:Create()
    ---@type Repositories
    local repositories = {
        characterRepository = characterRepository,
        professionRepository = ProfessionRepository:Create(LibCraftingProfessions),
        craftRepository = CraftRepository:Create(self.database, characterRepository, LibCrafts, specializationDetector)
    }

    self.uiManager = UIManager:Create(addonInfo, repositories, L, libraries)

    LibCraftingProfessions:RegisterEvent("LCP_SKILLS_UPDATE", function(profession, skills)
        local skillNames = {}
        local resultItemIds = {}
        local seenResultItemIds = {}
        for _, skill in ipairs(skills) do
            tinsert(skillNames, skill.localized_name)

            -- The live profession API gives us the crafted item's link. Keep
            -- its item ID as a language/punctuation-independent identity for
            -- known crafts. This is especially important for Turtle Survival,
            -- where the client uses typographic apostrophes in some names.
            if type(skill.item_link) == "string" then
                local _, _, itemIdText = strfind(skill.item_link, "item:(%d+)")
                local itemId = tonumber(itemIdText)
                if itemId ~= nil and seenResultItemIds[itemId] == nil then
                    seenResultItemIds[itemId] = true
                    tinsert(resultItemIds, itemId)
                end
            end
        end
        local specialization = specializationDetector:DetectPlayerProfessionSpecialization(profession.english_name, skills)
        self.database:SaveCurrentPlayerSkills(profession.localized_name, profession.cur_rank, skillNames, resultItemIds, specialization)

        local playerProfessions = LibCraftingProfessions:GetPlayerProfessions()
        if playerProfessions ~= nil then
            local playerProfessionNames = {}
            for _, playerProfession in ipairs(playerProfessions or {}) do
                tinsert(playerProfessionNames, playerProfession.localized_name)
            end
            self.database:SaveCurrentPlayerProfessions(playerProfessionNames)
        end

        self.uiManager:OnDataUpdated(profession.localized_name)
    end)

    LibCraftingProfessions:RegisterEvent("LCP_FRAME_SHOW", function(profession, frame, frameType)
        self.uiManager:OnProfessionFrameOpened(profession.localized_name, frame, frameType)
    end)

    LibCraftingProfessions:RegisterEvent("LCP_FRAME_CLOSE", function(frame, frameType)
        self.uiManager:OnProfessionFrameClosed(frame, frameType)
    end)
end
