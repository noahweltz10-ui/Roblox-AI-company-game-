--[[
	MainHUD.lua
	StarterGui > MainHUD (LocalScript)

	Builds and manages the main heads-up display:
	  - Cash display        – top-right corner, live-updating
	  - Income/s display    – below cash, shows current earnings rate
	  - Rebirth badge       – shows rebirth count next to player name area
	  - Rebirth button      – bottom-centre, hidden until player is eligible
	  - "Press E" hint      – appears when player is near a shop pad
	  - Shop shortcut button – bottom-left corner

	SETUP IN STUDIO:
	  1. In StarterGui, create a LocalScript named "MainHUD"
	  2. Paste this entire file into it
	  (The script creates its own ScreenGui — no manual UI objects needed)
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player = Players.LocalPlayer

-- ─────────────────────────────────────────────
--  WAIT FOR SHOPCONTROLLER
-- ─────────────────────────────────────────────
local function waitForGlobal(name, timeout)
	timeout = timeout or 20
	local elapsed = 0
	while not _G[name] and elapsed < timeout do
		task.wait(0.05)
		elapsed = elapsed + 0.05
	end
	return _G[name]
end

local ShopController = waitForGlobal("ShopController")
if not ShopController then
	warn("[MainHUD] ShopController not found — HUD may not update correctly.")
	ShopController = { GetCash = function() return 0 end, GetRebirthCount = function() return 0 end }
end

-- ─────────────────────────────────────────────
--  THEME CONSTANTS
-- ─────────────────────────────────────────────
local DARK_BG     = Color3.fromRGB(10,  15,  35)
local PANEL_BG    = Color3.fromRGB(16,  24,  50)
local ACCENT      = Color3.fromRGB(30,  140, 255)
local GOLD        = Color3.fromRGB(255, 195, 30)
local TEXT_WHITE  = Color3.fromRGB(255, 255, 255)
local TEXT_LIGHT  = Color3.fromRGB(180, 200, 230)
local TEXT_DIM    = Color3.fromRGB(120, 140, 175)
local OWNED_GREEN = Color3.fromRGB(30,  185, 85)

-- ─────────────────────────────────────────────
--  CURRENCY FORMATTER
-- ─────────────────────────────────────────────
local FORMATS = {
	{ threshold = 1e12, suffix = "T" },
	{ threshold = 1e9,  suffix = "B" },
	{ threshold = 1e6,  suffix = "M" },
	{ threshold = 1e3,  suffix = "K" },
}

local function formatCash(amount)
	amount = math.floor(amount)
	for _, fmt in ipairs(FORMATS) do
		if amount >= fmt.threshold then
			return string.format("$%.2f%s", amount / fmt.threshold, fmt.suffix)
		end
	end
	return string.format("$%s", tostring(amount):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

-- ─────────────────────────────────────────────
--  UI BUILDER HELPERS
-- ─────────────────────────────────────────────
local function makeCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function makeStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color      = color or ACCENT
	s.Thickness  = thickness or 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent     = parent
	return s
end

local function makeLabel(parent, text, size, color, font, position, anchorPoint)
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size          = size or UDim2.new(1, 0, 1, 0)
	lbl.Position      = position or UDim2.new(0, 0, 0, 0)
	lbl.AnchorPoint   = anchorPoint or Vector2.new(0, 0)
	lbl.Text          = text or ""
	lbl.TextColor3    = color or TEXT_WHITE
	lbl.Font          = font or Enum.Font.Gotham
	lbl.TextScaled    = true
	lbl.Parent        = parent
	return lbl
end

-- ─────────────────────────────────────────────
--  CREATE SCREENGUI
-- ─────────────────────────────────────────────
local playerGui = player:WaitForChild("PlayerGui")

local screenGui           = Instance.new("ScreenGui")
screenGui.Name            = "MainHUD"
screenGui.ResetOnSpawn    = false
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder    = 1
screenGui.Parent          = playerGui

-- ─────────────────────────────────────────────
--  CASH PANEL  (top-right)
-- ─────────────────────────────────────────────
local cashPanel = Instance.new("Frame")
cashPanel.Name            = "CashPanel"
cashPanel.Size            = UDim2.new(0, 240, 0, 88)
cashPanel.Position        = UDim2.new(1, -258, 0, 18)
cashPanel.AnchorPoint     = Vector2.new(0, 0)
cashPanel.BackgroundColor3 = PANEL_BG
cashPanel.BackgroundTransparency = 0.15
cashPanel.BorderSizePixel = 0
cashPanel.Parent          = screenGui
makeCorner(cashPanel, 10)
makeStroke(cashPanel, ACCENT, 1.5)

-- Subtle left accent bar
local accentBar = Instance.new("Frame")
accentBar.Name              = "AccentBar"
accentBar.Size              = UDim2.new(0, 4, 1, -16)
accentBar.Position          = UDim2.new(0, 8, 0, 8)
accentBar.BackgroundColor3  = ACCENT
accentBar.BorderSizePixel   = 0
accentBar.Parent            = cashPanel
makeCorner(accentBar, 2)

-- Cash label
local cashIcon = makeLabel(cashPanel, "💰", UDim2.new(0, 26, 0, 26),
	GOLD, Enum.Font.GothamBlack,
	UDim2.new(0, 20, 0, 12), Vector2.new(0, 0))
cashIcon.TextScaled = true

local cashValueLabel = makeLabel(cashPanel, "$0",
	UDim2.new(1, -55, 0, 34),
	TEXT_WHITE, Enum.Font.GothamBlack,
	UDim2.new(0, 50, 0, 8), Vector2.new(0, 0))
cashValueLabel.TextXAlignment = Enum.TextXAlignment.Left
cashValueLabel.TextScaled = true

-- "CASH" sub-label
local cashSubLabel = makeLabel(cashPanel, "CASH",
	UDim2.new(0, 60, 0, 16),
	TEXT_DIM, Enum.Font.GothamBold,
	UDim2.new(0, 50, 0, 44), Vector2.new(0, 0))
cashSubLabel.TextXAlignment = Enum.TextXAlignment.Left
cashSubLabel.TextScaled = false
cashSubLabel.TextSize  = 11

-- Income per second label
local incomeLabel = makeLabel(cashPanel, "+$1/s",
	UDim2.new(1, -55, 0, 18),
	OWNED_GREEN, Enum.Font.Gotham,
	UDim2.new(0, 50, 0, 60), Vector2.new(0, 0))
incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
incomeLabel.TextScaled = false
incomeLabel.TextSize  = 13

-- Rebirth count badge (shown on cash panel if rebirths > 0)
local rebirthBadge = Instance.new("Frame")
rebirthBadge.Name              = "RebirthBadge"
rebirthBadge.Size              = UDim2.new(0, 70, 0, 22)
rebirthBadge.Position          = UDim2.new(1, -78, 0, 10)
rebirthBadge.BackgroundColor3  = GOLD
rebirthBadge.BorderSizePixel   = 0
rebirthBadge.Visible           = false
rebirthBadge.Parent            = cashPanel
makeCorner(rebirthBadge, 11)

local rebirthBadgeLabel = makeLabel(rebirthBadge, "✦ x0",
	UDim2.new(1, 0, 1, 0),
	Color3.fromRGB(20, 15, 0), Enum.Font.GothamBlack)
rebirthBadgeLabel.TextScaled = false
rebirthBadgeLabel.TextSize   = 12

-- ─────────────────────────────────────────────
--  SHOP SHORTCUT BUTTON  (bottom-left)
-- ─────────────────────────────────────────────
local shopButton = Instance.new("TextButton")
shopButton.Name              = "ShopButton"
shopButton.Size              = UDim2.new(0, 140, 0, 46)
shopButton.Position          = UDim2.new(0, 18, 1, -64)
shopButton.AnchorPoint       = Vector2.new(0, 0)
shopButton.BackgroundColor3  = ACCENT
shopButton.BorderSizePixel   = 0
shopButton.Text              = "🛒  SHOP  [E]"
shopButton.TextColor3        = TEXT_WHITE
shopButton.Font              = Enum.Font.GothamBold
shopButton.TextSize          = 15
shopButton.Parent            = screenGui
makeCorner(shopButton, 10)

shopButton.MouseButton1Click:Connect(function()
	if ShopController then ShopController.ToggleShop() end
end)

-- Hover effect
shopButton.MouseEnter:Connect(function()
	TweenService:Create(shopButton, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(60, 165, 255)
	}):Play()
end)
shopButton.MouseLeave:Connect(function()
	TweenService:Create(shopButton, TweenInfo.new(0.15), {
		BackgroundColor3 = ACCENT
	}):Play()
end)

-- ─────────────────────────────────────────────
--  "PRESS E" SHOP HINT  (above shop button)
-- ─────────────────────────────────────────────
local shopHint = Instance.new("Frame")
shopHint.Name              = "ShopHint"
shopHint.Size              = UDim2.new(0, 200, 0, 36)
shopHint.Position          = UDim2.new(0, 18, 1, -110)
shopHint.BackgroundColor3  = DARK_BG
shopHint.BackgroundTransparency = 0.3
shopHint.BorderSizePixel   = 0
shopHint.Visible           = false
shopHint.Parent            = screenGui
makeCorner(shopHint, 8)
makeStroke(shopHint, ACCENT, 1)

local shopHintLabel = makeLabel(shopHint, "[E] Open Shop",
	UDim2.new(1, 0, 1, 0),
	ACCENT, Enum.Font.GothamBold)
shopHintLabel.TextScaled = false
shopHintLabel.TextSize   = 14

-- ─────────────────────────────────────────────
--  REBIRTH BUTTON  (bottom-centre, hidden until eligible)
-- ─────────────────────────────────────────────
local rebirthFrame = Instance.new("Frame")
rebirthFrame.Name              = "RebirthFrame"
rebirthFrame.Size              = UDim2.new(0, 300, 0, 72)
rebirthFrame.Position          = UDim2.new(0.5, 0, 1, -90)
rebirthFrame.AnchorPoint       = Vector2.new(0.5, 0)
rebirthFrame.BackgroundColor3  = Color3.fromRGB(12, 18, 40)
rebirthFrame.BackgroundTransparency = 0.2
rebirthFrame.BorderSizePixel   = 0
rebirthFrame.Visible           = false
rebirthFrame.Parent            = screenGui
makeCorner(rebirthFrame, 12)
makeStroke(rebirthFrame, GOLD, 2)

local rebirthTitle = makeLabel(rebirthFrame, "✦ REBIRTH AVAILABLE",
	UDim2.new(1, 0, 0, 22),
	GOLD, Enum.Font.GothamBold,
	UDim2.new(0, 0, 0, 5))
rebirthTitle.TextScaled = false
rebirthTitle.TextSize   = 13

local rebirthButton = Instance.new("TextButton")
rebirthButton.Name              = "RebirthButton"
rebirthButton.Size              = UDim2.new(1, -24, 0, 36)
rebirthButton.Position          = UDim2.new(0, 12, 0, 30)
rebirthButton.BackgroundColor3  = GOLD
rebirthButton.BorderSizePixel   = 0
rebirthButton.Text              = "✦  REBIRTH  (+2× Income Forever)"
rebirthButton.TextColor3        = Color3.fromRGB(20, 15, 0)
rebirthButton.Font              = Enum.Font.GothamBlack
rebirthButton.TextSize          = 14
rebirthButton.Parent            = rebirthFrame
makeCorner(rebirthButton, 8)

rebirthButton.MouseButton1Click:Connect(function()
	if ShopController then
		ShopController.RequestRebirth()
	end
end)

rebirthButton.MouseEnter:Connect(function()
	TweenService:Create(rebirthButton, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(255, 215, 60)
	}):Play()
end)
rebirthButton.MouseLeave:Connect(function()
	TweenService:Create(rebirthButton, TweenInfo.new(0.15), {
		BackgroundColor3 = GOLD
	}):Play()
end)

-- ─────────────────────────────────────────────
--  TOTAL EARNED PANEL  (under cash panel)
-- ─────────────────────────────────────────────
local totalEarnedPanel = Instance.new("Frame")
totalEarnedPanel.Name              = "TotalEarnedPanel"
totalEarnedPanel.Size              = UDim2.new(0, 240, 0, 34)
totalEarnedPanel.Position          = UDim2.new(1, -258, 0, 115)
totalEarnedPanel.BackgroundColor3  = PANEL_BG
totalEarnedPanel.BackgroundTransparency = 0.25
totalEarnedPanel.BorderSizePixel   = 0
totalEarnedPanel.Parent            = screenGui
makeCorner(totalEarnedPanel, 8)

local totalEarnedLabel = makeLabel(totalEarnedPanel, "Total Earned: $0",
	UDim2.new(1, -16, 1, 0),
	TEXT_DIM, Enum.Font.Gotham,
	UDim2.new(0, 8, 0, 0))
totalEarnedLabel.TextXAlignment = Enum.TextXAlignment.Left
totalEarnedLabel.TextScaled = false
totalEarnedLabel.TextSize   = 13

-- ─────────────────────────────────────────────
--  INCOME RATE UPDATE
--  We request income rate from server every 5 seconds to keep it accurate.
-- ─────────────────────────────────────────────
local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents", 15)
local requestIncome = RemoteEvents and RemoteEvents:FindFirstChild("RequestIncome")
local incomeResponse = RemoteEvents and RemoteEvents:WaitForChild("IncomeResponse", 10)

if incomeResponse then
	incomeResponse.OnClientEvent:Connect(function(incomePerSecond)
		incomeLabel.Text = string.format("+%s/s", formatCash(incomePerSecond):gsub("%$", ""))
	end)
end

task.spawn(function()
	while true do
		task.wait(5)
		if requestIncome then
			requestIncome:FireServer()
		end
	end
end)

-- ─────────────────────────────────────────────
--  REBIRTH ELIGIBILITY
-- ─────────────────────────────────────────────
local rebirthEligibleRe = RemoteEvents and RemoteEvents:WaitForChild("RebirthEligible", 10)
if rebirthEligibleRe then
	rebirthEligibleRe.OnClientEvent:Connect(function(eligible)
		if eligible and not rebirthFrame.Visible then
			-- Animate in
			rebirthFrame.Visible = true
			rebirthFrame.Position = UDim2.new(0.5, 0, 1, 0)
			TweenService:Create(rebirthFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, 1, -90)
			}):Play()
		end
	end)
end

-- ─────────────────────────────────────────────
--  SHOPCONTROLLER CALLBACKS
-- ─────────────────────────────────────────────
if ShopController then
	-- Update cash display whenever cash changes
	ShopController.OnCashChanged(function(cash, totalEarned)
		cashValueLabel.Text    = formatCash(cash)
		totalEarnedLabel.Text  = "Total Earned: " .. formatCash(totalEarned)
	end)

	-- Show/hide "near shop" hint
	ShopController.OnNearShopChanged(function(isNear)
		shopHint.Visible = isNear
	end)

	-- On rebirth: hide the rebirth button, update badge
	ShopController.OnRebirthOccurred(function(newCount)
		-- Slide out rebirth button
		TweenService:Create(rebirthFrame, TweenInfo.new(0.3), {
			Position = UDim2.new(0.5, 0, 1, 0)
		}):Play()
		task.wait(0.35)
		rebirthFrame.Visible = false

		-- Show rebirth badge
		rebirthBadge.Visible       = true
		rebirthBadgeLabel.Text     = string.format("✦ x%d", newCount)
	end)

	-- Initial data load — show badge if already has rebirths
	ShopController.OnDataLoaded(function(stateData)
		if (stateData.rebirthCount or 0) > 0 then
			rebirthBadge.Visible   = true
			rebirthBadgeLabel.Text = string.format("✦ x%d", stateData.rebirthCount)
		end
		-- Initial cash display
		cashValueLabel.Text   = formatCash(stateData.cash or 0)
		totalEarnedLabel.Text = "Total Earned: " .. formatCash(stateData.totalEarned or 0)
	end)
end

print("[MainHUD] Loaded.")
