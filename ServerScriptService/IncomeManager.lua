--[[
	IncomeManager.lua
	ServerScriptService > IncomeManager (Script)

	Manages all passive income for AI Empire Tycoon.
	Responsibilities:
	  - Runs a per-second tick that grants cash to every player
	  - Calculates income from current office tier + employee bonuses
	  - Applies rebirth multipliers
	  - Checks for gamepass-based income boosts (2x Income gamepass)
	  - Fires client RemoteEvents to update the HUD cash display
	  - Handles the rebirth action when triggered by a player
	  - Handles purchase requests forwarded from the shop (BuyUpgrade, BuyEmployee, BuyLuxury)

	DEPENDENCIES (must run before this script or be available in _G):
	  _G.DataManager  – from DataManager.lua
	  _G.PlotManager  – from PlotManager.lua
]]

local Players           = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local GameConfig  = require(game.ReplicatedStorage.GameConfig)
local LuxuryConfig = require(game.ReplicatedStorage.LuxuryConfig)

-- ─────────────────────────────────────────────
--  WAIT FOR DEPENDENCIES
--  DataManager and PlotManager run as Scripts in SSS; they set _G tables.
--  We wait up to 10s for them to be ready before proceeding.
-- ─────────────────────────────────────────────
local function waitForGlobal(name, timeout)
	timeout = timeout or 10
	local elapsed = 0
	while not _G[name] and elapsed < timeout do
		task.wait(0.1)
		elapsed = elapsed + 0.1
	end
	if not _G[name] then
		error(string.format("[IncomeManager] Timed out waiting for _G.%s", name))
	end
	return _G[name]
end

local DataManager = waitForGlobal("DataManager")
local PlotManager = waitForGlobal("PlotManager")

-- ─────────────────────────────────────────────
--  REMOTE EVENTS
-- ─────────────────────────────────────────────
local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents", 15)

local function getRemote(name)
	local r = RemoteEvents:FindFirstChild(name)
	if not r then
		warn(string.format("[IncomeManager] RemoteEvent '%s' not found.", name))
	end
	return r
end

-- ─────────────────────────────────────────────
--  GAMEPASS CHECK
-- ─────────────────────────────────────────────
local function hasGamepass(player, gamepassId)
	if gamepassId == 0 then return false end  -- not configured
	local ok, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)
	return ok and result
end

-- ─────────────────────────────────────────────
--  CALCULATE INCOME FOR A PLAYER
--  Returns the number of dollars per second the player currently earns.
-- ─────────────────────────────────────────────
local function calculateIncome(player)
	local data = DataManager.GetData(player)
	if not data then return 0 end

	-- Base income from current office tier
	local officeIncome = GameConfig.IncomeRates[data.CurrentOffice] or 0

	-- Employee income bonuses
	local employeeIncome = 0
	local employeeCount  = data.EmployeeCount or {}
	for _, empConfig in ipairs(GameConfig.Employees) do
		local count = employeeCount[empConfig.id] or 0
		employeeIncome = employeeIncome + (count * empConfig.incomeBonus)
	end

	local baseIncome = officeIncome + employeeIncome

	-- Rebirth multiplier  (2 ^ rebirths, since each rebirth doubles)
	local rebirthMultiplier = math.pow(GameConfig.Rebirth.multiplierPerRebirth, data.RebirthCount)

	-- Gamepass: 2x Income
	local gamepassMultiplier = 1
	if hasGamepass(player, GameConfig.Gamepasses.DoubleIncome) then
		gamepassMultiplier = 2
	end

	return math.floor(baseIncome * rebirthMultiplier * gamepassMultiplier)
end

-- ─────────────────────────────────────────────
--  INCOME TICK
--  Runs every GameConfig.IncomeTick seconds and pays all players.
-- ─────────────────────────────────────────────
task.spawn(function()
	while true do
		task.wait(GameConfig.IncomeTick)

		for _, player in ipairs(Players:GetPlayers()) do
			local data = DataManager.GetData(player)
			if not data then continue end

			local income = calculateIncome(player)
			if income <= 0 then continue end

			-- Grant cash
			DataManager.AddToField(player, "Cash",        income)
			DataManager.AddToField(player, "TotalEarned", income)

			-- Sync leaderstats
			DataManager.SyncLeaderstats(player)

			-- Push updated cash to client HUD
			local updateCash = getRemote("UpdateCash")
			if updateCash then
				updateCash:FireClient(player, data.Cash, data.TotalEarned)
			end

			-- Check rebirth eligibility
			local rebirthButton = getRemote("RebirthEligible")
			if rebirthButton and data.TotalEarned >= GameConfig.Rebirth.requiredTotalEarned then
				rebirthButton:FireClient(player, true)
			end
		end
	end
end)

-- ─────────────────────────────────────────────
--  PURCHASE: OFFICE UPGRADE
-- ─────────────────────────────────────────────
local function buyOfficeUpgrade(player, upgradeId)
	local data = DataManager.GetData(player)
	if not data then return false, "Data not loaded." end

	-- Find the upgrade config
	local upgradeConfig = nil
	for _, u in ipairs(GameConfig.OfficeUpgrades) do
		if u.id == upgradeId then
			upgradeConfig = u
			break
		end
	end

	if not upgradeConfig then
		return false, "Unknown upgrade: " .. tostring(upgradeId)
	end

	-- Already owned?
	if DataManager.OwnsItem(player, "OwnedUpgrades", upgradeId) then
		return false, "Already owned."
	end

	-- Can afford?
	if data.Cash < upgradeConfig.price then
		return false, "Not enough cash."
	end

	-- Deduct cash and record ownership
	DataManager.AddToField(player, "Cash", -upgradeConfig.price)
	DataManager.AddOwnedItem(player, "OwnedUpgrades", upgradeId)
	DataManager.SetField(player, "CurrentOffice", upgradeId)
	DataManager.SyncLeaderstats(player)

	-- Notify client of updated cash
	local updateCash = getRemote("UpdateCash")
	if updateCash then
		updateCash:FireClient(player, data.Cash, data.TotalEarned)
	end

	-- Tell LuxuryItemManager (or a building spawner) to spawn the office model
	if _G.LuxuryItemManager then
		_G.LuxuryItemManager.SpawnOffice(player, upgradeId)
	end

	print(string.format("[IncomeManager] %s purchased office upgrade: %s", player.Name, upgradeId))
	return true, "Success"
end

-- ─────────────────────────────────────────────
--  PURCHASE: EMPLOYEE
-- ─────────────────────────────────────────────
local function buyEmployee(player, employeeId)
	local data = DataManager.GetData(player)
	if not data then return false, "Data not loaded." end

	-- Find employee config
	local empConfig = nil
	for _, e in ipairs(GameConfig.Employees) do
		if e.id == employeeId then
			empConfig = e
			break
		end
	end

	if not empConfig then
		return false, "Unknown employee: " .. tostring(employeeId)
	end

	-- Check total employee count limit
	local totalEmployees = 0
	local employeeCount  = data.EmployeeCount or {}
	for _, count in pairs(employeeCount) do
		totalEmployees = totalEmployees + count
	end

	local maxAllowed = GameConfig.MaxEmployees.default
	if hasGamepass(player, GameConfig.Gamepasses.ExtraEmployees) then
		maxAllowed = GameConfig.MaxEmployees.vip
	end

	if totalEmployees >= maxAllowed then
		return false, string.format("Employee limit reached (%d/%d).", totalEmployees, maxAllowed)
	end

	-- Can afford?
	if data.Cash < empConfig.price then
		return false, "Not enough cash."
	end

	-- Deduct cash
	DataManager.AddToField(player, "Cash", -empConfig.price)

	-- Record the employee
	local ec = data.EmployeeCount
	ec[employeeId] = (ec[employeeId] or 0) + 1

	-- Track auto-collect flag
	if empConfig.autoCollect then
		DataManager.SetField(player, "HasAutoCollect", true)
	end

	DataManager.SyncLeaderstats(player)

	-- Update cash on client
	local updateCash = getRemote("UpdateCash")
	if updateCash then
		updateCash:FireClient(player, data.Cash, data.TotalEarned)
	end

	-- Spawn employee NPC on plot
	if _G.LuxuryItemManager then
		_G.LuxuryItemManager.SpawnEmployee(player, employeeId)
	end

	print(string.format("[IncomeManager] %s hired: %s (now has %d)",
		player.Name, employeeId, ec[employeeId]))
	return true, "Success"
end

-- ─────────────────────────────────────────────
--  PURCHASE: LUXURY ITEM
-- ─────────────────────────────────────────────
local function buyLuxuryItem(player, itemId)
	local data = DataManager.GetData(player)
	if not data then return false, "Data not loaded." end

	local itemConfig = LuxuryConfig.GetItemById(itemId)
	if not itemConfig then
		return false, "Unknown luxury item: " .. tostring(itemId)
	end

	-- Already owned?
	if DataManager.OwnsItem(player, "OwnedLuxuryItems", itemId) then
		return false, "Already owned."
	end

	-- Can afford?
	if data.Cash < itemConfig.price then
		return false, "Not enough cash."
	end

	-- Deduct cash and record
	DataManager.AddToField(player, "Cash", -itemConfig.price)
	DataManager.AddOwnedItem(player, "OwnedLuxuryItems", itemId)
	DataManager.SyncLeaderstats(player)

	-- Update cash on client
	local updateCash = getRemote("UpdateCash")
	if updateCash then
		updateCash:FireClient(player, data.Cash, data.TotalEarned)
	end

	-- Spawn the luxury model on the plot
	if _G.LuxuryItemManager then
		_G.LuxuryItemManager.SpawnLuxuryItem(player, itemId)
	end

	print(string.format("[IncomeManager] %s purchased luxury item: %s ($%d)",
		player.Name, itemConfig.name, itemConfig.price))
	return true, "Success"
end

-- ─────────────────────────────────────────────
--  REBIRTH
-- ─────────────────────────────────────────────
local function doRebirth(player)
	local data = DataManager.GetData(player)
	if not data then return false, "Data not loaded." end

	if data.TotalEarned < GameConfig.Rebirth.requiredTotalEarned then
		return false, string.format("Need $%s total earned.",
			tostring(GameConfig.Rebirth.requiredTotalEarned))
	end

	-- Increment rebirth count and reset progress
	data.RebirthCount     = data.RebirthCount + 1
	data.Cash             = 0
	data.TotalEarned      = 0
	data.CurrentOffice    = "Laptop"
	data.OwnedUpgrades    = { "Laptop" }
	data.OwnedEmployees   = {}
	data.OwnedLuxuryItems = {}
	data.EmployeeCount    = {}
	data.HasAutoCollect   = false

	DataManager.SyncLeaderstats(player)

	-- Clear the player's plot of all spawned items
	if _G.LuxuryItemManager then
		_G.LuxuryItemManager.ClearPlot(player)
	end

	-- Re-spawn the starting Laptop
	if _G.LuxuryItemManager then
		_G.LuxuryItemManager.SpawnOffice(player, "Laptop")
	end

	-- Tell client to refresh everything
	local onRebirth = getRemote("OnRebirth")
	if onRebirth then
		onRebirth:FireClient(player, data.RebirthCount)
	end

	local updateCash = getRemote("UpdateCash")
	if updateCash then
		updateCash:FireClient(player, data.Cash, data.TotalEarned)
	end

	print(string.format("[IncomeManager] %s rebirthed! Now on rebirth #%d.", player.Name, data.RebirthCount))
	return true, "Rebirth successful!"
end

-- ─────────────────────────────────────────────
--  WIRE UP REMOTE EVENTS
-- ─────────────────────────────────────────────
local function wireRemotes()
	local re = game.ReplicatedStorage:WaitForChild("RemoteEvents", 15)
	if not re then
		error("[IncomeManager] RemoteEvents folder not found!")
	end

	-- BuyUpgrade: client -> server
	local buyUpgradeEvent = re:WaitForChild("BuyUpgrade", 10)
	if buyUpgradeEvent then
		buyUpgradeEvent.OnServerEvent:Connect(function(player, upgradeId)
			local success, msg = buyOfficeUpgrade(player, upgradeId)
			local purchaseResult = re:FindFirstChild("PurchaseResult")
			if purchaseResult then
				purchaseResult:FireClient(player, "upgrade", upgradeId, success, msg)
			end
		end)
	end

	-- BuyEmployee: client -> server
	local buyEmployeeEvent = re:WaitForChild("BuyEmployee", 10)
	if buyEmployeeEvent then
		buyEmployeeEvent.OnServerEvent:Connect(function(player, employeeId)
			local success, msg = buyEmployee(player, employeeId)
			local purchaseResult = re:FindFirstChild("PurchaseResult")
			if purchaseResult then
				purchaseResult:FireClient(player, "employee", employeeId, success, msg)
			end
		end)
	end

	-- BuyLuxury: client -> server
	local buyLuxuryEvent = re:WaitForChild("BuyLuxury", 10)
	if buyLuxuryEvent then
		buyLuxuryEvent.OnServerEvent:Connect(function(player, itemId)
			local success, msg = buyLuxuryItem(player, itemId)
			local purchaseResult = re:FindFirstChild("PurchaseResult")
			if purchaseResult then
				purchaseResult:FireClient(player, "luxury", itemId, success, msg)
			end
		end)
	end

	-- RequestRebirth: client -> server
	local rebirthEvent = re:WaitForChild("RequestRebirth", 10)
	if rebirthEvent then
		rebirthEvent.OnServerEvent:Connect(function(player)
			local success, msg = doRebirth(player)
			local rebirthResult = re:FindFirstChild("RebirthResult")
			if rebirthResult then
				rebirthResult:FireClient(player, success, msg)
			end
		end)
	end

	-- RequestIncome: client asks for current income rate (for shop display)
	local requestIncome = re:WaitForChild("RequestIncome", 10)
	if requestIncome then
		requestIncome.OnServerEvent:Connect(function(player)
			local income = calculateIncome(player)
			local incomeResponse = re:FindFirstChild("IncomeResponse")
			if incomeResponse then
				incomeResponse:FireClient(player, income)
			end
		end)
	end

	print("[IncomeManager] All remote events wired.")
end

wireRemotes()

-- ─────────────────────────────────────────────
--  PUBLIC API
-- ─────────────────────────────────────────────
_G.IncomeManager = {
	CalculateIncome = calculateIncome,
	BuyOfficeUpgrade = buyOfficeUpgrade,
	BuyEmployee      = buyEmployee,
	BuyLuxuryItem    = buyLuxuryItem,
	DoRebirth        = doRebirth,
}
