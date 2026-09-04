### v1.5.4 (2026/09/04)
- Added the missing Turtle/Octo Leatherworking recipe Grimtotem Bracers (skill 125), verified against the current client DBC and server data.
- Added Pattern: Grimtotem Bracers (item 70243) as the rare drop recipe source.

### v1.5.3 (2026/08/30)
- Rebuilt Turtle/Octo profession craft data against the current client DBC before using addon references.
- Survival now uses the real client craft spell IDs and DBC reagent lists instead of placeholder IDs.
- Added seven DBC-backed Survival crafts: Simple Wooden Planter, Jungle Remedy, Fisherman's Backpack, Oil-Powered Cooker, Starfeather Arrows, Spirited Precision Sickle, and Prospector’s Magnifying Lens.
- Corrected DBC-confirmed reagent data across Alchemy, Blacksmithing, Cooking, Enchanting, Engineering, Tailoring, Jewelcrafting, Disguise, and Survival.
- Corrected Iron Belt Buckle's client spell name and removed two stale Jewelcrafting entries not associated with Jewelcrafting in the current client DBC.

### v1.5.2 (2026/08/30)
- Fixed the MissingCrafts window jumping to different horizontal positions when switching external profession tabs on scaled Turtle/Octo profession frames.
- Normalize profession-frame and external-tab bounds into UIParent coordinates before calculating placement.
- Tighten side-tab detection and cap tab clearance so unrelated scaled UI buttons cannot push the MissingCrafts frame far across the screen.

### v1.5.1 (2026/08/30)
- Fixed Survival recipes with typographic punctuation being falsely shown as missing even when already learned (for example Simple Herbalist’s Backpack and Skinner’s Pack).
- Known crafts are now matched by crafted item ID as well as a normalized recipe name, making detection more robust across Turtle/Octo UI variants and external profession-tab addons.
- Existing saved data remains compatible; opening a profession once refreshes the stronger item-ID based cache.

### v1.5.0 (2026/08/30)
- Add Turtle/OctoWoW Survival profession support (87 confirmed trainer crafts, skill 1-300; the two unconfirmed skill-295 recipe-item crafts remain omitted)
- Detect the current Jewelcrafting specialization (Goldsmith or Gemology) and hide recipes for the opposite specialization when the client exposes a specialization requirement
- Preserve specialization data per character so character filtering and recipe-item tooltips stay specialization-aware
- Make the MissingCrafts window external-profession-tab aware and avoid overlapping side-mounted profession tabs
- Prefer placing the MissingCrafts window fully outside the profession frame, with automatic left/right fallback on narrow UIs

### v1.4.1 (2025/12/21)
- Update LibCrafts (support latest Turtle localization changes)

### v1.4 (2025/09/09)
- Update LibCrafts (add a lot of Turtle recipes, fix data errors)
- Add very basic support of craft tooltips

### v1.3.3 (2025/09/05)
- Update LibCrafts and LibCraftingProfessions (support latest Turtle localization changes, add new alchemy recipes)

### v1.3.2 (2025/08/17)
- Update LibCrafts and LibCraftingProfessions (support latest Turtle localization changes including deDE game client)

### v1.3.1 (2025/08/16)
- Update LibCrafts and LibCraftingProfessions

### v1.3 (2025/08/01)
- Support pfUI

### v1.2.2 (2025/08/01)
- Fix random Ace3 layout-related crashes

### v1.2.1 (2025/07/18)
- Update color scheme to use softer, more readable colors

### v1.2 (2025/06/23)
- Fix broken TradeSkillFrame filters

### v1.1 (2025/06/20)
- Add search field to the UI

### v1.0 (2025/06/17)
- Initial release
