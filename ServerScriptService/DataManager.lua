--[[
	DataManager.lua
	ServerScriptService > DataManager (Script)

	Handles all DataStore operations for AI Empire Tycoon.
	Responsible for:
	  - Loading player data on join
	  - Saving player data on leave
	  - Auto-saving every GameConfig.AutoSaveInterval seconds
	  - Graceful retry logic on DataStore failures
	  - Providing a clean API for other scripts to read/write player data

	USAGE (from other server scripts):
	  local DataManager = require(script.Parent.DataManager)  -- if ModuleScript
	  -- OR access via the module table set on _G for server-wide access:
	  _G.DataManager.GetData(player)
	  _G.DataManager.SetData(player, key, value)
	  _G.DataManager.SaveData(player)
]]

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")

local GameConfig = require(game.ReplicatedStorage.GameConfig)

-- ─────────────────────────────────────────────
--  DATASTORE SETUP
-- ─────────────────────────────────────────────
local PlayerDataStore = DataStoreService:GetDataStore(GameConfig.DataStoreKey)

-- In-memory cache: [player] = { data table }
local playerData = {}

-- ─────────────────────────────────────────────
--  DEFAULT DATA TEMPLATE
--  All new players start with this structure.
-- ─────────────────────────────────────────────
local function getDefaultData()
	return {
		Cash             = 0,
		TotalEarned      = 0,
		RebirthCount     = 0,
		CurrentOffice    = "Laptop",       -- highest unlocked office tier
		OwnedUpgrades    = { "Laptop" },   -- list of purchased upgrade IDs
		OwnedEmployees   = {},             -- list of purchased employee IDs (can repeat for multiples)
		OwnedLuxuryItems = {},             -- list of purchased luxury item IDs
		EmployeeCount    = {},             -- { ["Junior Dev"] = 2, ["Senior Dev"] = 1, ... }
		HasAutoCollect   = false,          -- true if AI Manager purchased OR gamepass owned
		PlotIndex        = nil,            -- assigned plot number (set by PlotManager at runtime)
	}
end

-- ─────────────────────────────────────────────
--  RETRY HELPER
--  Retries a DataStore call up to maxAttempts times with exponential backoff.
-- ─────────────────────────────────────────────
local function retryDataStore(func, maxAttempts)
	maxAttempts = maxAttempts or 3
	local attempt = 0
	local success, result

	repeat
		attempt = attempt + 1
		success, result = pcall(func)
		if not success then
			warn(string.format("[DataManager] DataStore error (attempt %d/%d): %s", attempt, maxAttempts, tostring(result)))
			if attempt < maxAttempts then
				task.wait(2 ^ attempt)  -- 2s, 4s, 8s ...
			end
		end
	until success or attempt >= maxAttempts

	return success, result
end

-- ─────────────────────────────────────────────
--  LOAD PLAYER DATA
-- ─────────────────────────────────────────────
local function loadData(player)
	local userId = tostring(player.UserId)
	local loadedData = nil

	local success, result = retryDataStore(function()
		loadedData = PlayerDataStore:GetAsync(userId)
	end)

	if success and loadedData then
		-- Merge saved data with defaults so new fields added in updates are populated
		local defaults = getDefaultData()
		for key, defaultValue in pairs(defaults) do
			if loadedData[key] == nil then
				loadedData[key] = defaultValue
			end
		end
		playerData[player] = loadedData
		print(string.format("[DataManager] Loaded data for %s (Cash: $%d, Rebirths: %d)",
			player.Name, loadedData.Cash, loadedData.RebirthCount))
	else
		if not success then
			warn(string.format("[DataManager] Failed to load data for %s — using defaults. Error: %s",
				player.Name, tostring(result)))
		else
			print(string.format("[DataManager] No saved data for %s — creating new profile.", player.Name))
		end
		playerData[player] = getDefaultData()
	end

	return playerData[player]
end

-- ─────────────────────────────────────────────
--  SAVE PLAYER DATA
-- ─────────────────────────────────────────────
local function saveData(player)
	if not playerData[player] then
		warn(string.format("[DataManager] Tried to save data for %s but no in-memory data found.", player.Name))
		return false
	end

	local userId   = tostring(player.UserId)
	local dataToSave = playerData[player]

	-- Strip runtime-only fields that should not be persisted
	local saveSnapshot = {}
	for k, v in pairs(dataToSave) do
		saveSnapshot[k] = v
	end
	saveSnapshot.PlotIndex = nil  -- plot is re-assigned at runtime, not saved

	local success, result = retryDataStore(function()
		PlayerDataStore:SetAsync(userId, saveSnapshot)
	end)

	if success then
		print(string.format("[DataManager] Saved data for %s.", player.Name))
	else
		warn(string.format("[DataManager] FAILED to save data for %s: %s", player.Name, tostring(result)))
	end

	return success
end

-- ─────────────────────────────────────────────
--  PUBLIC API
-- ─────────────────────────────────────────────

-- Get the full data table for a player (returns nil if not loaded yet)
local function getData(player)
	return playerData[player]
end

-- Get a single field from player data
local function getField(player, key)
	local data = playerData[player]
	if data then
		return data[key]
	end
	return nil
end

-- Set a single field in player data (does NOT save to DataStore immediately)
local function setField(player, key, value)
	if playerData[player] then
		playerData[player][key] = value
	else
		warn(string.format("[DataManager] setField called for %s but data not loaded.", player.Name))
	end
end

-- Add an amount to a numeric field
local function addToField(player, key, amount)
	if playerData[player] then
		playerData[player][key] = (playerData[player][key] or 0) + amount
	end
end

-- Check if a player owns a specific upgrade or luxury item
local function ownsItem(player, listKey, itemId)
	local data = playerData[player]
	if not data then return false end
	local list = data[listKey]
	if not list then return false end
	for _, id in ipairs(list) do
		if id == itemId then return true end
	end
	return false
end

-- Add an item to an owned list (OwnedUpgrades or OwnedLuxuryItems)
local function addOwnedItem(player, listKey, itemId)
	if playerData[player] then
		local list = playerData[player][listKey]
		if list and not ownsItem(player, listKey, itemId) then
			table.insert(list, itemId)
		end
	end
end

-- ─────────────────────────────────────────────
--  LEADERSTATS SETUP
--  Creates the leaderstats folder Roblox uses for the in-game scoreboard.
-- ─────────────────────────────────────────────
local function setupLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name  = "leaderstats"
	leaderstats.Parent = player

	local cashValue = Instance.new("IntValue")
	cashValue.Name  = "Cash"
	cashValue.Value = 0
	cashValue.Parent = leaderstats

	local totalEarnedValue = Instance.new("IntValue")
	totalEarnedValue.Name  = "TotalEarned"
	totalEarnedValue.Value = 0
	totalEarnedValue.Parent = leaderstats

	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name  = "Rebirths"
	rebirthValue.Value = 0
	rebirthValue.Parent = leaderstats

	return leaderstats
end

-- Syncs leaderstats IntValues from the in-memory data table
local function syncLeaderstats(player)
	local data = playerData[player]
	if not data then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local cashVal = leaderstats:FindFirstChild("Cash")
	if cashVal then cashVal.Value = math.floor(data.Cash) end

	local totalVal = leaderstats:FindFirstChild("TotalEarned")
	if totalVal then totalVal.Value = math.floor(data.TotalEarned) end

	local rebirthVal = leaderstats:FindFirstChild("Rebirths")
	if rebirthVal then rebirthVal.Value = data.RebirthCount end
end

-- ─────────────────────────────────────────────
--  PLAYER JOINED
-- ─────────────────────────────────────────────
local function onPlayerAdded(player)
	setupLeaderstats(player)
	local data = loadData(player)
	syncLeaderstats(player)

	-- Fire an event so other systems know data is ready
	local remotes = game.ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remotes then
		local dataReadyEvent = remotes:FindFirstChild("DataReady")
		if dataReadyEvent then
			dataReadyEvent:FireClient(player, data)
		end
	end
end

-- ─────────────────────────────────────────────
--  PLAYER LEAVING
-- ─────────────────────────────────────────────
local function onPlayerRemoving(player)
	saveData(player)
	playerData[player] = nil  -- free memory
end

-- ─────────────────────────────────────────────
--  AUTO-SAVE LOOP
-- ─────────────────────────────────────────────
task.spawn(function()
	while true do
		task.wait(GameConfig.AutoSaveInterval)
		for player, _ in pairs(playerData) do
			if player and player.Parent then  -- player is still in game
				saveData(player)
				syncLeaderstats(player)
			end
		end
	end
end)

-- ─────────────────────────────────────────────
--  CONNECT EVENTS
-- ─────────────────────────────────────────────
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players already in game if script loads late (e.g. in Studio testing)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- ─────────────────────────────────────────────
--  EXPORT PUBLIC API via _G for cross-script access
--  Other server scripts can do:  local DM = _G.DataManager
-- ─────────────────────────────────────────────
_G.DataManager = {
	GetData        = getData,
	GetField       = getField,
	SetField       = setField,
	AddToField     = addToField,
	OwnsItem       = ownsItem,
	AddOwnedItem   = addOwnedItem,
	SaveData       = saveData,
	SyncLeaderstats = syncLeaderstats,
}
