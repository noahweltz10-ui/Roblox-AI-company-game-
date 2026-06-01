--[[
	GameConfig.lua
	ReplicatedStorage > GameConfig (ModuleScript)

	Central configuration for AI Empire Tycoon.
	All tunable values live here — change numbers here, they propagate everywhere.
]]

local GameConfig = {}

-- ─────────────────────────────────────────────
--  INCOME RATES  (cash per second per building)
-- ─────────────────────────────────────────────
GameConfig.IncomeRates = {
	["Laptop"]        = 1,
	["Garage Office"] = 10,
	["Startup Office"]= 50,
	["Tech Campus"]   = 200,
	["Skyscraper HQ"] = 500,
	["Global HQ"]     = 1000,
}

-- ─────────────────────────────────────────────
--  OFFICE UPGRADES  (ordered progression)
-- ─────────────────────────────────────────────
GameConfig.OfficeUpgrades = {
	{
		id          = "Laptop",
		name        = "Laptop",
		description = "Your humble beginning. A single laptop on a fold-out table.",
		price       = 0,
		incomeRate  = 1,
		imageId     = "rbxassetid://6277375466",  -- Laptop / computer icon (Roblox catalog)
		order       = 1,
	},
	{
		id          = "Garage Office",
		name        = "Garage Office",
		description = "Moved out of your bedroom. The classic startup garage.",
		price       = 500,
		incomeRate  = 10,
		imageId     = "rbxassetid://2948768",     -- Roblox Building Decal D / garage structure (roblox.com/library/2948768)
		order       = 2,
	},
	{
		id          = "Startup Office",
		name        = "Startup Office",
		description = "A real desk, real chairs, and way too much free coffee.",
		price       = 2500,
		incomeRate  = 50,
		imageId     = "rbxassetid://5539575",     -- Roblox Castle / small office building (roblox.com/library/5539575)
		order       = 3,
	},
	{
		id          = "Tech Campus",
		name        = "Tech Campus",
		description = "Ping pong tables, nap pods, and a rooftop garden.",
		price       = 15000,
		incomeRate  = 200,
		imageId     = "rbxassetid://317674349",   -- Mad Games Map / tech campus grounds (roblox.com/library/317674349)
		order       = 4,
	},
	{
		id          = "Skyscraper HQ",
		name        = "Skyscraper HQ",
		description = "Your name is on the building. Literally.",
		price       = 100000,
		incomeRate  = 500,
		imageId     = "rbxassetid://2215219927",  -- Castle 2 / tall structure (roblox.com/library/2215219927)
		order       = 5,
	},
	{
		id          = "Global HQ",
		name        = "Global HQ",
		description = "You're not a startup anymore. You run the world's AI empire.",
		price       = 1000000,
		incomeRate  = 1000,
		imageId     = "rbxassetid://20379895",    -- Space Decal 2 / global scene (roblox.com/library/20379895)
		order       = 6,
	},
}

-- ─────────────────────────────────────────────
--  EMPLOYEES
-- ─────────────────────────────────────────────
GameConfig.Employees = {
	{
		id          = "Junior Dev",
		name        = "Junior Dev",
		description = "Fresh out of bootcamp. Enthusiastic but needs a lot of guidance.",
		price       = 1000,
		incomeBonus = 5,      -- +$5/s
		imageId     = "rbxassetid://174792017",   -- Statue / young developer figure (roblox.com/library/174792017)
		shirtColor  = BrickColor.new("Bright blue"),
		hatColor    = BrickColor.new("White"),
		order       = 1,
	},
	{
		id          = "Senior Dev",
		name        = "Senior Dev",
		description = "10 years of experience. Has opinions about semicolons.",
		price       = 5000,
		incomeBonus = 20,     -- +$20/s
		imageId     = "rbxassetid://392990034",   -- Personal Statue / experienced figure (roblox.com/library/392990034)
		shirtColor  = BrickColor.new("Bright green"),
		hatColor    = BrickColor.new("Dark grey"),
		order       = 2,
	},
	{
		id          = "AI Manager",
		name        = "AI Manager",
		description = "Manages teams AND auto-collects income. Worth every penny.",
		price       = 25000,
		incomeBonus = 100,    -- +$100/s
		imageId     = "rbxassetid://415565819",   -- Aesthetic Statue / tech manager (roblox.com/library/415565819)
		autoCollect = true,
		shirtColor  = BrickColor.new("Bright orange"),
		hatColor    = BrickColor.new("Black"),
		order       = 3,
	},
	{
		id          = "CTO",
		name        = "CTO",
		description = "Chief Technology Officer. Has a standing desk AND a treadmill.",
		price       = 100000,
		incomeBonus = 500,    -- +$500/s
		imageId     = "rbxassetid://43118538",    -- Roblox Golden Statue / prestigious executive (roblox.com/library/43118538)
		shirtColor  = BrickColor.new("Hot pink"),
		hatColor    = BrickColor.new("Gold"),
		order       = 4,
	},
}

-- ─────────────────────────────────────────────
--  REBIRTH SYSTEM
-- ─────────────────────────────────────────────
GameConfig.Rebirth = {
	requiredTotalEarned = 1000000,   -- $1,000,000 total earned to unlock rebirth
	multiplierPerRebirth = 2,        -- each rebirth doubles income (stacks multiplicatively)
}

-- ─────────────────────────────────────────────
--  PLOT SETTINGS
-- ─────────────────────────────────────────────
GameConfig.Plots = {
	totalPlots      = 10,
	plotSize        = Vector3.new(200, 1, 200),   -- baseplate dimensions
	plotSpacing     = 220,                         -- studs between plot centres
	claimPadSize    = Vector3.new(10, 1, 10),
	luxuryAreaSize  = Vector3.new(80, 1, 80),      -- reserved showcase area per plot
}

-- ─────────────────────────────────────────────
--  EMPLOYEE LIMITS
-- ─────────────────────────────────────────────
GameConfig.MaxEmployees = {
	default = 10,
	vip     = 25,
}

-- ─────────────────────────────────────────────
--  INCOME TICK RATE
-- ─────────────────────────────────────────────
GameConfig.IncomeTick     = 1     -- seconds between passive income grants
GameConfig.AutoSaveInterval = 60  -- seconds between auto-saves

-- ─────────────────────────────────────────────
--  LEADERBOARD
-- ─────────────────────────────────────────────
GameConfig.LeaderboardUpdateInterval = 10   -- seconds
GameConfig.LeaderboardMaxEntries     = 10

-- ─────────────────────────────────────────────
--  GAMEPASS / DEVELOPER PRODUCT IDs  (fill in after creating in Creator Dashboard)
-- ─────────────────────────────────────────────
GameConfig.Gamepasses = {
	DoubleIncome    = 0,   -- replace 0 with real gamepass ID
	VIPOffice       = 0,
	ExtraEmployees  = 0,
	AutoCollect     = 0,
}

GameConfig.DeveloperProducts = {
	-- example: Cash1000 = 0,
}

-- ─────────────────────────────────────────────
--  DATASTORE KEY
-- ─────────────────────────────────────────────
GameConfig.DataStoreKey = "AIEmpireTycoon_v1"

-- ─────────────────────────────────────────────
--  RARITY THRESHOLDS  (used by shop UI)
-- ─────────────────────────────────────────────
GameConfig.Rarity = {
	{ name = "Common",    color = Color3.fromRGB(255, 255, 255), maxPrice = 499999    },
	{ name = "Rare",      color = Color3.fromRGB(80,  140, 255), maxPrice = 4999999   },
	{ name = "Epic",      color = Color3.fromRGB(160,  80, 255), maxPrice = 24999999  },
	{ name = "Legendary", color = Color3.fromRGB(255, 200,  30), maxPrice = math.huge },
}

-- ─────────────────────────────────────────────
--  CURRENCY FORMAT THRESHOLDS
-- ─────────────────────────────────────────────
GameConfig.CurrencyFormat = {
	{ threshold = 1e12, suffix = "T" },
	{ threshold = 1e9,  suffix = "B" },
	{ threshold = 1e6,  suffix = "M" },
	{ threshold = 1e3,  suffix = "K" },
}

return GameConfig
