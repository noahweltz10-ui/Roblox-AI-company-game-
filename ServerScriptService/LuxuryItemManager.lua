--[[
	LuxuryItemManager.lua
	ServerScriptService > LuxuryItemManager (Script)

	Manages all physical model spawning/removal on player plots.
	Responsibilities:
	  - Spawning office upgrade models in the OfficeArea of a player's plot
	  - Spawning employee NPC models in the EmployeeArea
	  - Spawning luxury item models in the LuxuryArea on a grid
	  - Clearing all models from a plot (on rebirth)
	  - Falling back to coloured placeholder parts if no real model is found

	MODEL LOCATION:
	  Models should be placed in ReplicatedStorage > ItemModels   (office/employee)
	  and ReplicatedStorage > LuxuryModels   (luxury items).
	  Each model must be named exactly matching the config id:
	    e.g.  ItemModels > "Laptop"
	          ItemModels > "Garage Office"
	          LuxuryModels > "SportsCar"
	  If a model is not found, a placeholder coloured part is spawned instead.

	DEPENDENCIES:
	  _G.DataManager  – from DataManager.lua
	  _G.PlotManager  – from PlotManager.lua
]]

local Players = game:GetService("Players")

local GameConfig   = require(game.ReplicatedStorage.GameConfig)
local LuxuryConfig = require(game.ReplicatedStorage.LuxuryConfig)

-- ─────────────────────────────────────────────
--  WAIT FOR DEPENDENCIES
-- ─────────────────────────────────────────────
local function waitForGlobal(name, timeout)
	timeout = timeout or 10
	local elapsed = 0
	while not _G[name] and elapsed < timeout do
		task.wait(0.1)
		elapsed = elapsed + 0.1
	end
	if not _G[name] then
		error(string.format("[LuxuryItemManager] Timed out waiting for _G.%s", name))
	end
	return _G[name]
end

local DataManager = waitForGlobal("DataManager")
local PlotManager = waitForGlobal("PlotManager")

-- ─────────────────────────────────────────────
--  MODEL REPOSITORIES
-- ─────────────────────────────────────────────
local ItemModels   = game.ReplicatedStorage:WaitForChild("ItemModels",   15)
local LuxuryModels = game.ReplicatedStorage:WaitForChild("LuxuryModels", 15)

-- ─────────────────────────────────────────────
--  RARITY COLOURS  (for placeholder parts)
-- ─────────────────────────────────────────────
local RARITY_COLORS = {
	Common    = BrickColor.new("White"),
	Rare      = BrickColor.new("Bright blue"),
	Epic      = BrickColor.new("Bright violet"),
	Legendary = BrickColor.new("Bright yellow"),
}

-- ─────────────────────────────────────────────
--  HELPERS
-- ─────────────────────────────────────────────

-- Returns the world-space CFrame of the plot's OfficeArea marker,
-- falling back to the baseplate centre if the folder doesn't exist.
local function getAreaCFrame(plotIndex, areaName, yOffset)
	yOffset = yOffset or 0
	local model = PlotManager.GetPlotModel(plotIndex)
	if not model then return CFrame.new(0, yOffset, 0) end

	local area = model:FindFirstChild(areaName)
	if area and area:IsA("BasePart") then
		return area.CFrame + Vector3.new(0, yOffset, 0)
	end

	-- Fall back to baseplate position
	local base = model:FindFirstChild("Baseplate")
	if base then
		return CFrame.new(base.Position + Vector3.new(0, base.Size.Y / 2 + yOffset, 0))
	end

	local origin = PlotManager.GetPlotOrigin(plotIndex)
	return CFrame.new(origin + Vector3.new(0, yOffset, 0))
end

-- Clone a model from a folder, return nil if not found.
local function cloneModel(folder, name)
	if not folder then return nil end
	local template = folder:FindFirstChild(name)
	if template then
		return template:Clone()
	end
	return nil
end

-- Create a placeholder part when no real model exists.
local function makePlaceholder(name, size, color, parent, cframe)
	local part = Instance.new("Part")
	part.Name      = name
	part.Size      = size or Vector3.new(6, 6, 6)
	part.BrickColor = color or BrickColor.new("Medium stone grey")
	part.Material  = Enum.Material.SmoothPlastic
	part.Anchored  = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.CFrame    = cframe or CFrame.new(0, 0, 0)
	part.Parent    = parent

	-- Label on top so it's identifiable in-game
	local billGui = Instance.new("BillboardGui", part)
	billGui.Size = UDim2.new(0, 120, 0, 40)
	billGui.StudsOffset = Vector3.new(0, part.Size.Y / 2 + 2, 0)
	local lbl = Instance.new("TextLabel", billGui)
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = name
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold

	return part
end

-- Anchor all BaseParts in a model and weld them so they don't fall apart.
local function anchorModel(model)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
end

-- Place a model (or placeholder) at a given CFrame.
local function placeModel(modelFolder, id, name, targetCFrame, parentFolder, placeholderColor, placeholderSize)
	local spawned = cloneModel(modelFolder, id)

	if spawned then
		-- If it's a Model, move the PrimaryPart or use SetPrimaryPartCFrame
		if spawned:IsA("Model") then
			anchorModel(spawned)
			if spawned.PrimaryPart then
				spawned:SetPrimaryPartCFrame(targetCFrame)
			else
				-- No PrimaryPart — move the first BasePart we find
				local firstPart = spawned:FindFirstChildOfClass("BasePart")
				if firstPart then
					local offset = targetCFrame.Position - firstPart.Position
					for _, p in ipairs(spawned:GetDescendants()) do
						if p:IsA("BasePart") then
							p.Position = p.Position + offset
						end
					end
				end
			end
		elseif spawned:IsA("BasePart") then
			spawned.Anchored = true
			spawned.CFrame   = targetCFrame
		end
		spawned.Name   = id
		spawned.Parent = parentFolder
	else
		-- No model found — make a coloured placeholder
		makePlaceholder(name, placeholderSize, placeholderColor, parentFolder, targetCFrame)
	end

	return spawned
end

-- ─────────────────────────────────────────────
--  SPAWN OFFICE MODEL
-- ─────────────────────────────────────────────
local function spawnOffice(player, upgradeId)
	local plotIndex = PlotManager.GetPlotIndex(player)
	if not plotIndex then
		warn("[LuxuryItemManager] No plot for " .. player.Name)
		return
	end

	local model = PlotManager.GetPlotModel(plotIndex)
	if not model then return end

	local officeArea = model:FindFirstChild("OfficeArea")
	if not officeArea then
		officeArea = Instance.new("Folder")
		officeArea.Name   = "OfficeArea"
		officeArea.Parent = model
	end

	-- Remove previous office model (only one office at a time)
	for _, child in ipairs(officeArea:GetChildren()) do
		child:Destroy()
	end

	-- Find the upgrade config for display name
	local upgradeName = upgradeId
	for _, u in ipairs(GameConfig.OfficeUpgrades) do
		if u.id == upgradeId then
			upgradeName = u.name
			break
		end
	end

	local origin = PlotManager.GetPlotOrigin(plotIndex)
	local targetCFrame = CFrame.new(origin + Vector3.new(0, 1, -20))

	placeModel(
		ItemModels,
		upgradeId,
		upgradeName,
		targetCFrame,
		officeArea,
		BrickColor.new("Light stone grey"),
		Vector3.new(20, 10, 20)
	)

	print(string.format("[LuxuryItemManager] Spawned office '%s' for %s.", upgradeId, player.Name))
end

-- ─────────────────────────────────────────────
--  SPAWN EMPLOYEE NPC
--  Each employee is placed at a random point in the EmployeeArea.
--  They use a simple animated placeholder (walking rig) if no real model exists.
-- ─────────────────────────────────────────────
local function spawnEmployee(player, employeeId)
	local plotIndex = PlotManager.GetPlotIndex(player)
	if not plotIndex then return end

	local model = PlotManager.GetPlotModel(plotIndex)
	if not model then return end

	local employeeArea = model:FindFirstChild("EmployeeArea")
	if not employeeArea then
		employeeArea = Instance.new("Folder")
		employeeArea.Name   = "EmployeeArea"
		employeeArea.Parent = model
	end

	-- Find employee config for colour
	local empConfig = nil
	for _, e in ipairs(GameConfig.Employees) do
		if e.id == employeeId then
			empConfig = e
			break
		end
	end

	local origin      = PlotManager.GetPlotOrigin(plotIndex)
	local randX       = math.random(-30, 30)
	local randZ       = math.random(-10, 30)
	local spawnPos    = origin + Vector3.new(randX, 2, randZ)
	local targetCFrame = CFrame.new(spawnPos)

	-- Try real model first
	local npc = cloneModel(ItemModels, employeeId)

	if npc then
		anchorModel(npc)
		if npc:IsA("Model") and npc.PrimaryPart then
			npc:SetPrimaryPartCFrame(targetCFrame)
		end
		npc.Name   = "Employee_" .. employeeId
		npc.Parent = employeeArea
	else
		-- Placeholder: coloured block with name label
		local color = empConfig and empConfig.shirtColor or BrickColor.new("Bright blue")
		makePlaceholder(
			"Employee_" .. employeeId,
			Vector3.new(3, 5, 3),
			color,
			employeeArea,
			targetCFrame
		)
	end

	-- Simple wander loop for the NPC
	-- (real NPCs would use PathfindingService; placeholder just teleports randomly)
	task.spawn(function()
		while employeeArea.Parent do
			task.wait(math.random(3, 8))
			local npcObj = employeeArea:FindFirstChild("Employee_" .. employeeId)
			if npcObj then
				local newX = math.random(-30, 30)
				local newZ = math.random(-10, 30)
				local newPos = origin + Vector3.new(newX, 2, newZ)

				if npcObj:IsA("BasePart") then
					npcObj.CFrame = CFrame.new(newPos)
				elseif npcObj:IsA("Model") and npcObj.PrimaryPart then
					npcObj:SetPrimaryPartCFrame(CFrame.new(newPos))
				end
			end
		end
	end)

	print(string.format("[LuxuryItemManager] Spawned employee '%s' for %s.", employeeId, player.Name))
end

-- ─────────────────────────────────────────────
--  SPAWN LUXURY ITEM
--  Items are placed on a grid in the LuxuryArea folder.
-- ─────────────────────────────────────────────

-- Track how many luxury items each player has spawned (for grid layout)
local luxuryItemCount = {}

local function spawnLuxuryItem(player, itemId)
	local plotIndex = PlotManager.GetPlotIndex(player)
	if not plotIndex then return end

	local model = PlotManager.GetPlotModel(plotIndex)
	if not model then return end

	local luxuryArea = model:FindFirstChild("LuxuryArea")
	if not luxuryArea then
		luxuryArea = Instance.new("Folder")
		luxuryArea.Name   = "LuxuryArea"
		luxuryArea.Parent = model
	end

	-- Find item config
	local itemConfig = LuxuryConfig.GetItemById(itemId)
	if not itemConfig then
		warn("[LuxuryItemManager] Unknown luxury item: " .. tostring(itemId))
		return
	end

	-- Calculate grid position for this item
	local userId   = player.UserId
	local count    = luxuryItemCount[userId] or 0
	local grid     = LuxuryConfig.ShowcaseGrid
	local columns  = grid.columns
	local cellSize = grid.cellSize
	local start    = grid.startOffset

	local row = math.floor(count / columns)
	local col = count % columns

	local origin = PlotManager.GetPlotOrigin(plotIndex)

	-- Check if item has a custom spawn offset defined
	local customOffset = itemConfig.spawnOffset
	local targetPos

	if customOffset and (customOffset.X ~= 0 or customOffset.Y ~= 0 or customOffset.Z ~= 0) then
		targetPos = origin + customOffset
	else
		targetPos = origin + start + Vector3.new(col * cellSize, 0, row * cellSize)
	end

	local targetCFrame = CFrame.new(targetPos)

	-- Determine placeholder colour from rarity
	local rarity       = itemConfig.rarity or "Common"
	local placeholderColor = RARITY_COLORS[rarity] or BrickColor.new("White")

	-- Spawn the model
	placeModel(
		LuxuryModels,
		itemId,
		itemConfig.name,
		targetCFrame,
		luxuryArea,
		placeholderColor,
		Vector3.new(8, 8, 8)
	)

	-- Increment the counter so next item gets the next grid cell
	luxuryItemCount[userId] = count + 1

	print(string.format("[LuxuryItemManager] Spawned luxury '%s' for %s at grid [%d, %d].",
		itemId, player.Name, row, col))
end

-- ─────────────────────────────────────────────
--  CLEAR PLOT  (used on rebirth)
-- ─────────────────────────────────────────────
local function clearPlot(player)
	local plotIndex = PlotManager.GetPlotIndex(player)
	if not plotIndex then return end

	local model = PlotManager.GetPlotModel(plotIndex)
	if not model then return end

	for _, areaName in ipairs({"OfficeArea", "EmployeeArea", "LuxuryArea"}) do
		local area = model:FindFirstChild(areaName)
		if area then
			for _, child in ipairs(area:GetChildren()) do
				child:Destroy()
			end
		end
	end

	-- Reset item count
	luxuryItemCount[player.UserId] = 0

	print(string.format("[LuxuryItemManager] Cleared plot for %s (rebirth).", player.Name))
end

-- ─────────────────────────────────────────────
--  RESTORE PLAYER'S OWNED ITEMS ON JOIN
--  Called after DataManager loads the player's saved data.
-- ─────────────────────────────────────────────
local function restorePlayerItems(player)
	local data = DataManager.GetData(player)
	if not data then return end

	-- Wait for plot to be assigned
	local attempts = 0
	while not PlotManager.GetPlotIndex(player) and attempts < 50 do
		task.wait(0.2)
		attempts = attempts + 1
	end

	if not PlotManager.GetPlotIndex(player) then
		warn("[LuxuryItemManager] Could not restore items for " .. player.Name .. " — no plot assigned.")
		return
	end

	-- Spawn current office
	spawnOffice(player, data.CurrentOffice or "Laptop")

	-- Spawn each employee (count times)
	local ec = data.EmployeeCount or {}
	for empId, count in pairs(ec) do
		for _ = 1, count do
			spawnEmployee(player, empId)
		end
	end

	-- Spawn luxury items
	local ownedLux = data.OwnedLuxuryItems or {}
	for _, itemId in ipairs(ownedLux) do
		spawnLuxuryItem(player, itemId)
	end

	print(string.format("[LuxuryItemManager] Restored items for %s.", player.Name))
end

-- ─────────────────────────────────────────────
--  LISTEN FOR DATAREADY EVENT TO TRIGGER RESTORE
-- ─────────────────────────────────────────────
local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents", 15)
local dataReadyEvent = RemoteEvents and RemoteEvents:FindFirstChild("DataReady")

-- DataReady is fired from DataManager on the client, but we need server-side restore.
-- Instead, hook directly into PlayerAdded with a delay.
Players.PlayerAdded:Connect(function(player)
	-- Wait for data to be loaded (DataManager fires after loading)
	task.wait(2)
	task.spawn(restorePlayerItems, player)
end)

-- Handle players already in game (Studio testing)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		task.wait(2)
		restorePlayerItems(player)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	luxuryItemCount[player.UserId] = nil
end)

-- ─────────────────────────────────────────────
--  PUBLIC API
-- ─────────────────────────────────────────────
_G.LuxuryItemManager = {
	SpawnOffice      = spawnOffice,
	SpawnEmployee    = spawnEmployee,
	SpawnLuxuryItem  = spawnLuxuryItem,
	ClearPlot        = clearPlot,
	RestorePlayer    = restorePlayerItems,
}
