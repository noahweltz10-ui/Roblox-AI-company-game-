# AI Empire Tycoon — Full Studio Setup Guide

This guide walks you through every step needed to get the game running in Roblox Studio from scratch. Follow each section in order.

---

## Prerequisites

- Roblox Studio installed and up to date
- A Roblox account with publishing rights (for DataStore to work, even in Studio)
- In Studio: **File → Game Settings → Security** → enable **Enable Studio Access to API Services** (required for DataStoreService to work during playtesting)

---

## Part 1 — Folder Structure

Create the following structure exactly. Names are case-sensitive.

```
game
├── ReplicatedStorage
│   ├── GameConfig          (ModuleScript)
│   ├── LuxuryConfig        (ModuleScript)
│   ├── ItemModels          (Folder)        ← office and employee models go here
│   └── LuxuryModels        (Folder)        ← luxury item models go here
│       (RemoteEvents folder is auto-created by MainGameScript on run)
│
├── ServerScriptService
│   ├── MainGameScript      (Script)
│   ├── DataManager         (Script)
│   ├── PlotManager         (Script)
│   ├── IncomeManager       (Script)
│   └── LuxuryItemManager   (Script)
│
├── StarterGui
│   ├── MainHUD             (LocalScript)
│   ├── ShopGui             (LocalScript)
│   └── LeaderboardGui      (LocalScript)
│
├── StarterPlayerScripts
│   ├── LocalInputHandler   (LocalScript)
│   └── ShopController      (LocalScript)
│
└── Workspace
    ├── Plots               (Folder)        ← see Part 3
    └── Lobby               (auto-created by MainGameScript, or build manually)
```

---

## Part 2 — Pasting the Scripts

For each file in this repository, find the matching object in Studio and paste the code.

### ModuleScripts (ReplicatedStorage)

| File in repo | Studio object type | Studio location |
|---|---|---|
| `ReplicatedStorage/GameConfig.lua` | ModuleScript | ReplicatedStorage → GameConfig |
| `ReplicatedStorage/LuxuryConfig.lua` | ModuleScript | ReplicatedStorage → LuxuryConfig |

**How to create a ModuleScript:**
1. Right-click `ReplicatedStorage` → Insert Object → `ModuleScript`
2. Rename it to `GameConfig` (or `LuxuryConfig`)
3. Double-click it to open the script editor
4. Select all (Ctrl+A) and paste the file contents

### Server Scripts (ServerScriptService)

All five files are regular **Script** objects (not LocalScript or ModuleScript).

| File in repo | Studio object name |
|---|---|
| `ServerScriptService/MainGameScript.lua` | MainGameScript |
| `ServerScriptService/DataManager.lua` | DataManager |
| `ServerScriptService/PlotManager.lua` | PlotManager |
| `ServerScriptService/IncomeManager.lua` | IncomeManager |
| `ServerScriptService/LuxuryItemManager.lua` | LuxuryItemManager |

**How to create a Script:**
1. Right-click `ServerScriptService` → Insert Object → `Script`
2. Rename and paste as above

> **Script Execution Order Note:**  
> All five server scripts start concurrently. They use `_G.*` polling with timeouts to wait for each other's APIs before proceeding, so execution order does not matter. If you see timeout warnings in the Output window, check that all five scripts are present and named correctly.

### Client LocalScripts (StarterGui)

These are **LocalScript** objects placed directly inside `StarterGui` (not inside a ScreenGui — each script creates its own ScreenGui programmatically).

| File in repo | Studio object name |
|---|---|
| `StarterGui/MainHUD.lua` | MainHUD |
| `StarterGui/ShopGui.lua` | ShopGui |
| `StarterGui/LeaderboardGui.lua` | LeaderboardGui |

**How to create a LocalScript in StarterGui:**
1. Right-click `StarterGui` → Insert Object → `LocalScript`
2. Rename it and paste the file contents

### Client LocalScripts (StarterPlayerScripts)

| File in repo | Studio object name |
|---|---|
| `StarterPlayerScripts/LocalInputHandler.lua` | LocalInputHandler |
| `StarterPlayerScripts/ShopController.lua` | ShopController |

---

## Part 3 — Plot Layout in Workspace

The `PlotManager` script will **automatically generate 10 placeholder plots** at runtime if none exist. This means you can press Play immediately and the game will work.

However, for a polished shipped game you should build real plots by hand. Here is how:

### Option A — Use the Auto-Generated Plots (fastest for testing)

1. Press **Play** in Studio
2. PlotManager will generate `Plot_1` through `Plot_10` under `Workspace → Plots`
3. The game is fully playable immediately

### Option B — Build Custom Plots (recommended for release)

Each plot must be a **Model** (or Folder) named `Plot_1`, `Plot_2`, ... `Plot_10` inside `Workspace → Plots`.

**Required children of each Plot_N model:**

| Object | Type | Purpose |
|---|---|---|
| `Baseplate` | Part | The main floor of the plot |
| `ClaimPad` | Part | Glowing pad — player steps on it to claim |
| `ClaimLabel` | BillboardGui (inside ClaimPad) | Shows owner name or "UNCLAIMED" |
| `OfficeArea` | Folder | Where office upgrade models spawn |
| `EmployeeArea` | Folder | Where employee NPC models walk |
| `LuxuryArea` | Folder | Where luxury items are placed |

**Recommended plot dimensions:**
- Baseplate: `200 × 1 × 200` studs
- Gap between plot centres: `220` studs
- Arrange in a 5×2 grid (5 across, 2 rows)

**Plot layout grid (top-down view):**

```
[Plot_1] [Plot_2] [Plot_3] [Plot_4] [Plot_5]
                   220 studs apart
[Plot_6] [Plot_7] [Plot_8] [Plot_9] [Plot_10]
```

**Claim pad placement:**
- Place `ClaimPad` at the south edge of each plot (front entrance)
- Size: `10 × 1 × 10` studs
- Set BrickColor to `Bright green`, Material to `Neon`
- Add a `BillboardGui` named `ClaimLabel` inside it with a `TextLabel` child

**Luxury showcase area:**
- In each plot, leave the **north-east quadrant** (~80×80 studs) empty for luxury items
- PlotManager places luxury items automatically using the grid defined in `LuxuryConfig.ShowcaseGrid`
- Default grid: 5 columns × auto rows, 14 studs per cell, starting 32 studs west and 30 studs north of plot origin

**Tip:** Build Plot_1 completely, then duplicate it 9 times, rename them, and adjust positions.

---

## Part 4 — Setting Up Models (ItemModels and LuxuryModels)

Without real models the game uses coloured placeholder parts. The game is fully playable with placeholders — add real models progressively.

### Naming Convention

Models **must be named exactly** matching the config `id` field.

**Office / Employee models → `ReplicatedStorage → ItemModels`**

| Config id | Model name in ItemModels |
|---|---|
| `"Laptop"` | `Laptop` |
| `"Garage Office"` | `Garage Office` |
| `"Startup Office"` | `Startup Office` |
| `"Tech Campus"` | `Tech Campus` |
| `"Skyscraper HQ"` | `Skyscraper HQ` |
| `"Global HQ"` | `Global HQ` |
| `"Junior Dev"` | `Junior Dev` |
| `"Senior Dev"` | `Senior Dev` |
| `"AI Manager"` | `AI Manager` |
| `"CTO"` | `CTO` |

**Luxury item models → `ReplicatedStorage → LuxuryModels`**

Each model must be named by the item's `id` (not `name`):

| Display Name | Model id (exact filename) |
|---|---|
| Sports Car | `SportsCar` |
| Luxury Sedan | `LuxurySalon` |
| Supercar | `Supercar` |
| Monster Truck | `MonsterTruck` |
| Armored SUV | `ArmoredSUV` |
| Hypercar | `Hypercar` |
| Gold Plated Car | `GoldPlatedCar` |
| Formula 1 Car | `F1Car` |
| Jet Ski | `JetSki` |
| Speedboat | `Speedboat` |
| Sailing Yacht | `SailingYacht` |
| Yacht | `Yacht` |
| Hovercraft | `Hovercraft` |
| Mega Yacht | `MegaYacht` |
| Submarine | `Submarine` |
| Hot Air Balloon | `HotAirBalloon` |
| Helicopter | `Helicopter` |
| Seaplane | `Seaplane` |
| Private Jet | `PrivateJet` |
| Blimp | `Blimp` |
| Tiltrotor Aircraft | `TiltrotorAircraft` |
| Supersonic Jet | `SupersonicJet` |
| Military Fighter Jet | `MilitaryFighterJet` |
| Space Rocket | `SpaceRocket` |
| Beach House | `BeachHouse` |
| Penthouse | `Penthouse` |
| Underground Bunker | `UndergroundBunker` |
| Mansion | `Mansion` |
| Ski Chalet | `SkiChalet` |
| Castle | `Castle` |
| Private Island | `PrivateIsland` |
| Space Station | `SpaceStation` |
| Gold Plated Throne | `GoldThrone` |
| Diamond Desk | `DiamondDesk` |
| Robot Butler | `RobotButler` |
| Pet Tiger | `PetTiger` |
| Pet Lion | `PetLion` |
| Vault Room | `VaultRoom` |
| Pet Shark (in Tank) | `PetShark` |
| Giant Gold Statue | `GoldStatue` |

### How to Add a Model from the Toolbox

1. In Studio, open the **Toolbox** (View → Toolbox)
2. Search for the model using the search terms in the table below
3. Insert the model into the **Workspace** temporarily
4. Rename the model to the exact id from the table above
5. Set the **PrimaryPart** of the model (select the root part, right-click → Set as PrimaryPart)
6. Anchor all parts: select all descendants, set `Anchored = true`
7. Cut the model (Ctrl+X) and paste it into `ReplicatedStorage → LuxuryModels` (or `ItemModels`)
8. Delete any leftover scripts or LocalScripts inside the model (they won't work from ReplicatedStorage)

---

## Part 5 — Free Toolbox Search Terms

These search terms are suggested starting points for the Roblox Toolbox (Creator Store). Filter by **Models**, sort by **Relevance**. Look for low-poly, well-rated models. Always preview before inserting.

### Office & Employees

| Item | Suggested Toolbox Search |
|---|---|
| Laptop | `laptop computer desk roblox` |
| Garage Office | `garage office startup roblox` |
| Startup Office | `modern office room roblox furniture` |
| Tech Campus | `tech campus office building roblox` |
| Skyscraper HQ | `skyscraper office tower roblox` |
| Global HQ | `corporate headquarters building roblox` |
| Junior Dev | `programmer NPC roblox blue shirt` |
| Senior Dev | `developer NPC roblox character` |
| AI Manager | `manager NPC roblox suit` |
| CTO | `executive NPC roblox boss character` |

### Vehicles

| Item | Suggested Toolbox Search |
|---|---|
| Sports Car | `ferrari sports car roblox red` |
| Luxury Sedan | `rolls royce luxury car roblox black` |
| Supercar | `lamborghini roblox car scissor doors` |
| Monster Truck | `monster truck roblox big wheels` |
| Armored SUV | `armored SUV military roblox black` |
| Hypercar | `bugatti roblox hypercar` |
| Gold Plated Car | `gold car roblox supercar golden` |
| Formula 1 Car | `F1 formula 1 race car roblox` |

### Watercraft

| Item | Suggested Toolbox Search |
|---|---|
| Jet Ski | `jet ski roblox watercraft personal` |
| Speedboat | `speedboat roblox white chrome fast` |
| Sailing Yacht | `sailing yacht roblox tall mast` |
| Yacht | `luxury yacht roblox helipad white` |
| Hovercraft | `hovercraft military roblox` |
| Mega Yacht | `mega yacht roblox large multi deck` |
| Submarine | `submarine roblox private black` |

### Aircraft

| Item | Suggested Toolbox Search |
|---|---|
| Hot Air Balloon | `hot air balloon roblox colorful` |
| Helicopter | `executive helicopter roblox black` |
| Seaplane | `seaplane floatplane roblox water` |
| Private Jet | `private jet gulfstream roblox white` |
| Blimp | `blimp airship roblox large` |
| Tiltrotor Aircraft | `V22 osprey tiltrotor roblox aircraft` |
| Supersonic Jet | `concorde supersonic jet roblox` |
| Military Fighter Jet | `F22 stealth fighter jet roblox` |
| Space Rocket | `spacex rocket launchpad roblox` |

### Property

| Item | Suggested Toolbox Search |
|---|---|
| Beach House | `beach house modern glass roblox stilts` |
| Penthouse | `penthouse rooftop roblox glass` |
| Underground Bunker | `bunker hatch roblox underground` |
| Mansion | `mansion white columns roblox large` |
| Ski Chalet | `ski chalet alpine cabin roblox snow` |
| Castle | `medieval castle stone roblox large` |
| Private Island | `tropical island roblox dock palm trees` |
| Space Station | `space station ISS roblox orbiting` |

### Exotic & Miscellaneous

| Item | Suggested Toolbox Search |
|---|---|
| Gold Plated Throne | `gold throne chair roblox large` |
| Diamond Desk | `diamond crystal desk roblox` |
| Robot Butler | `robot butler humanoid roblox NPC` |
| Pet Tiger | `tiger animal NPC roblox animated` |
| Pet Lion | `lion animal NPC roblox animated` |
| Pet Shark (in Tank) | `shark aquarium tank roblox large` |
| Vault Room | `vault room gold bars roblox` |
| Giant Gold Statue | `gold statue CEO roblox large entrance` |

---

## Part 6 — Luxury Showcase Area

The showcase area is where all purchased luxury items physically appear on a player's plot.

### How It Works

- `LuxuryItemManager` places items on a 5-column grid inside `LuxuryArea` folder
- Grid starts at `LuxuryConfig.ShowcaseGrid.startOffset` relative to plot origin
- Default: 5 columns, 14 studs per cell, starting at `(-32, 0, 30)` from plot centre
- Items with a custom `spawnOffset` in `LuxuryConfig.lua` ignore the grid (e.g. Space Station floats at Y+150)

### Manual Fine-Tuning

To adjust where luxury items appear on your custom-built plots:

1. Open `ReplicatedStorage → LuxuryConfig`
2. Find `LuxuryConfig.ShowcaseGrid` near the bottom
3. Adjust:
   - `columns` — how many items per row (default 5)
   - `cellSize` — spacing in studs between item centres (default 14)
   - `startOffset` — Vector3 offset from plot origin where the grid begins

To move a specific item to a custom position:
1. Find the item in `LuxuryConfig.Items`
2. Set its `spawnOffset = Vector3.new(x, y, z)` (relative to plot origin)
3. Non-zero offsets bypass the auto-grid entirely

### Recommended Showcase Layout

```
Plot (200×200 studs)
┌──────────────────────────────────────────┐
│                                          │
│  [OFFICE AREA]         [LUXURY SHOWCASE] │
│  Centre-north          North-east quad   │
│  ~60×60 studs          ~80×80 studs      │
│                                          │
│  [EMPLOYEE WALKWAY]                      │
│  Centre                                  │
│                                          │
│  ▼ ClaimPad (south edge)                 │
└──────────────────────────────────────────┘
```

---

## Part 7 — Gamepass & Developer Product Setup

The code already has hooks for all monetisation. To activate:

### 2× Income Gamepass
1. Go to Creator Dashboard → your game → Passes → Create
2. Name it "2× Income Boost", set the price
3. Copy the Pass ID
4. Open `ReplicatedStorage → GameConfig`
5. Set `GameConfig.Gamepasses.DoubleIncome = YOUR_PASS_ID`

### VIP Office Gamepass
1. Create a Pass named "VIP Office"
2. Set `GameConfig.Gamepasses.VIPOffice = YOUR_PASS_ID`
3. In `LuxuryItemManager`, add logic to check this pass and spawn a premium office model

### Extra Employee Slots Gamepass
1. Create a Pass named "Extra Employee Slots"
2. Set `GameConfig.Gamepasses.ExtraEmployees = YOUR_PASS_ID`
3. Already wired: `IncomeManager` checks this pass and allows 25 employees instead of 10

### Auto-Collect Gamepass
1. Create a Pass named "Auto-Collect"
2. Set `GameConfig.Gamepasses.AutoCollect = YOUR_PASS_ID`
3. The `AI Manager` employee already grants auto-collect; this pass gives it for free

> **Note:** Gamepass checks use `MarketplaceService:UserOwnsGamePassAsync()` which requires a real game ID. Gamepasses won't work in Studio unless you test via the published game.

---

## Part 8 — DataStore Setup

DataStore requires **API access** to be enabled.

1. In Studio: **File → Game Settings → Security**
2. Toggle **Enable Studio Access to API Services** → ON
3. The DataStore key is `"AIEmpireTycoon_v1"` (set in `GameConfig.DataStoreKey`)
4. To wipe all player data and start fresh (e.g. after a major update), change the version suffix: `"AIEmpireTycoon_v2"`

**What is saved:**
- Cash
- TotalEarned
- RebirthCount
- CurrentOffice (highest tier unlocked)
- OwnedUpgrades (list of upgrade IDs)
- OwnedLuxuryItems (list of luxury item IDs)
- EmployeeCount (table of employee type → quantity)
- HasAutoCollect

**What is NOT saved:**
- PlotIndex (re-assigned fresh each session)

---

## Part 9 — First Playtest Checklist

Run through this list after setting up everything:

- [ ] Press **Play** — no errors appear in the Output window
- [ ] A "Plots" folder appears in Workspace with 10 plot models
- [ ] A "Lobby" area appears with a spawn pad and shop pad
- [ ] "RemoteEvents" folder appears in ReplicatedStorage with 16 events
- [ ] Cash display appears top-right showing `$0`
- [ ] Income ticks up every second (you should see `$1` after 1 second — Laptop tier)
- [ ] Press **E** — the shop opens with the dark navy theme
- [ ] Office tab shows all 6 upgrades; Laptop shows "✓ OWNED"
- [ ] Employees tab shows 4 hirable employees
- [ ] Luxury tab shows all 40+ items in a grid with rarity labels
- [ ] Sub-category filter buttons (All / Vehicles / Watercraft / Aircraft / Property / Exotic) correctly filter items
- [ ] Leaderboard panel appears on the right side
- [ ] Step on the green ClaimPad — it turns red and shows your name
- [ ] Buy "Garage Office" ($500) — a placeholder (or model if added) spawns on your plot
- [ ] Hire a "Junior Dev" — a coloured block appears and wanders on your plot
- [ ] Income increases when you buy an office or hire employees
- [ ] DataStore saves on leave (check Output for "[DataManager] Saved data for...")

---

## Part 10 — Common Issues

**"DataManager not found" or "_G.DataManager is nil"**
- Make sure `DataManager.lua` is a **Script** (not LocalScript) in `ServerScriptService`
- Check the Output window for errors in DataManager on startup

**Shop doesn't open when pressing E**
- Confirm `ShopController.lua` is a **LocalScript** in `StarterPlayerScripts` (not StarterGui)
- Check that `LocalInputHandler.lua` is also in `StarterPlayerScripts`

**Income isn't ticking**
- Confirm `IncomeManager.lua` is a **Script** in `ServerScriptService`
- Confirm `GameConfig.lua` is a **ModuleScript** in `ReplicatedStorage` (not a Script)

**Leaderboard not updating**
- Confirm `LeaderboardGui.lua` is a **LocalScript** in `StarterGui`
- The leaderboard only updates every 10 seconds — wait for the first tick

**Models don't spawn on plots**
- Models in `ItemModels` and `LuxuryModels` must have a `PrimaryPart` set
- All parts in the model must be Anchored
- Model names must match the `id` field exactly (case-sensitive)

**DataStore not saving (Studio)**
- Enable Studio Access to API Services in Game Settings → Security
- DataStore requires the place to be published at least once

**"RemoteEvents" folder not found**
- `MainGameScript.lua` must run before other scripts try to access RemoteEvents
- If it's still missing, check that `MainGameScript.lua` is a **Script** in `ServerScriptService`

---

## Part 11 — Tuning & Customisation

All game balance values are in `ReplicatedStorage → GameConfig`:

| Setting | Location in GameConfig | Default |
|---|---|---|
| Income rates per office | `IncomeRates` table | Laptop=$1/s → GlobalHQ=$1000/s |
| Office prices | `OfficeUpgrades[].price` | $0 → $1,000,000 |
| Employee prices | `Employees[].price` | $1,000 → $100,000 |
| Employee income bonus | `Employees[].incomeBonus` | +$5/s → +$500/s |
| Rebirth threshold | `Rebirth.requiredTotalEarned` | $1,000,000 |
| Rebirth multiplier | `Rebirth.multiplierPerRebirth` | 2 (doubles each rebirth) |
| Income tick rate | `IncomeTick` | 1 second |
| Auto-save interval | `AutoSaveInterval` | 60 seconds |
| Leaderboard update interval | `LeaderboardUpdateInterval` | 10 seconds |
| Max employees (default) | `MaxEmployees.default` | 10 |
| Max employees (VIP) | `MaxEmployees.vip` | 25 |

All luxury item prices and metadata are in `ReplicatedStorage → LuxuryConfig`.
