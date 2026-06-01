--[[
	WorldBuilder.lua
	ServerScriptService > WorldBuilder (Script)

	Handles all world visuals for AI Empire Tycoon:
	  - Replaces the flat baseplate with grass terrain
	  - Adds a running day/night cycle
	  - Sets up atmosphere, lighting, and sky
	  - Adds roads between plots
	  - Adds trees and decorations around the map
	  - Upgrades plot floors (marble office area, stone surroundings)
]]

local Lighting   = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local GameConfig = require(game.ReplicatedStorage:WaitForChild("GameConfig", 30))

-- ─────────────────────────────────────────────
--  LIGHTING SETUP
-- ─────────────────────────────────────────────
local function setupLighting()
	-- Base lighting
	Lighting.Ambient          = Color3.fromRGB(80, 80, 90)
	Lighting.Brightness       = 2
	Lighting.GlobalShadows    = true
	Lighting.ShadowSoftness   = 0.2
	Lighting.ClockTime        = 8  -- start at 8am

	-- Atmosphere for realism
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density    = 0.3
	atmosphere.Offset     = 0.1
	atmosphere.Color      = Color3.fromRGB(199, 170, 140)
	atmosphere.Decay      = Color3.fromRGB(90, 110, 130)
	atmosphere.Glare      = 0.1
	atmosphere.Haze       = 1.5
	atmosphere.Parent     = Lighting

	-- Sky
	local sky = Instance.new("Sky")
	sky.SkyboxBk = "rbxassetid://159454299"
	sky.SkyboxDn = "rbxassetid://159454296"
	sky.SkyboxFt = "rbxassetid://159454293"
	sky.SkyboxLf = "rbxassetid://159454286"
	sky.SkyboxRt = "rbxassetid://159454300"
	sky.SkyboxUp = "rbxassetid://159454302"
	sky.StarCount = 3000
	sky.Parent    = Lighting

	-- Bloom effect
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity  = 0.4
	bloom.Size       = 24
	bloom.Threshold  = 0.95
	bloom.Parent     = Lighting

	-- Color correction for a warm, vibrant look
	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Brightness = 0.02
	colorCorrection.Contrast   = 0.08
	colorCorrection.Saturation = 0.15
	colorCorrection.TintColor  = Color3.fromRGB(255, 248, 240)
	colorCorrection.Parent     = Lighting

	-- Sun rays
	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Intensity = 0.15
	sunRays.Spread    = 0.5
	sunRays.Parent    = Lighting

	print("[WorldBuilder] Lighting setup complete.")
end

-- ─────────────────────────────────────────────
--  DAY CYCLE
--  Smoothly cycles through a full day in 10 real minutes.
-- ─────────────────────────────────────────────
local DAY_LENGTH_SECONDS = 600  -- 10 minutes per full day cycle

local function updateLightingForTime(clockTime)
	-- Adjust ambient and brightness based on time of day
	if clockTime >= 6 and clockTime < 8 then
		-- Dawn: soft orange/pink
		Lighting.Ambient       = Color3.fromRGB(100, 85, 80)
		Lighting.Brightness    = 1.5
		Lighting.OutdoorAmbient = Color3.fromRGB(180, 140, 100)
	elseif clockTime >= 8 and clockTime < 17 then
		-- Daytime: bright and clear
		Lighting.Ambient       = Color3.fromRGB(80, 80, 90)
		Lighting.Brightness    = 2.5
		Lighting.OutdoorAmbient = Color3.fromRGB(160, 170, 190)
	elseif clockTime >= 17 and clockTime < 20 then
		-- Golden hour / sunset
		Lighting.Ambient       = Color3.fromRGB(110, 80, 60)
		Lighting.Brightness    = 1.8
		Lighting.OutdoorAmbient = Color3.fromRGB(200, 130, 80)
	elseif clockTime >= 20 or clockTime < 5 then
		-- Night: dark blue
		Lighting.Ambient       = Color3.fromRGB(30, 35, 60)
		Lighting.Brightness    = 0.5
		Lighting.OutdoorAmbient = Color3.fromRGB(40, 50, 80)
	else
		-- Pre-dawn
		Lighting.Ambient       = Color3.fromRGB(50, 50, 70)
		Lighting.Brightness    = 0.8
		Lighting.OutdoorAmbient = Color3.fromRGB(60, 70, 90)
	end
end

local function startDayCycle()
	task.spawn(function()
		while true do
			task.wait(0.5)
			-- Advance time
			local hoursPerSecond = 24 / DAY_LENGTH_SECONDS
			Lighting.ClockTime = (Lighting.ClockTime + hoursPerSecond * 0.5) % 24
			updateLightingForTime(Lighting.ClockTime)
		end
	end)
	print("[WorldBuilder] Day cycle started.")
end

-- ─────────────────────────────────────────────
--  TERRAIN
--  Replace the flat baseplate with grass terrain.
-- ─────────────────────────────────────────────
local function buildTerrain()
	local terrain = workspace.Terrain

	-- Clear existing terrain
	terrain:Clear()

	local TERRAIN_SIZE  = 1200
	local TERRAIN_DEPTH = 4

	-- Fill the base with grass
	terrain:FillBlock(
		CFrame.new(0, -TERRAIN_DEPTH / 2, 0),
		Vector3.new(TERRAIN_SIZE, TERRAIN_DEPTH, TERRAIN_SIZE),
		Enum.Material.Grass
	)

	-- Add a water area on one side for the watercraft luxury items
	terrain:FillBlock(
		CFrame.new(600, -2, 0),
		Vector3.new(200, 4, 600),
		Enum.Material.Water
	)

	-- Add some dirt paths between plot rows
	local plotsPerRow = 5
	local spacing     = GameConfig.Plots.plotSpacing

	-- Horizontal road between rows
	terrain:FillBlock(
		CFrame.new(0, 0.1, spacing / 2),
		Vector3.new(TERRAIN_SIZE, 1, 20),
		Enum.Material.Pavement
	)

	-- Vertical roads between columns
	for col = 0, plotsPerRow do
		local x = (col * spacing) - ((plotsPerRow - 1) * spacing / 2) - spacing / 2
		terrain:FillBlock(
			CFrame.new(x, 0.1, 0),
			Vector3.new(20, 1, TERRAIN_SIZE),
			Enum.Material.Pavement
		)
	end

	-- Set short grass AFTER all terrain operations so it isn't reset
	terrain.GrassLength        = 0.1
	terrain.Decoration         = true

	print("[WorldBuilder] Terrain built.")
end

-- ─────────────────────────────────────────────
--  REMOVE DEFAULT BASEPLATE
-- ─────────────────────────────────────────────
local function removeBaseplate()
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
		print("[WorldBuilder] Removed default baseplate.")
	end
end

-- ─────────────────────────────────────────────
--  UPGRADE PLOT FLOORS
--  Makes each plot look nicer with marble/stone flooring.
-- ─────────────────────────────────────────────
local function upgradePlotFloors()
	-- Wait for PlotManager to generate plots
	local plotsFolder = workspace:WaitForChild("Plots", 30)
	if not plotsFolder then
		warn("[WorldBuilder] Plots folder not found.")
		return
	end

	-- Wait a moment for all plots to be generated
	task.wait(3)

	for i = 1, GameConfig.Plots.totalPlots do
		local plotModel = plotsFolder:FindFirstChild("Plot_" .. i)
		if not plotModel then continue end

		local baseplate = plotModel:FindFirstChild("Baseplate")
		if not baseplate then continue end

		-- Upgrade baseplate to smooth marble
		baseplate.Material  = Enum.Material.Marble
		baseplate.BrickColor = BrickColor.new("White")
		baseplate.TopSurface = Enum.SurfaceType.Smooth

		-- Add a grass border around the plot
		local plotSize = baseplate.Size
		local plotPos  = baseplate.Position

		local function makeBorder(name, size, offset, color, material)
			local border = Instance.new("Part")
			border.Name       = name
			border.Size       = size
			border.Position   = plotPos + offset
			border.Anchored   = true
			border.BrickColor = color
			border.Material   = material
			border.TopSurface = Enum.SurfaceType.Smooth
			border.CanCollide = true
			border.Parent     = plotModel
		end

		-- Decorative border strips (grass edging)
		local bw = 4  -- border width
		local bh = 0.5
		makeBorder("BorderNorth",
			Vector3.new(plotSize.X + bw*2, bh, bw),
			Vector3.new(0, bh/2, -(plotSize.Z/2 + bw/2)),
			BrickColor.new("Bright green"), Enum.Material.Grass)
		makeBorder("BorderSouth",
			Vector3.new(plotSize.X + bw*2, bh, bw),
			Vector3.new(0, bh/2, plotSize.Z/2 + bw/2),
			BrickColor.new("Bright green"), Enum.Material.Grass)
		makeBorder("BorderEast",
			Vector3.new(bw, bh, plotSize.Z),
			Vector3.new(plotSize.X/2 + bw/2, bh/2, 0),
			BrickColor.new("Bright green"), Enum.Material.Grass)
		makeBorder("BorderWest",
			Vector3.new(bw, bh, plotSize.Z),
			Vector3.new(-(plotSize.X/2 + bw/2), bh/2, 0),
			BrickColor.new("Bright green"), Enum.Material.Grass)

		-- Upgrade walls to glass/metal look
		for _, child in ipairs(plotModel:GetChildren()) do
			if child.Name:find("Wall") and child:IsA("BasePart") then
				child.Material  = Enum.Material.Glass
				child.BrickColor = BrickColor.new("Institutional white")
				child.Transparency = 0.5
			end
		end
	end

	print("[WorldBuilder] Plot floors upgraded.")
end

-- ─────────────────────────────────────────────
--  ADD TREES
--  Places trees around the map for decoration.
-- ─────────────────────────────────────────────
local function addTrees()
	local treeFolder = Instance.new("Folder")
	treeFolder.Name   = "Trees"
	treeFolder.Parent = workspace

	local function makeTree(x, z, scale)
		scale = scale or 1

		local trunk = Instance.new("Part")
		trunk.Name      = "Trunk"
		trunk.Size      = Vector3.new(2*scale, 8*scale, 2*scale)
		trunk.Position  = Vector3.new(x, 4*scale, z)
		trunk.Anchored  = true
		trunk.BrickColor = BrickColor.new("Reddish brown")
		trunk.Material  = Enum.Material.Wood
		trunk.TopSurface = Enum.SurfaceType.Smooth
		trunk.BottomSurface = Enum.SurfaceType.Smooth
		trunk.Parent    = treeFolder

		local leaves = Instance.new("Part")
		leaves.Name     = "Leaves"
		leaves.Shape    = Enum.PartType.Ball
		leaves.Size     = Vector3.new(10*scale, 10*scale, 10*scale)
		leaves.Position = Vector3.new(x, 12*scale, z)
		leaves.Anchored = true
		leaves.BrickColor = BrickColor.new("Bright green")
		leaves.Material = Enum.Material.Grass
		leaves.TopSurface = Enum.SurfaceType.Smooth
		leaves.BottomSurface = Enum.SurfaceType.Smooth
		leaves.Parent   = treeFolder
	end

	-- Place trees around the edges of the map and between plots
	local positions = {
		-- Far edges
		{-500, -400}, {-500, -200}, {-500, 0}, {-500, 200}, {-500, 400},
		{500,  -400}, {500,  -200}, {500,  0}, {500,  200}, {500,  400},
		{-300, -500}, {-100, -500}, {100,  -500}, {300, -500},
		{-300,  500}, {-100,  500}, {100,   500}, {300,  500},
		-- Between plots (corners)
		{-220, -260}, {0, -260}, {220, -260}, {440, -260},
		{-220,  260}, {0,  260}, {220,  260}, {440,  260},
		-- Scattered
		{-380, 150}, {380, -150}, {-380, -150}, {380, 150},
		{-450, 50},  {450, -50},  {-450, -50},  {450, 50},
	}

	for _, pos in ipairs(positions) do
		local scale = 0.8 + math.random() * 0.6
		makeTree(pos[1], pos[2], scale)
	end

	print(string.format("[WorldBuilder] Placed %d trees.", #positions))
end

-- ─────────────────────────────────────────────
--  ADD STREET LIGHTS
--  Bright street lights along every road + glow
--  pads at plot corners for extra night coverage.
-- ─────────────────────────────────────────────
local function addStreetLights()
	local lightFolder = Instance.new("Folder")
	lightFolder.Name   = "StreetLights"
	lightFolder.Parent = workspace

	local function makeStreetLight(x, z)
		local post = Instance.new("Part")
		post.Name        = "Post"
		post.Size        = Vector3.new(1, 16, 1)
		post.Position    = Vector3.new(x, 8, z)
		post.Anchored    = true
		post.BrickColor  = BrickColor.new("Dark stone grey")
		post.Material    = Enum.Material.Metal
		post.TopSurface  = Enum.SurfaceType.Smooth
		post.CastShadow  = false
		post.Parent      = lightFolder

		local arm = Instance.new("Part")
		arm.Name       = "Arm"
		arm.Size       = Vector3.new(4, 0.8, 0.8)
		arm.Position   = Vector3.new(x + 2, 16, z)
		arm.Anchored   = true
		arm.BrickColor = BrickColor.new("Dark stone grey")
		arm.Material   = Enum.Material.Metal
		arm.CastShadow = false
		arm.Parent     = lightFolder

		local bulb = Instance.new("Part")
		bulb.Name      = "Bulb"
		bulb.Size      = Vector3.new(2, 0.8, 2)
		bulb.Position  = Vector3.new(x + 3.5, 15.4, z)
		bulb.Anchored  = true
		bulb.BrickColor = BrickColor.new("Bright yellow")
		bulb.Material  = Enum.Material.Neon
		bulb.CastShadow = false
		bulb.Parent    = lightFolder

		local pointLight = Instance.new("PointLight")
		pointLight.Brightness = 8
		pointLight.Color      = Color3.fromRGB(255, 240, 190)
		pointLight.Range      = 60
		pointLight.Parent     = bulb

		-- Small glow pad on the ground directly below
		local pad = Instance.new("Part")
		pad.Name        = "GlowPad"
		pad.Size        = Vector3.new(6, 0.2, 6)
		pad.Position    = Vector3.new(x + 3.5, 0.1, z)
		pad.Anchored    = true
		pad.BrickColor  = BrickColor.new("Bright yellow")
		pad.Material    = Enum.Material.Neon
		pad.Transparency = 0.85
		pad.CastShadow  = false
		pad.Parent      = lightFolder
	end

	-- Large ambient fill lights hidden in the sky above the map
	-- These give soft blue-white fill so night is never pitch black
	local function makeAmbientLight(x, z)
		local anchor = Instance.new("Part")
		anchor.Size        = Vector3.new(1, 1, 1)
		anchor.Position    = Vector3.new(x, 80, z)
		anchor.Anchored    = true
		anchor.Transparency = 1
		anchor.CanCollide  = false
		anchor.CastShadow  = false
		anchor.Parent      = lightFolder

		local pl = Instance.new("PointLight")
		pl.Brightness = 2
		pl.Color      = Color3.fromRGB(140, 160, 220)
		pl.Range      = 300
		pl.Parent     = anchor
	end

	local spacing = GameConfig.Plots.plotSpacing

	-- Street lights on every road intersection
	for col = -2, 2 do
		local x = col * spacing
		for row = -2, 2 do
			local z = row * spacing
			makeStreetLight(x - spacing / 2, z)
			makeStreetLight(x - spacing / 2, z + spacing / 2)
		end
	end

	-- Ambient fill lights spread across the map
	for _, pos in ipairs({
		{-400, -400}, {0, -400}, {400, -400},
		{-400,    0}, {0,    0}, {400,    0},
		{-400,  400}, {0,  400}, {400,  400},
	}) do
		makeAmbientLight(pos[1], pos[2])
	end

	print("[WorldBuilder] Street lights placed.")
end

-- ─────────────────────────────────────────────
--  BOOT SEQUENCE
-- ─────────────────────────────────────────────
print("[WorldBuilder] Building world...")
setupLighting()
removeBaseplate()
buildTerrain()
upgradePlotFloors()
addTrees()
addStreetLights()
startDayCycle()
print("[WorldBuilder] World build complete.")
