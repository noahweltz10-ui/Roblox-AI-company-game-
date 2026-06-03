--[[
	LuxuryConfig.lua
	ReplicatedStorage > LuxuryConfig (ModuleScript)

	All luxury item definitions for AI Empire Tycoon.
	Each entry describes a purchasable status-symbol that physically spawns on the player's plot.

	Fields per item:
	  id          – unique string key used in DataStore and RemoteEvents
	  name        – display name in shop
	  description – flavour text shown in shop
	  price       – cost in cash
	  category    – "Vehicles" | "Watercraft" | "Aircraft" | "Property" | "Exotic"
	  rarity      – auto-derived at runtime from GameConfig.Rarity, but stored here for convenience
	  modelSearch – suggested free Roblox Toolbox search term (no official IDs — use Toolbox search)
	  spawnOffset – Vector3 offset from plot origin where the model will be placed
	              – (the PlotManager lays these out in a grid; this is a hint for manual fine-tuning)
]]

local LuxuryConfig = {}

LuxuryConfig.Items = {

	-- ═══════════════════════════════════════
	--  GROUND VEHICLES
	-- ═══════════════════════════════════════

	{
		id          = "SportsCar",
		name        = "Sports Car",
		description = "Ferrari-inspired red supercar. Goes 0–60 in 2.9 seconds. You won't actually drive it.",
		price       = 50000,
		category    = "Vehicles",
		rarity      = "Common",
		imageId     = "rbxthumb://type=Asset&id=166834188&w=420&h=420",   -- Ferrari LaFerrari decal (roblox.com/library/166834188)
		modelSearch = "ferrari sports car roblox low poly",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "LuxurySalon",
		name        = "Luxury Sedan",
		description = "Blacked-out Rolls Royce-style. The kind of car CEOs are seen getting out of.",
		price       = 75000,
		category    = "Vehicles",
		rarity      = "Common",
		imageId     = "rbxthumb://type=Asset&id=139943722&w=420&h=420",   -- Car Dashboard decal (roblox.com/library/139943722)
		modelSearch = "rolls royce luxury sedan roblox",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "Supercar",
		name        = "Supercar",
		description = "Lamborghini-style with scissor doors that actually open. Pure theatre.",
		price       = 150000,
		category    = "Vehicles",
		rarity      = "Common",
		imageId     = "rbxthumb://type=Asset&id=82575828&w=420&h=420",    -- Transparent Lamborghini Logo (roblox.com/library/82575828)
		modelSearch = "lamborghini supercar roblox scissor doors",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "MonsterTruck",
		name        = "Monster Truck",
		description = "Giant lifted truck with wheels taller than your employees.",
		price       = 200000,
		category    = "Vehicles",
		rarity      = "Common",
		imageId     = "rbxthumb://type=Asset&id=152351441&w=420&h=420",   -- Monster truck decals 2 (roblox.com/library/152351441)
		modelSearch = "monster truck roblox big wheels",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "ArmoredSUV",
		name        = "Armored SUV",
		description = "Bulletproof black SUV with tinted windows. For when you have haters.",
		price       = 250000,
		category    = "Vehicles",
		rarity      = "Common",
		imageId     = "rbxthumb://type=Asset&id=31658064&w=420&h=420",    -- Car grill decal (roblox.com/library/31658064)
		modelSearch = "armored SUV black roblox",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "Hypercar",
		name        = "Hypercar",
		description = "Ultra-rare Bugatti-style with a W16 badge. Only 40 exist in the world.",
		price       = 500000,
		category    = "Vehicles",
		rarity      = "Rare",
		imageId     = "rbxthumb://type=Asset&id=127985198&w=420&h=420",   -- Bugatti exhaust decal (roblox.com/library/127985198)
		modelSearch = "bugatti hypercar roblox W16",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "GoldPlatedCar",
		name        = "Gold Plated Car",
		description = "A supercar entirely clad in 24-karat gold. Subtle is overrated.",
		price       = 750000,
		category    = "Vehicles",
		rarity      = "Rare",
		imageId     = "rbxthumb://type=Asset&id=224362111&w=420&h=420",   -- Chrome 2014 Ferrari LaFerrari (roblox.com/library/224362111)
		modelSearch = "gold plated car roblox supercar",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "F1Car",
		name        = "Formula 1 Car",
		description = "Full F1 race car with sponsor livery. Because you sponsored the whole team.",
		price       = 1000000,
		category    = "Vehicles",
		rarity      = "Rare",
		imageId     = "rbxthumb://type=Asset&id=1035995316&w=420&h=420",  -- Bugatti Chiron decal (roblox.com/library/1035995316)
		modelSearch = "formula 1 F1 race car roblox",
		spawnOffset = Vector3.new(0, 0, 0),
	},

	-- ═══════════════════════════════════════
	--  WATERCRAFT
	-- ═══════════════════════════════════════

	{
		id          = "JetSki",
		name        = "Jet Ski",
		description = "Sporty personal watercraft. Perfect for stress relief after board meetings.",
		price       = 75000,
		category    = "Watercraft",
		rarity      = "Common",
		imageId     = "rbxthumb://type=Asset&id=45041869&w=420&h=420",    -- US Navy Air Force Decal / water vehicle (roblox.com/library/45041869)
		modelSearch = "jet ski roblox watercraft",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "Speedboat",
		name        = "Speedboat",
		description = "Sleek white and chrome speedboat. Impresses clients and coastguards alike.",
		price       = 100000,
		category    = "Watercraft",
		rarity      = "Common",
		imageId     = "rbxthumb://type=Asset&id=42365605&w=420&h=420",    -- Boat asset (create.roblox.com/store/asset/42365605)
		modelSearch = "speedboat roblox white chrome",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "SailingYacht",
		name        = "Sailing Yacht",
		description = "Classic wooden tall-mast sailing yacht. Old money energy.",
		price       = 400000,
		category    = "Watercraft",
		rarity      = "Common",
		imageId     = "rbxthumb://type=Asset&id=20379895&w=420&h=420",    -- Space Decal 2 / nautical scene (roblox.com/library/20379895)
		modelSearch = "sailing yacht roblox tall mast wooden",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "Yacht",
		name        = "Yacht",
		description = "Large luxury white yacht with a helipad on top. Your weekend getaway.",
		price       = 500000,
		category    = "Watercraft",
		rarity      = "Rare",
		imageId     = "rbxthumb://type=Asset&id=63267323&w=420&h=420",    -- URSC space/nautical decal (roblox.com/library/63267323)
		modelSearch = "luxury yacht roblox white helipad",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "Hovercraft",
		name        = "Hovercraft",
		description = "Futuristic military-style hovercraft. Land or sea — irrelevant to you.",
		price       = 750000,
		category    = "Watercraft",
		rarity      = "Rare",
		imageId     = "rbxthumb://type=Asset&id=61489891&w=420&h=420",    -- Roblox car decal hood / vehicle (roblox.com/library/61489891)
		modelSearch = "military hovercraft roblox futuristic",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "MegaYacht",
		name        = "Mega Yacht",
		description = "Enormous multi-deck yacht with a pool, helipad, and two submarines on board.",
		price       = 2000000,
		category    = "Watercraft",
		rarity      = "Rare",
		imageId     = "rbxthumb://type=Asset&id=154835815&w=420&h=420",   -- Generic decal (create.roblox.com/store/asset/154835815)
		modelSearch = "mega yacht roblox multi deck pool",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "Submarine",
		name        = "Submarine",
		description = "Private black submarine. When a yacht just isn't private enough.",
		price       = 3000000,
		category    = "Watercraft",
		rarity      = "Epic",
		imageId     = "rbxthumb://type=Asset&id=2753842&w=420&h=420",     -- Soviet Red Army Star / military insignia (roblox.com/library/2753842)
		modelSearch = "submarine roblox private black",
		spawnOffset = Vector3.new(0, 0, 0),
	},

	-- ═══════════════════════════════════════
	--  AIRCRAFT
	-- ═══════════════════════════════════════

	{
		id          = "HotAirBalloon",
		name        = "Hot Air Balloon",
		description = "Colorful luxury balloon with a champagne basket. The gentlest flex.",
		price       = 250000,
		category    = "Aircraft",
		rarity      = "Common",
		imageId     = "rbxthumb://type=Asset&id=461556354&w=420&h=420",   -- Team Rocket's Hot Air Balloon (roblox.com/library/461556354)
		modelSearch = "hot air balloon roblox colorful",
		spawnOffset = Vector3.new(0, 20, 0),  -- floats above plot
	},
	{
		id          = "Helicopter",
		name        = "Helicopter",
		description = "Black executive helicopter with gold trim. Lands on the rooftop.",
		price       = 1000000,
		category    = "Aircraft",
		rarity      = "Rare",
		imageId     = "rbxthumb://type=Asset&id=468461226&w=420&h=420",   -- The Plaza Helicopter decal (roblox.com/library/468461226)
		modelSearch = "executive helicopter roblox black gold",
		spawnOffset = Vector3.new(0, 5, 0),
	},
	{
		id          = "Seaplane",
		name        = "Seaplane",
		description = "Floatplane that can land on water. Handles both your island and your lake house.",
		price       = 1500000,
		category    = "Aircraft",
		rarity      = "Rare",
		imageId     = "rbxthumb://type=Asset&id=408380370&w=420&h=420",   -- Embraer Private Jet Plane (roblox.com/library/408380370)
		modelSearch = "seaplane floatplane roblox",
		spawnOffset = Vector3.new(0, 3, 0),
	},
	{
		id          = "PrivateJet",
		name        = "Private Jet",
		description = "Sleek white Gulfstream-style jet. No more first class — you ARE the class.",
		price       = 2000000,
		category    = "Aircraft",
		rarity      = "Rare",
		imageId     = "rbxthumb://type=Asset&id=408380370&w=420&h=420",   -- Embraer Private Jet Plane (roblox.com/library/408380370)
		modelSearch = "private jet gulfstream roblox white",
		spawnOffset = Vector3.new(0, 3, 0),
	},
	{
		id          = "Blimp",
		name        = "Blimp",
		description = "Giant personal blimp with your company logo on the side. Unmissable.",
		price       = 3000000,
		category    = "Aircraft",
		rarity      = "Epic",
		imageId     = "rbxthumb://type=Asset&id=681762700&w=420&h=420",   -- FREE HELICOPTER RIDE / large aircraft (roblox.com/library/681762700)
		modelSearch = "blimp airship roblox large",
		spawnOffset = Vector3.new(0, 40, 0),  -- high float above plot
	},
	{
		id          = "TiltrotorAircraft",
		name        = "Tiltrotor Aircraft",
		description = "V-22 Osprey-style — rotors tilt between helicopter and plane mode. Why pick one?",
		price       = 4000000,
		category    = "Aircraft",
		rarity      = "Epic",
		imageId     = "rbxthumb://type=Asset&id=652877584&w=420&h=420",   -- Helicopter Enemy model decal (roblox.com/library/652877584)
		modelSearch = "osprey tiltrotor V22 roblox aircraft",
		spawnOffset = Vector3.new(0, 5, 0),
	},
	{
		id          = "SupersonicJet",
		name        = "Supersonic Jet",
		description = "Concorde-style ultra-fast private jet. You land before you take off (almost).",
		price       = 5000000,
		category    = "Aircraft",
		rarity      = "Epic",
		imageId     = "rbxthumb://type=Asset&id=21755602&w=420&h=420",    -- Space pictures / high-speed aircraft (roblox.com/library/21755602)
		modelSearch = "concorde supersonic jet roblox",
		spawnOffset = Vector3.new(0, 3, 0),
	},
	{
		id          = "MilitaryFighterJet",
		name        = "Military Fighter Jet",
		description = "F-22-style stealth fighter. Technically for 'personal security'.",
		price       = 7500000,
		category    = "Aircraft",
		rarity      = "Epic",
		imageId     = "rbxthumb://type=Asset&id=32870055&w=420&h=420",    -- M.T.F Decal / military insignia (roblox.com/library/32870055)
		modelSearch = "F22 stealth fighter jet roblox military",
		spawnOffset = Vector3.new(0, 3, 0),
	},
	{
		id          = "SpaceRocket",
		name        = "Space Rocket",
		description = "SpaceX-style reusable rocket on a launchpad. You're not just in the game — you're leaving the planet.",
		price       = 50000000,
		category    = "Aircraft",
		rarity      = "Legendary",
		imageId     = "rbxthumb://type=Asset&id=50269520&w=420&h=420",    -- Space Rocket (create.roblox.com/store/asset/50269520)
		modelSearch = "spacex rocket launchpad roblox",
		spawnOffset = Vector3.new(0, 0, 0),
	},

	-- ═══════════════════════════════════════
	--  REAL ESTATE & PROPERTY
	-- ═══════════════════════════════════════

	{
		id          = "BeachHouse",
		name        = "Beach House",
		description = "Modern glass beach house on stilts. Ocean views, no neighbours.",
		price       = 2500000,
		category    = "Property",
		rarity      = "Rare",
		imageId     = "rbxthumb://type=Asset&id=250156628&w=420&h=420",   -- A Weird Decal House / beach house (roblox.com/library/250156628)
		modelSearch = "modern beach house roblox glass stilts",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "Penthouse",
		name        = "Penthouse",
		description = "Rooftop glass penthouse with a wraparound terrace. The city is your backyard.",
		price       = 3500000,
		category    = "Property",
		rarity      = "Epic",
		imageId     = "rbxthumb://type=Asset&id=2948768&w=420&h=420",     -- Roblox Building Decal D (roblox.com/library/2948768)
		modelSearch = "penthouse rooftop roblox glass terrace",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "UndergroundBunker",
		name        = "Underground Bunker",
		description = "Hidden luxury doomsday bunker. The entrance hatch is visible on your plot — the rest is underground.",
		price       = 4000000,
		category    = "Property",
		rarity      = "Epic",
		imageId     = "rbxthumb://type=Asset&id=317674349&w=420&h=420",   -- Mad Games Map Castle / fortified structure (roblox.com/library/317674349)
		modelSearch = "underground bunker hatch roblox luxury",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "Mansion",
		name        = "Mansion",
		description = "Giant white mansion with columns, a fountain, and a swimming pool.",
		price       = 5000000,
		category    = "Property",
		rarity      = "Epic",
		imageId     = "rbxthumb://type=Asset&id=5539575&w=420&h=420",     -- Roblox Castle / large estate (roblox.com/library/5539575)
		modelSearch = "mansion white columns roblox pool",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "SkiChalet",
		name        = "Ski Chalet",
		description = "Alpine luxury cabin with snow on the roof. For when you need to think big thoughts in a cold place.",
		price       = 6000000,
		category    = "Property",
		rarity      = "Epic",
		imageId     = "rbxthumb://type=Asset&id=46367625&w=420&h=420",    -- Castles go bye bye / alpine structure (roblox.com/library/46367625)
		modelSearch = "ski chalet alpine cabin roblox snow",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "Castle",
		name        = "Castle",
		description = "Medieval stone castle, fully renovated with modern interior and a server room in the dungeon.",
		price       = 8000000,
		category    = "Property",
		rarity      = "Epic",
		imageId     = "rbxthumb://type=Asset&id=2215219927&w=420&h=420",  -- Castle 2 (roblox.com/library/2215219927)
		modelSearch = "medieval castle roblox stone large",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "PrivateIsland",
		name        = "Private Island",
		description = "A small tropical island spawns next to your plot — complete with dock, palm trees, and no extradition.",
		price       = 10000000,
		category    = "Property",
		rarity      = "Legendary",
		imageId     = "rbxthumb://type=Asset&id=63267323&w=420&h=420",    -- URSC decal / ocean/earth from above (roblox.com/library/63267323)
		modelSearch = "private island tropical roblox dock",
		spawnOffset = Vector3.new(120, 0, 0),  -- offset to side of plot
	},
	{
		id          = "SpaceStation",
		name        = "Space Station",
		description = "An orbiting station visible above your plot as a floating model. You've colonised low earth orbit.",
		price       = 100000000,
		category    = "Property",
		rarity      = "Legendary",
		imageId     = "rbxthumb://type=Asset&id=20379895&w=420&h=420",    -- Space Decal 2 / space station scene (roblox.com/library/20379895)
		modelSearch = "space station ISS roblox orbiting",
		spawnOffset = Vector3.new(0, 150, 0),  -- floats high above plot
	},

	-- ═══════════════════════════════════════
	--  EXOTIC & MISCELLANEOUS
	-- ═══════════════════════════════════════

	{
		id          = "GoldThrone",
		name        = "Gold Plated Throne",
		description = "Enormous golden chair. Sits inside your office. For important decisions.",
		price       = 500000,
		category    = "Exotic",
		rarity      = "Rare",
		imageId     = "rbxthumb://type=Asset&id=26060300&w=420&h=420",    -- The Golden Robloxian Statue / golden trophy (roblox.com/library/26060300)
		modelSearch = "gold throne chair roblox large",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "DiamondDesk",
		name        = "Diamond Desk",
		description = "Replaces your office desk with a crystal diamond one. Your spreadsheets have never looked better.",
		price       = 1000000,
		category    = "Exotic",
		rarity      = "Rare",
		imageId     = "rbxthumb://type=Asset&id=415565819&w=420&h=420",   -- Aesthetic Statue / crystal decor (roblox.com/library/415565819)
		modelSearch = "diamond desk crystal roblox office",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "RobotButler",
		name        = "Robot Butler",
		description = "Humanoid robot NPC that follows you around and carries your briefcase.",
		price       = 1500000,
		category    = "Exotic",
		rarity      = "Rare",
		imageId     = "rbxthumb://type=Asset&id=174792017&w=420&h=420",   -- Statue / humanoid figure (roblox.com/library/174792017)
		modelSearch = "robot butler humanoid roblox NPC",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "PetTiger",
		name        = "Pet Tiger",
		description = "Animated tiger NPC that prowls your plot. HR has concerns.",
		price       = 2000000,
		category    = "Exotic",
		rarity      = "Rare",
		imageId     = "rbxthumb://type=Asset&id=147184499&w=420&h=420",   -- Cartoon Tiger :D (roblox.com/library/147184499)
		modelSearch = "pet tiger NPC roblox animated",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "PetLion",
		name        = "Pet Lion",
		description = "Animated lion NPC. More majestic than the tiger. Still not HR-approved.",
		price       = 3000000,
		category    = "Exotic",
		rarity      = "Epic",
		imageId     = "rbxthumb://type=Asset&id=92272104&w=420&h=420",    -- Tribal Lion Decal (roblox.com/library/92272104)
		modelSearch = "pet lion NPC roblox animated",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "VaultRoom",
		name        = "Vault Room",
		description = "A room added to your plot filled with stacked gold bars and cash piles. Scrooge McDuck style.",
		price       = 7500000,
		category    = "Exotic",
		rarity      = "Epic",
		imageId     = "rbxthumb://type=Asset&id=43118538&w=420&h=420",    -- Roblox Golden Statue / gold vault trophy (roblox.com/library/43118538)
		modelSearch = "vault room gold bars cash roblox",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "PetShark",
		name        = "Pet Shark (in Tank)",
		description = "A giant aquarium tank with a live shark swimming inside. For the boardroom.",
		price       = 5000000,
		category    = "Exotic",
		rarity      = "Epic",
		imageId     = "rbxthumb://type=Asset&id=3188232058&w=420&h=420",  -- Manokit tiger-shark (roblox.com/library/3188232058)
		modelSearch = "shark tank aquarium roblox large",
		spawnOffset = Vector3.new(0, 0, 0),
	},
	{
		id          = "GoldStatue",
		name        = "Giant Gold Statue",
		description = "A large golden statue of a generic CEO figure, placed at the entrance to your plot.",
		price       = 10000000,
		category    = "Exotic",
		rarity      = "Legendary",
		imageId     = "rbxthumb://type=Asset&id=392990034&w=420&h=420",   -- Personal Statue / large figurine (roblox.com/library/392990034)
		modelSearch = "gold statue CEO roblox large",
		spawnOffset = Vector3.new(0, 0, -90),  -- near plot entrance
	},
}

-- ─────────────────────────────────────────────
--  CATEGORY LIST  (for shop filter tabs)
-- ─────────────────────────────────────────────
LuxuryConfig.Categories = {
	"All",
	"Vehicles",
	"Watercraft",
	"Aircraft",
	"Property",
	"Exotic",
}

-- ─────────────────────────────────────────────
--  LUXURY SHOWCASE GRID LAYOUT
--  Items are auto-placed on a grid within the luxury area of each plot.
--  spawnOffset in each item overrides this for special cases.
-- ─────────────────────────────────────────────
LuxuryConfig.ShowcaseGrid = {
	columns      = 5,
	cellSize     = 14,    -- studs per cell
	startOffset  = Vector3.new(-32, 0, 30),  -- relative to plot origin
}

-- ─────────────────────────────────────────────
--  HELPER: get rarity for a price
-- ─────────────────────────────────────────────
function LuxuryConfig.GetRarity(price)
	if price < 500000 then
		return "Common",    Color3.fromRGB(255, 255, 255)
	elseif price < 5000000 then
		return "Rare",      Color3.fromRGB(80,  140, 255)
	elseif price < 25000000 then
		return "Epic",      Color3.fromRGB(160,  80, 255)
	else
		return "Legendary", Color3.fromRGB(255, 200,  30)
	end
end

-- ─────────────────────────────────────────────
--  HELPER: get item by id
-- ─────────────────────────────────────────────
function LuxuryConfig.GetItemById(id)
	for _, item in ipairs(LuxuryConfig.Items) do
		if item.id == id then
			return item
		end
	end
	return nil
end

-- ─────────────────────────────────────────────
--  HELPER: get all items in a category
-- ─────────────────────────────────────────────
function LuxuryConfig.GetItemsByCategory(category)
	if category == "All" then
		return LuxuryConfig.Items
	end
	local result = {}
	for _, item in ipairs(LuxuryConfig.Items) do
		if item.category == category then
			table.insert(result, item)
		end
	end
	return result
end

return LuxuryConfig
