--[[
	PlotManager.lua
	ServerScriptService > PlotManager (Script)

	Manages tycoon plots for AI Empire Tycoon.
	Responsibilities:
	  - Tracks which plots are free and which are claimed
	  - Assigns an unclaimed plot to each player when they join
	  - Listens for players stepping on the "claim pad" of an unclaimed plot
	  - Releases a plot when the player who owns it leaves
	  - Provides a public API for other scripts to query plot ownership

	PLOT STRUCTURE (expected in Workspace > Plots > Plot_1 ... Plot_10):
	  Plot_N (Model or Folder)
	    ├── Baseplate        (Part)   – the main floor
	    ├── ClaimPad         (Part)   – glowing pad players step on to claim
	    ├── ClaimLabel       (BillboardGui inside ClaimPad)  – shows "Unclaimed" / owner name
	    ├── OfficeArea       (Folder) – where office models are spawned
	    ├── EmployeeArea     (Folder) – where employee NPCs walk
	    └── LuxuryArea       (Folder) – where luxury items are placed

	If the Plots folder / plot models don't exist yet, this script will
	procedurally create placeholder baseplates so the game still runs in Studio.
]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local GameConfig = require(game.ReplicatedStorage.GameConfig)

-- ─────────────────────────────────────────────
--  STATE
-- ─────────────────────────────────────────────
-- plotOwners[plotIndex] = player  (nil = unclaimed)
local plotOwners = {}

-- playerPlot[player] = plotIndex  (nil = no plot yet)
local playerPlot = {}

-- ─────────────────────────────────────────────
--  ENSURE PLOTS FOLDER EXISTS
--  Creates procedural fallback plots if none were hand-built in Studio.
-- ─────────────────────────────────────────────
local function ensurePlotsFolder()
	local workspace = game.Workspace
	local plotsFolder = workspace:FindFirstChild("Plots")

	if not plotsFolder then
		plotsFolder = Instance.new("Folder")
		plotsFolder.Name   = "Plots"
		plotsFolder.Parent = workspace
		print("[PlotManager] Created Plots folder in Workspace.")
	end

	-- Check how many plots currently exist
	local existingCount = #plotsFolder:GetChildren()
	local needed        = GameConfig.Plots.totalPlots

	if existingCount < needed then
		print(string.format("[PlotManager] Only %d plots found, generating %d procedural placeholder plots.",
			existingCount, needed - existingCount))

		local plotSize    = GameConfig.Plots.plotSize
		local spacing     = GameConfig.Plots.plotSpacing
		local plotsPerRow = 5

		for i = existingCount + 1, needed do
			local row = math.ceil(i / plotsPerRow) - 1
			local col = (i - 1) % plotsPerRow

			local originX = col * spacing - ((plotsPerRow - 1) * spacing / 2)
			local originZ = row * spacing

			-- Root model
			local plotModel = Instance.new("Model")
			plotModel.Name  = "Plot_" .. i
			plotModel.Parent = plotsFolder

			-- Baseplate
			local base = Instance.new("Part")
			base.Name      = "Baseplate"
			base.Size      = plotSize
			base.Position  = Vector3.new(originX, 0, originZ)
			base.Anchored  = true
			base.BrickColor = BrickColor.new("Medium stone grey")
			base.Material  = Enum.Material.SmoothPlastic
			base.TopSurface = Enum.SurfaceType.Smooth
			base.Parent    = plotModel

			-- Office area marker
			local officeArea = Instance.new("Folder")
			officeArea.Name   = "OfficeArea"
			officeArea.Parent = plotModel

			-- Employee area marker
			local employeeArea = Instance.new("Folder")
			employeeArea.Name   = "EmployeeArea"
			employeeArea.Parent = plotModel

			-- Luxury area marker
			local luxuryArea = Instance.new("Folder")
			luxuryArea.Name   = "LuxuryArea"
			luxuryArea.Parent = plotModel

			-- Claim pad
			local claimPad = Instance.new("Part")
			claimPad.Name      = "ClaimPad"
			claimPad.Size      = GameConfig.Plots.claimPadSize
			claimPad.Position  = Vector3.new(originX, 1, originZ - (plotSize.Z / 2) + 10)
			claimPad.Anchored  = true
			claimPad.BrickColor = BrickColor.new("Bright green")
			claimPad.Material  = Enum.Material.Neon
			claimPad.TopSurface = Enum.SurfaceType.Smooth
			claimPad.Parent    = plotModel

			-- Billboard label on claim pad
			local billboard = Instance.new("BillboardGui")
			billboard.Name         = "ClaimLabel"
			billboard.Size         = UDim2.new(0, 160, 0, 50)
			billboard.StudsOffset  = Vector3.new(0, 4, 0)
			billboard.AlwaysOnTop  = false
			billboard.Parent       = claimPad

			local label = Instance.new("TextLabel")
			label.Size            = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text            = "⬛ UNCLAIMED\nStep here to claim!"
			label.TextColor3      = Color3.fromRGB(255, 255, 255)
			label.TextScaled      = true
			label.Font            = Enum.Font.GothamBold
			label.Parent          = billboard

			-- Boundary wall (thin, decorative, just marks the plot edge)
			local function makeBorderWall(name, size, pos)
				local wall = Instance.new("Part")
				wall.Name      = name
				wall.Size      = size
				wall.Position  = pos
				wall.Anchored  = true
				wall.BrickColor = BrickColor.new("Dark stone grey")
				wall.Material  = Enum.Material.SmoothPlastic
				wall.CanCollide = true
				wall.TopSurface = Enum.SurfaceType.Smooth
				wall.Parent    = plotModel
			end

			local hw = plotSize.X / 2  -- half width
			local hd = plotSize.Z / 2  -- half depth
			local wallH = 3  -- wall height in studs
			local wallT = 1  -- wall thickness

			makeBorderWall("WallNorth", Vector3.new(plotSize.X, wallH, wallT),
				Vector3.new(originX, wallH / 2, originZ - hd))
			makeBorderWall("WallSouth", Vector3.new(plotSize.X, wallH, wallT),
				Vector3.new(originX, wallH / 2, originZ + hd))
			makeBorderWall("WallEast",  Vector3.new(wallT, wallH, plotSize.Z),
				Vector3.new(originX + hw, wallH / 2, originZ))
			makeBorderWall("WallWest",  Vector3.new(wallT, wallH, plotSize.Z),
				Vector3.new(originX - hw, wallH / 2, originZ))

			-- Store origin CFrame on the model as an attribute for easy lookup
			plotModel:SetAttribute("OriginX", originX)
			plotModel:SetAttribute("OriginZ", originZ)
		end
	end

	return plotsFolder
end

-- ─────────────────────────────────────────────
--  GET PLOT MODEL BY INDEX
-- ─────────────────────────────────────────────
local function getPlotModel(index)
	local plotsFolder = game.Workspace:FindFirstChild("Plots")
	if not plotsFolder then return nil end
	return plotsFolder:FindFirstChild("Plot_" .. index)
end

-- ─────────────────────────────────────────────
--  GET PLOT ORIGIN  (world position of plot centre)
-- ─────────────────────────────────────────────
local function getPlotOrigin(index)
	local model = getPlotModel(index)
	if not model then return Vector3.new(0, 0, 0) end
	local base = model:FindFirstChild("Baseplate")
	if base then
		return base.Position
	end
	-- Fallback to stored attributes
	local ox = model:GetAttribute("OriginX") or 0
	local oz = model:GetAttribute("OriginZ") or 0
	return Vector3.new(ox, 0, oz)
end

-- ─────────────────────────────────────────────
--  UPDATE CLAIM PAD APPEARANCE
-- ─────────────────────────────────────────────
local function updateClaimPad(plotIndex, owner)
	local model = getPlotModel(plotIndex)
	if not model then return end

	local claimPad = model:FindFirstChild("ClaimPad")
	if not claimPad then return end

	local billboard = claimPad:FindFirstChild("ClaimLabel")
	local label     = billboard and billboard:FindFirstChildOfClass("TextLabel")

	if owner then
		claimPad.BrickColor = BrickColor.new("Bright red")
		claimPad.Material   = Enum.Material.SmoothPlastic
		if label then
			label.Text = "🏢 " .. owner.Name .. "'s Empire"
		end
	else
		claimPad.BrickColor = BrickColor.new("Bright green")
		claimPad.Material   = Enum.Material.Neon
		if label then
			label.Text = "⬛ UNCLAIMED\nStep here to claim!"
		end
	end
end

-- ─────────────────────────────────────────────
--  ASSIGN PLOT TO PLAYER
-- ─────────────────────────────────────────────
local function assignPlot(player)
	if playerPlot[player] then
		-- Already has a plot
		return playerPlot[player]
	end

	-- Find the first unclaimed plot
	for i = 1, GameConfig.Plots.totalPlots do
		if not plotOwners[i] then
			plotOwners[i]    = player
			playerPlot[player] = i
			updateClaimPad(i, player)

			-- Teleport player to their plot
			local character = player.Character or player.CharacterAdded:Wait()
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				local origin = getPlotOrigin(i)
				humanoidRootPart.CFrame = CFrame.new(origin + Vector3.new(0, 5, -80))
			end

			-- Store plot index in player data
			if _G.DataManager then
				_G.DataManager.SetField(player, "PlotIndex", i)
			end

			print(string.format("[PlotManager] Assigned Plot_%d to %s.", i, player.Name))

			-- Notify other systems
			local remotes = game.ReplicatedStorage:FindFirstChild("RemoteEvents")
			if remotes then
				local plotAssigned = remotes:FindFirstChild("PlotAssigned")
				if plotAssigned then
					plotAssigned:FireClient(player, i, getPlotOrigin(i))
				end
			end

			return i
		end
	end

	warn(string.format("[PlotManager] No free plots for %s! All %d plots are claimed.",
		player.Name, GameConfig.Plots.totalPlots))
	return nil
end

-- ─────────────────────────────────────────────
--  RELEASE A PLAYER'S PLOT
-- ─────────────────────────────────────────────
local function releasePlot(player)
	local index = playerPlot[player]
	if index then
		plotOwners[index]  = nil
		playerPlot[player] = nil
		updateClaimPad(index, nil)
		print(string.format("[PlotManager] Released Plot_%d from %s.", index, player.Name))
	end
end

-- ─────────────────────────────────────────────
--  CLAIM PAD TOUCH DETECTION
--  Players can walk onto an unclaimed pad to claim it.
--  (Auto-assignment on join is the primary method; this is a fallback.)
-- ─────────────────────────────────────────────
local function setupClaimPadTouches(plotsFolder)
	for i = 1, GameConfig.Plots.totalPlots do
		local model    = plotsFolder:FindFirstChild("Plot_" .. i)
		if not model then continue end

		local claimPad = model:FindFirstChild("ClaimPad")
		if not claimPad then continue end

		-- Track debounce per part touch so we don't fire 10x per second
		local debounce = false

		claimPad.Touched:Connect(function(hit)
			if debounce then return end

			-- Only react to character limbs
			local character = hit:FindFirstAncestorOfClass("Model")
			if not character then return end

			local player = Players:GetPlayerFromCharacter(character)
			if not player then return end

			-- Plot is already claimed
			if plotOwners[i] then return end

			-- Player already has a plot
			if playerPlot[player] then return end

			debounce = true
			assignPlot(player)
			task.wait(1)
			debounce = false
		end)
	end
end

-- ─────────────────────────────────────────────
--  PLAYER EVENTS
-- ─────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	-- Wait for character to load so we can teleport them
	player.CharacterAdded:Connect(function()
		task.wait(0.5)  -- brief wait for physics to settle
		if not playerPlot[player] then
			assignPlot(player)
		else
			-- Re-teleport on respawn to their own plot
			local character = player.Character
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local origin = getPlotOrigin(playerPlot[player])
				hrp.CFrame = CFrame.new(origin + Vector3.new(0, 5, -80))
			end
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	releasePlot(player)
end)

-- ─────────────────────────────────────────────
--  INITIALISE
-- ─────────────────────────────────────────────
local plotsFolder = ensurePlotsFolder()
setupClaimPadTouches(plotsFolder)

-- Assign plots to anyone already in game (Studio play testing)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		if player.Character then
			task.wait(0.5)
			assignPlot(player)
		else
			player.CharacterAdded:Wait()
			task.wait(0.5)
			assignPlot(player)
		end
	end)
end

-- ─────────────────────────────────────────────
--  PUBLIC API
-- ─────────────────────────────────────────────
_G.PlotManager = {
	GetPlotIndex  = function(player) return playerPlot[player] end,
	GetPlotOrigin = getPlotOrigin,
	GetPlotModel  = getPlotModel,
	GetPlotOwner  = function(index) return plotOwners[index] end,
	AssignPlot    = assignPlot,
	ReleasePlot   = releasePlot,
}
