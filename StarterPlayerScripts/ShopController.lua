--[[
	ShopController.lua
	StarterPlayerScripts > ShopController (LocalScript)

	Central client-side state manager for AI Empire Tycoon.
	All other client scripts read state from here and register callbacks.

	STATE MANAGED:
	  - Current cash and total earned (mirrored from server ticks)
	  - Owned upgrades, employees, luxury items (mirrored from server)
	  - Rebirth count
	  - Whether the shop is open
	  - Whether the player is near a shop pad

	CALLBACK SYSTEM:
	  Other scripts register callbacks via OnXxx() functions.
	  Callbacks are fired whenever the relevant state changes.

	PURCHASE FUNCTIONS:
	  BuyUpgrade, BuyEmployee, BuyLuxury, RequestRebirth
	  — these just fire the RemoteEvents; the server validates and responds.

	EXPOSED VIA:
	  _G.ShopController  (available to all client LocalScripts)
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- ─────────────────────────────────────────────
--  REMOTE EVENTS
-- ─────────────────────────────────────────────
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 15)

local function getRemote(name)
	return RemoteEvents and RemoteEvents:WaitForChild(name, 10)
end

-- ─────────────────────────────────────────────
--  LOCAL STATE
-- ─────────────────────────────────────────────
local state = {
	cash             = 0,
	totalEarned      = 0,
	rebirthCount     = 0,
	ownedUpgrades    = { "Laptop" },
	ownedLuxuryItems = {},
	employeeCount    = {},
	isNearShop       = false,
	shopOpen         = false,
	dataLoaded       = false,
}

-- ─────────────────────────────────────────────
--  CALLBACK LISTS
-- ─────────────────────────────────────────────
local callbacks = {
	cashChanged      = {},   -- (cash, totalEarned)
	shopToggled      = {},   -- (isOpen)
	nearShopChanged  = {},   -- (isNear)
	purchaseResult   = {},   -- (purchaseType, itemId, success, message)
	rebirthOccurred  = {},   -- (newRebirthCount)
	dataLoaded       = {},   -- (state)
}

local function fire(callbackList, ...)
	for _, cb in ipairs(callbackList) do
		task.spawn(cb, ...)
	end
end

-- ─────────────────────────────────────────────
--  HELPER: add to owned list (no duplicates)
-- ─────────────────────────────────────────────
local function addToOwned(list, id)
	for _, existing in ipairs(list) do
		if existing == id then return end
	end
	table.insert(list, id)
end

-- ─────────────────────────────────────────────
--  REMOTE EVENT CONNECTIONS
-- ─────────────────────────────────────────────

-- DataReady: server sends the full player data table when it finishes loading
local dataReadyRe = getRemote("DataReady")
if dataReadyRe then
	dataReadyRe.OnClientEvent:Connect(function(data)
		if not data then return end
		state.cash             = math.floor(data.Cash or 0)
		state.totalEarned      = math.floor(data.TotalEarned or 0)
		state.rebirthCount     = data.RebirthCount or 0
		state.ownedUpgrades    = data.OwnedUpgrades or { "Laptop" }
		state.ownedLuxuryItems = data.OwnedLuxuryItems or {}
		state.employeeCount    = data.EmployeeCount or {}
		state.dataLoaded       = true

		fire(callbacks.cashChanged,   state.cash, state.totalEarned)
		fire(callbacks.dataLoaded,    state)
		fire(callbacks.purchaseResult, "init", nil, true, "Data loaded")
	end)
end

-- UpdateCash: server pushes this every income tick (~1s)
local updateCashRe = getRemote("UpdateCash")
if updateCashRe then
	updateCashRe.OnClientEvent:Connect(function(cash, totalEarned)
		state.cash        = math.floor(cash or state.cash)
		state.totalEarned = math.floor(totalEarned or state.totalEarned)
		fire(callbacks.cashChanged, state.cash, state.totalEarned)
	end)
end

-- PurchaseResult: server confirms or rejects a purchase
local purchaseResultRe = getRemote("PurchaseResult")
if purchaseResultRe then
	purchaseResultRe.OnClientEvent:Connect(function(purchaseType, itemId, success, message)
		if success then
			if purchaseType == "upgrade" then
				addToOwned(state.ownedUpgrades, itemId)
			elseif purchaseType == "employee" then
				state.employeeCount[itemId] = (state.employeeCount[itemId] or 0) + 1
			elseif purchaseType == "luxury" then
				addToOwned(state.ownedLuxuryItems, itemId)
			end
		end
		fire(callbacks.purchaseResult, purchaseType, itemId, success, message)
	end)
end

-- OnRebirth: server confirmed the rebirth; reset local state to match
local onRebirthRe = getRemote("OnRebirth")
if onRebirthRe then
	onRebirthRe.OnClientEvent:Connect(function(newRebirthCount)
		state.rebirthCount     = newRebirthCount
		state.cash             = 0
		state.totalEarned      = 0
		state.ownedUpgrades    = { "Laptop" }
		state.ownedLuxuryItems = {}
		state.employeeCount    = {}

		fire(callbacks.rebirthOccurred,  newRebirthCount)
		fire(callbacks.cashChanged,      0, 0)
		-- Refresh shop UI
		fire(callbacks.purchaseResult,   "rebirth", nil, true, "Rebirth complete!")
	end)
end

-- ─────────────────────────────────────────────
--  PUBLIC API
-- ─────────────────────────────────────────────
local ShopController = {}

-- ── State readers ─────────────────────────────
function ShopController.GetCash()          return state.cash          end
function ShopController.GetTotalEarned()   return state.totalEarned   end
function ShopController.GetRebirthCount()  return state.rebirthCount  end
function ShopController.IsDataLoaded()     return state.dataLoaded    end
function ShopController.IsShopOpen()       return state.shopOpen      end
function ShopController.IsNearShop()       return state.isNearShop    end

function ShopController.CanAfford(price)
	return state.cash >= price
end

function ShopController.OwnsUpgrade(id)
	for _, ownedId in ipairs(state.ownedUpgrades) do
		if ownedId == id then return true end
	end
	return false
end

function ShopController.OwnsLuxury(id)
	for _, ownedId in ipairs(state.ownedLuxuryItems) do
		if ownedId == id then return true end
	end
	return false
end

function ShopController.GetEmployeeCount(id)
	return state.employeeCount[id] or 0
end

-- ── Purchase actions ──────────────────────────
function ShopController.BuyUpgrade(upgradeId)
	local re = RemoteEvents:FindFirstChild("BuyUpgrade")
	if re then re:FireServer(upgradeId) end
end

function ShopController.BuyEmployee(employeeId)
	local re = RemoteEvents:FindFirstChild("BuyEmployee")
	if re then re:FireServer(employeeId) end
end

function ShopController.BuyLuxury(itemId)
	local re = RemoteEvents:FindFirstChild("BuyLuxury")
	if re then re:FireServer(itemId) end
end

function ShopController.RequestRebirth()
	local re = RemoteEvents:FindFirstChild("RequestRebirth")
	if re then re:FireServer() end
end

-- ── Shop visibility ───────────────────────────
function ShopController.OpenShop()
	if not state.shopOpen then
		state.shopOpen = true
		fire(callbacks.shopToggled, true)
	end
end

function ShopController.CloseShop()
	if state.shopOpen then
		state.shopOpen = false
		fire(callbacks.shopToggled, false)
	end
end

function ShopController.ToggleShop()
	if state.shopOpen then
		ShopController.CloseShop()
	else
		ShopController.OpenShop()
	end
end

-- ── Proximity ────────────────────────────────
function ShopController.SetNearShop(isNear)
	if isNear ~= state.isNearShop then
		state.isNearShop = isNear
		fire(callbacks.nearShopChanged, isNear)
	end
end

-- ── Callback registration ─────────────────────
function ShopController.OnCashChanged(cb)     table.insert(callbacks.cashChanged,    cb) end
function ShopController.OnShopToggled(cb)     table.insert(callbacks.shopToggled,    cb) end
function ShopController.OnNearShopChanged(cb) table.insert(callbacks.nearShopChanged, cb) end
function ShopController.OnPurchaseResult(cb)  table.insert(callbacks.purchaseResult, cb) end
function ShopController.OnRebirthOccurred(cb) table.insert(callbacks.rebirthOccurred, cb) end
function ShopController.OnDataLoaded(cb)      table.insert(callbacks.dataLoaded,     cb) end

-- ─────────────────────────────────────────────
--  EXPOSE GLOBALLY
-- ─────────────────────────────────────────────
_G.ShopController = ShopController
print("[ShopController] Loaded and registered as _G.ShopController.")
