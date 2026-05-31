--[[
	LocalInputHandler.lua
	StarterPlayerScripts > LocalInputHandler (LocalScript)

	Handles all keyboard input and proximity detection for the client.
	  - E key: toggle the shop GUI open/close
	  - Proximity to shop pads: shows a "Press E" hint via ShopController callback
	  - Listens for the OpenShop RemoteEvent pushed from the server (stepping on pads)
]]

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- ─────────────────────────────────────────────
--  WAIT FOR SHOPCONTROLLER
--  ShopController.lua also runs at startup; wait for it to register.
-- ─────────────────────────────────────────────
local function waitForGlobal(name, timeout)
	timeout = timeout or 15
	local elapsed = 0
	while not _G[name] and elapsed < timeout do
		task.wait(0.05)
		elapsed = elapsed + 0.05
	end
	return _G[name]
end

local ShopController = waitForGlobal("ShopController")
if not ShopController then
	warn("[LocalInputHandler] ShopController not found — some input won't work.")
end

-- ─────────────────────────────────────────────
--  REMOTE EVENTS
-- ─────────────────────────────────────────────
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 15)

-- Server can force-open the shop (e.g. player stepped on a shop pad server-side)
local openShopRe = RemoteEvents and RemoteEvents:WaitForChild("OpenShop", 10)
if openShopRe then
	openShopRe.OnClientEvent:Connect(function()
		if ShopController then
			ShopController.OpenShop()
		end
	end)
end

local closeShopRe = RemoteEvents and RemoteEvents:WaitForChild("CloseShop", 10)
if closeShopRe then
	closeShopRe.OnClientEvent:Connect(function()
		if ShopController then
			ShopController.CloseShop()
		end
	end)
end

-- ─────────────────────────────────────────────
--  KEYBOARD SHORTCUTS
-- ─────────────────────────────────────────────
local SHOP_KEY = Enum.KeyCode.E

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- gameProcessed = true means the user is typing in chat, a text box, etc.
	if gameProcessed then return end

	if input.KeyCode == SHOP_KEY then
		if ShopController then
			ShopController.ToggleShop()
		end
	end
end)

-- ─────────────────────────────────────────────
--  PROXIMITY DETECTION
--  Check each frame if the player is near a shop pad.
--  This drives the "Press E to open shop" hint in the HUD.
-- ─────────────────────────────────────────────
local SHOP_PROXIMITY_STUDS = 18

RunService.Heartbeat:Connect(function()
	if not ShopController then return end

	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local playerPos = hrp.Position
	local isNear    = false

	-- Check the lobby shop pad
	local lobby   = workspace:FindFirstChild("Lobby")
	local shopPad = lobby and lobby:FindFirstChild("ShopPad")
	if shopPad and shopPad:IsA("BasePart") then
		local dist = (playerPos - shopPad.Position).Magnitude
		if dist <= SHOP_PROXIMITY_STUDS then
			isNear = true
		end
	end

	-- Could also check per-plot shop pads here if added later
	ShopController.SetNearShop(isNear)
end)

print("[LocalInputHandler] Loaded. Press E to open/close shop.")
