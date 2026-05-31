--[[
	MainGameScript.lua
	ServerScriptService > MainGameScript (Script)

	The server-side bootstrap for AI Empire Tycoon.
	This script runs FIRST and is responsible for:
	  1. Creating all RemoteEvents in ReplicatedStorage
	  2. Creating the ItemModels and LuxuryModels folders in ReplicatedStorage (if absent)
	  3. Creating the Lobby area in Workspace (if absent)
	  4. Running the global leaderboard update loop
	  5. Logging startup diagnostics

	All other server systems (DataManager, PlotManager, IncomeManager, LuxuryItemManager)
	are separate Scripts in ServerScriptService and start up independently.
	They use _G.* to expose their APIs to each other.

	EXECUTION ORDER NOTE:
	  Roblox executes Scripts in ServerScriptService in alphabetical order within the
	  same priority level.  To control order, either:
	    a) Use the "RunContext" or script priority settings in Studio, OR
	    b) Name scripts with a number prefix: "01_MainGameScript", "02_DataManager", etc.
	  The safest approach (used here) is that every script waits for its dependencies
	  via _G polling, so order doesn't matter as long as all scripts eventually run.
]]

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")

local GameConfig = require(game.ReplicatedStorage.GameConfig)

-- ─────────────────────────────────────────────
--  1. CREATE REMOTE EVENTS
--  All client<->server communication happens through these events.
--  The full list is also documented in docs/RemoteEvents_List.md
-- ─────────────────────────────────────────────
local REMOTE_EVENT_NAMES = {
	-- Data & Cash
	"DataReady",          -- Server -> Client: fires when player data is loaded, sends full data table
	"UpdateCash",         -- Server -> Client: current Cash and TotalEarned values
	"RequestIncome",      -- Client -> Server: ask what income rate is (for shop display)
	"IncomeResponse",     -- Server -> Client: response with income per second

	-- Plot
	"PlotAssigned",       -- Server -> Client: tells client which plot and origin they have

	-- Shop / Purchases
	"BuyUpgrade",         -- Client -> Server: purchase an office upgrade (sends upgradeId)
	"BuyEmployee",        -- Client -> Server: hire an employee (sends employeeId)
	"BuyLuxury",          -- Client -> Server: purchase a luxury item (sends itemId)
	"PurchaseResult",     -- Server -> Client: result of any purchase (type, id, success, message)

	-- Rebirth
	"RebirthEligible",    -- Server -> Client: player has reached the rebirth threshold
	"RequestRebirth",     -- Client -> Server: player pressed the rebirth button
	"RebirthResult",      -- Server -> Client: result of rebirth attempt
	"OnRebirth",          -- Server -> Client: broadcast that rebirth completed (sends new count)

	-- Leaderboard
	"LeaderboardUpdate",  -- Server -> Client (All): updated top-10 list every 10s

	-- Shop UI
	"OpenShop",           -- Client -> Server or Server -> Client: open shop GUI
	"CloseShop",          -- Client -> Server or Server -> Client: close shop GUI
}

local function createRemoteEvents()
	local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name   = "RemoteEvents"
		folder.Parent = ReplicatedStorage
		print("[MainGameScript] Created RemoteEvents folder.")
	end

	for _, name in ipairs(REMOTE_EVENT_NAMES) do
		if not folder:FindFirstChild(name) then
			local re   = Instance.new("RemoteEvent")
			re.Name    = name
			re.Parent  = folder
		end
	end

	print(string.format("[MainGameScript] Ensured %d RemoteEvents exist.", #REMOTE_EVENT_NAMES))
	return folder
end

-- ─────────────────────────────────────────────
--  2. CREATE MODEL REPOSITORY FOLDERS
-- ─────────────────────────────────────────────
local function createModelFolders()
	local function ensureFolder(parent, name)
		local f = parent:FindFirstChild(name)
		if not f then
			f = Instance.new("Folder")
			f.Name   = name
			f.Parent = parent
			print(string.format("[MainGameScript] Created %s/%s folder.", parent.Name, name))
		end
		return f
	end

	ensureFolder(ReplicatedStorage, "ItemModels")
	ensureFolder(ReplicatedStorage, "LuxuryModels")
end

-- ─────────────────────────────────────────────
--  3. CREATE LOBBY AREA
-- ─────────────────────────────────────────────
local function createLobby()
	local workspace = game.Workspace
	if workspace:FindFirstChild("Lobby") then return end

	local lobby = Instance.new("Model")
	lobby.Name  = "Lobby"
	lobby.Parent = workspace

	-- Lobby floor
	local floor = Instance.new("Part")
	floor.Name      = "LobbyFloor"
	floor.Size      = Vector3.new(100, 1, 60)
	floor.Position  = Vector3.new(0, -0.5, -150)  -- behind the plots
	floor.Anchored  = true
	floor.BrickColor = BrickColor.new("Dark stone grey")
	floor.Material  = Enum.Material.SmoothPlastic
	floor.TopSurface = Enum.SurfaceType.Smooth
	floor.Parent    = lobby

	-- Welcome sign (BillboardGui on a post)
	local signPost = Instance.new("Part")
	signPost.Name     = "WelcomePost"
	signPost.Size     = Vector3.new(1, 10, 1)
	signPost.Position = Vector3.new(0, 5, -165)
	signPost.Anchored = true
	signPost.BrickColor = BrickColor.new("Mid gray")
	signPost.Material = Enum.Material.Metal
	signPost.Parent   = lobby

	local billboard = Instance.new("BillboardGui", signPost)
	billboard.Size        = UDim2.new(0, 400, 0, 120)
	billboard.StudsOffset = Vector3.new(0, 8, 0)
	billboard.AlwaysOnTop = false

	local titleLabel = Instance.new("TextLabel", billboard)
	titleLabel.Size              = UDim2.new(1, 0, 0.6, 0)
	titleLabel.Position          = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text              = "🤖 AI EMPIRE TYCOON"
	titleLabel.TextColor3        = Color3.fromRGB(255, 200, 30)
	titleLabel.TextScaled        = true
	titleLabel.Font              = Enum.Font.GothamBlack

	local subLabel = Instance.new("TextLabel", billboard)
	subLabel.Size               = UDim2.new(1, 0, 0.4, 0)
	subLabel.Position           = UDim2.new(0, 0, 0.6, 0)
	subLabel.BackgroundTransparency = 1
	subLabel.Text               = "Build your AI empire. Dominate the world."
	subLabel.TextColor3         = Color3.fromRGB(200, 220, 255)
	subLabel.TextScaled         = true
	subLabel.Font               = Enum.Font.Gotham

	-- Spawn location for new players (SpawnLocation)
	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name      = "LobbySpawn"
	spawnLoc.Size      = Vector3.new(6, 1, 6)
	spawnLoc.Position  = Vector3.new(0, 1, -155)
	spawnLoc.Anchored  = true
	spawnLoc.BrickColor = BrickColor.new("Bright blue")
	spawnLoc.Material  = Enum.Material.Neon
	spawnLoc.Neutral   = true  -- all teams spawn here
	spawnLoc.Duration  = 0
	spawnLoc.Parent    = lobby

	-- Shop access pad in the lobby
	local shopPad = Instance.new("Part")
	shopPad.Name      = "ShopPad"
	shopPad.Size      = Vector3.new(10, 1, 10)
	shopPad.Position  = Vector3.new(20, 1, -155)
	shopPad.Anchored  = true
	shopPad.BrickColor = BrickColor.new("Bright blue")
	shopPad.Material  = Enum.Material.Neon
	shopPad.TopSurface = Enum.SurfaceType.Smooth
	shopPad.Parent    = lobby

	local shopBillboard = Instance.new("BillboardGui", shopPad)
	shopBillboard.Size        = UDim2.new(0, 160, 0, 50)
	shopBillboard.StudsOffset = Vector3.new(0, 4, 0)
	local shopLabel = Instance.new("TextLabel", shopBillboard)
	shopLabel.Size              = UDim2.new(1, 0, 1, 0)
	shopLabel.BackgroundTransparency = 1
	shopLabel.Text              = "🛒 SHOP\nStep here to open"
	shopLabel.TextColor3        = Color3.fromRGB(255, 255, 255)
	shopLabel.TextScaled        = true
	shopLabel.Font              = Enum.Font.GothamBold

	-- Shop pad touch event
	local shopDebounce = {}
	shopPad.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		if shopDebounce[player] then return end

		shopDebounce[player] = true
		local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if re then
			local openShop = re:FindFirstChild("OpenShop")
			if openShop then openShop:FireClient(player) end
		end
		task.wait(2)
		shopDebounce[player] = nil
	end)

	print("[MainGameScript] Created Lobby area.")
end

-- ─────────────────────────────────────────────
--  4. LEADERBOARD UPDATE LOOP
--  Collects all players' net worth and broadcasts top 10 to all clients.
-- ─────────────────────────────────────────────
local function formatCash(amount)
	for _, fmt in ipairs(GameConfig.CurrencyFormat) do
		if amount >= fmt.threshold then
			return string.format("$%.1f%s", amount / fmt.threshold, fmt.suffix)
		end
	end
	return string.format("$%d", math.floor(amount))
end

local function runLeaderboardLoop()
	local re = ReplicatedStorage:WaitForChild("RemoteEvents", 15)
	if not re then return end

	local leaderboardUpdate = re:WaitForChild("LeaderboardUpdate", 10)
	if not leaderboardUpdate then return end

	while true do
		task.wait(GameConfig.LeaderboardUpdateInterval)

		-- Gather net worths from all players
		local entries = {}
		for _, player in ipairs(Players:GetPlayers()) do
			if _G.DataManager then
				local data = _G.DataManager.GetData(player)
				if data then
					table.insert(entries, {
						name       = player.Name,
						cash       = data.Cash or 0,
						rebirths   = data.RebirthCount or 0,
						formatted  = formatCash(data.Cash or 0),
					})
				end
			else
				-- Fallback: read from leaderstats
				local ls   = player:FindFirstChild("leaderstats")
				local cv   = ls and ls:FindFirstChild("Cash")
				local cash = cv and cv.Value or 0
				table.insert(entries, {
					name      = player.Name,
					cash      = cash,
					rebirths  = 0,
					formatted = formatCash(cash),
				})
			end
		end

		-- Sort descending by cash
		table.sort(entries, function(a, b) return a.cash > b.cash end)

		-- Trim to top 10
		local topEntries = {}
		for i = 1, math.min(GameConfig.LeaderboardMaxEntries, #entries) do
			table.insert(topEntries, entries[i])
		end

		-- Broadcast to all clients
		leaderboardUpdate:FireAllClients(topEntries)
	end
end

-- ─────────────────────────────────────────────
--  5. STARTUP DIAGNOSTICS
-- ─────────────────────────────────────────────
local function printStartupDiagnostics()
	print("═══════════════════════════════════════")
	print("  AI Empire Tycoon — Server Starting")
	print(string.format("  Plots:        %d", GameConfig.Plots.totalPlots))
	print(string.format("  Income Tick:  %ds", GameConfig.IncomeTick))
	print(string.format("  Auto-Save:    every %ds", GameConfig.AutoSaveInterval))
	print(string.format("  Leaderboard:  every %ds", GameConfig.LeaderboardUpdateInterval))
	print(string.format("  DataStore:    %s", GameConfig.DataStoreKey))
	print(string.format("  Office Tiers: %d", #GameConfig.OfficeUpgrades))
	print(string.format("  Employees:    %d types", #GameConfig.Employees))

	local LuxuryConfig = require(game.ReplicatedStorage.LuxuryConfig)
	print(string.format("  Luxury Items: %d total", #LuxuryConfig.Items))
	print("═══════════════════════════════════════")
end

-- ─────────────────────────────────────────────
--  BOOT SEQUENCE
-- ─────────────────────────────────────────────
printStartupDiagnostics()
createRemoteEvents()
createModelFolders()
createLobby()

-- Leaderboard runs in background
task.spawn(runLeaderboardLoop)

print("[MainGameScript] Bootstrap complete. Waiting for other systems...")
