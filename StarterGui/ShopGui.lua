--[[
	ShopGui.lua
	StarterGui > ShopGui (LocalScript)

	Builds and manages the full shop interface for AI Empire Tycoon.

	TABS:
	  1. Office Upgrades  – linear progression (Laptop → Global HQ)
	  2. Employees        – hirable staff with income bonuses
	  3. Luxury Items     – 40+ status items in a filterable grid

	FEATURES:
	  - Live affordability check: buy buttons grey out if player can't afford
	  - OWNED state: purchased items show a green ✓ OWNED button
	  - Rarity labels: Common (white), Rare (blue), Epic (purple), Legendary (gold)
	  - Luxury sub-category filter: All / Vehicles / Watercraft / Aircraft / Property / Exotic
	  - Smooth open/close animation
	  - All purchases send RemoteEvents via ShopController

	SETUP IN STUDIO:
	  1. In StarterGui, create a LocalScript named "ShopGui"
	  2. Paste this entire file into it
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
	error("[ShopGui] ShopController not found after waiting. Check StarterPlayerScripts.")
end

-- ─────────────────────────────────────────────
--  CONFIG
-- ─────────────────────────────────────────────
local GameConfig   = require(ReplicatedStorage:WaitForChild("GameConfig",   10))
local LuxuryConfig = require(ReplicatedStorage:WaitForChild("LuxuryConfig", 10))

-- ─────────────────────────────────────────────
--  THEME
-- ─────────────────────────────────────────────
local C = {
	darkBg      = Color3.fromRGB(8,   13,  32),
	panelBg     = Color3.fromRGB(14,  22,  50),
	panelLight  = Color3.fromRGB(22,  34,  68),
	panelMid    = Color3.fromRGB(18,  28,  58),
	accent      = Color3.fromRGB(30,  140, 255),
	accentHover = Color3.fromRGB(60,  165, 255),
	accentDark  = Color3.fromRGB(18,  95,  185),
	gold        = Color3.fromRGB(255, 195, 30),
	green       = Color3.fromRGB(30,  185, 80),
	red         = Color3.fromRGB(225, 60,  60),
	textWhite   = Color3.fromRGB(255, 255, 255),
	textLight   = Color3.fromRGB(175, 198, 232),
	textDim     = Color3.fromRGB(110, 132, 170),
	border      = Color3.fromRGB(36,  56,  110),
	tabActive   = Color3.fromRGB(30,  140, 255),
	tabInactive = Color3.fromRGB(22,  34,  68),
	cantAfford  = Color3.fromRGB(50,  58,  82),
	owned       = Color3.fromRGB(22,  130, 58),
	scroll      = Color3.fromRGB(30,  140, 255),
}

local RARITY = {
	Common    = { color = Color3.fromRGB(190, 195, 205), bg = Color3.fromRGB(50, 55, 75)  },
	Rare      = { color = Color3.fromRGB(80,  140, 255), bg = Color3.fromRGB(20, 40, 100) },
	Epic      = { color = Color3.fromRGB(165, 80,  255), bg = Color3.fromRGB(45, 20, 90)  },
	Legendary = { color = Color3.fromRGB(255, 195, 30),  bg = Color3.fromRGB(80, 55, 0)   },
}

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
	amount = math.floor(amount or 0)
	for _, fmt in ipairs(FORMATS) do
		if amount >= fmt.threshold then
			return string.format("$%.2f%s", amount / fmt.threshold, fmt.suffix)
		end
	end
	return "$" .. tostring(amount):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

-- ─────────────────────────────────────────────
--  UI HELPERS
-- ─────────────────────────────────────────────
local function corner(parent, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = parent; return c end
local function stroke(parent, color, t) local s = Instance.new("UIStroke"); s.Color = color; s.Thickness = t or 1.5; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = parent; return s end
local function padding(parent, top, right, bottom, left) local p = Instance.new("UIPadding"); p.PaddingTop = UDim.new(0, top or 0); p.PaddingRight = UDim.new(0, right or top or 0); p.PaddingBottom = UDim.new(0, bottom or top or 0); p.PaddingLeft = UDim.new(0, left or right or top or 0); p.Parent = parent; return p end

local function label(parent, text, color, font, size, xalign)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text          = text or ""
	l.TextColor3    = color or C.textWhite
	l.Font          = font or Enum.Font.Gotham
	l.TextSize      = size or 14
	l.TextXAlignment = xalign or Enum.TextXAlignment.Left
	l.TextScaled    = false
	l.TextTruncate  = Enum.TextTruncate.AtEnd
	l.Size          = UDim2.new(1, 0, 1, 0)
	l.Parent        = parent
	return l
end

local function makeButton(parent, text, bgColor, textColor, fontSize)
	local btn = Instance.new("TextButton")
	btn.BackgroundColor3 = bgColor or C.accent
	btn.BorderSizePixel  = 0
	btn.Text             = text or ""
	btn.TextColor3       = textColor or C.textWhite
	btn.Font             = Enum.Font.GothamBold
	btn.TextSize         = fontSize or 14
	btn.TextScaled       = false
	btn.AutoButtonColor  = false
	btn.Parent           = parent
	corner(btn, 8)
	return btn
end

-- ─────────────────────────────────────────────
--  SCREENGUI
-- ─────────────────────────────────────────────
local playerGui = player:WaitForChild("PlayerGui")

local screenGui          = Instance.new("ScreenGui")
screenGui.Name           = "ShopGui"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder   = 10   -- above leaderboard and HUD
screenGui.Enabled        = false  -- starts hidden
screenGui.Parent         = playerGui

-- ─────────────────────────────────────────────
--  BACKDROP  (semi-transparent overlay)
-- ─────────────────────────────────────────────
local backdrop = Instance.new("Frame")
backdrop.Name                = "Backdrop"
backdrop.Size                = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3    = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 0.55
backdrop.BorderSizePixel     = 0
backdrop.Parent              = screenGui

-- Click backdrop to close shop
local backdropBtn = Instance.new("TextButton")
backdropBtn.Size                = UDim2.new(1, 0, 1, 0)
backdropBtn.BackgroundTransparency = 1
backdropBtn.Text                = ""
backdropBtn.Parent              = backdrop
backdropBtn.MouseButton1Click:Connect(function()
	ShopController.CloseShop()
end)

-- ─────────────────────────────────────────────
--  MAIN SHOP FRAME
-- ─────────────────────────────────────────────
local SHOP_W = 720
local SHOP_H = 560

local shopFrame = Instance.new("Frame")
shopFrame.Name              = "ShopFrame"
shopFrame.Size              = UDim2.new(0, SHOP_W, 0, SHOP_H)
shopFrame.Position          = UDim2.new(0.5, 0, 0.5, 0)
shopFrame.AnchorPoint       = Vector2.new(0.5, 0.5)
shopFrame.BackgroundColor3  = C.panelBg
shopFrame.BorderSizePixel   = 0
shopFrame.Parent            = screenGui
corner(shopFrame, 14)
stroke(shopFrame, C.border, 2)

-- ─────────────────────────────────────────────
--  TITLE BAR
-- ─────────────────────────────────────────────
local TITLEBAR_H = 52

local titleBar = Instance.new("Frame")
titleBar.Name              = "TitleBar"
titleBar.Size              = UDim2.new(1, 0, 0, TITLEBAR_H)
titleBar.BackgroundColor3  = C.accentDark
titleBar.BorderSizePixel   = 0
titleBar.Parent            = shopFrame
corner(titleBar, 14)

-- Cover bottom corners of title bar
local titleBarCover = Instance.new("Frame")
titleBarCover.Size              = UDim2.new(1, 0, 0, 14)
titleBarCover.Position          = UDim2.new(0, 0, 1, -14)
titleBarCover.BackgroundColor3  = C.accentDark
titleBarCover.BorderSizePixel   = 0
titleBarCover.Parent            = titleBar

local titleIcon = Instance.new("TextLabel")
titleIcon.BackgroundTransparency = 1
titleIcon.Size     = UDim2.new(0, 38, 0, 38)
titleIcon.Position = UDim2.new(0, 14, 0.5, 0)
titleIcon.AnchorPoint = Vector2.new(0, 0.5)
titleIcon.Text     = "🤖"
titleIcon.TextSize = 26
titleIcon.Font     = Enum.Font.GothamBold
titleIcon.TextScaled = false
titleIcon.Parent   = titleBar

local titleText = Instance.new("TextLabel")
titleText.BackgroundTransparency = 1
titleText.Size     = UDim2.new(1, -120, 1, 0)
titleText.Position = UDim2.new(0, 56, 0, 0)
titleText.Text     = "AI EMPIRE TYCOON  —  SHOP"
titleText.TextColor3 = C.textWhite
titleText.Font     = Enum.Font.GothamBlack
titleText.TextSize = 18
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.TextScaled = false
titleText.Parent   = titleBar

-- Cash display in title bar
local titleCash = Instance.new("TextLabel")
titleCash.BackgroundTransparency = 1
titleCash.Size     = UDim2.new(0, 160, 0, 26)
titleCash.Position = UDim2.new(1, -220, 0.5, 0)
titleCash.AnchorPoint = Vector2.new(0, 0.5)
titleCash.Text     = "💰 $0"
titleCash.TextColor3 = C.gold
titleCash.Font     = Enum.Font.GothamBold
titleCash.TextSize = 15
titleCash.TextXAlignment = Enum.TextXAlignment.Right
titleCash.TextScaled = false
titleCash.Parent   = titleBar

-- Close button
local closeBtn = makeButton(titleBar, "✕", Color3.fromRGB(200, 50, 50), C.textWhite, 16)
closeBtn.Size     = UDim2.new(0, 42, 0, 34)
closeBtn.Position = UDim2.new(1, -52, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(0, 0.5)
closeBtn.MouseButton1Click:Connect(function()
	ShopController.CloseShop()
end)
closeBtn.MouseEnter:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(230, 80, 80) }):Play()
end)
closeBtn.MouseLeave:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(200, 50, 50) }):Play()
end)

-- ─────────────────────────────────────────────
--  TAB BAR
-- ─────────────────────────────────────────────
local TAB_BAR_H = 46
local TAB_NAMES = { "Office", "Employees", "Luxury" }

local tabBar = Instance.new("Frame")
tabBar.Name              = "TabBar"
tabBar.Size              = UDim2.new(1, 0, 0, TAB_BAR_H)
tabBar.Position          = UDim2.new(0, 0, 0, TITLEBAR_H)
tabBar.BackgroundColor3  = C.darkBg
tabBar.BorderSizePixel   = 0
tabBar.Parent            = shopFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection  = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabLayout.SortOrder      = Enum.SortOrder.LayoutOrder
tabLayout.Padding        = UDim.new(0, 2)
tabLayout.Parent         = tabBar
padding(tabBar, 6, 8, 6, 8)

local tabButtons = {}  -- { [tabName] = button }
local activeTab  = "Office"

local function setTabActive(name)
	for tName, btn in pairs(tabButtons) do
		local isActive = (tName == name)
		btn.BackgroundColor3 = isActive and C.tabActive or C.tabInactive
		btn.TextColor3       = isActive and C.textWhite or C.textDim
		btn.Font             = isActive and Enum.Font.GothamBold or Enum.Font.Gotham
	end
	activeTab = name
end

-- ─────────────────────────────────────────────
--  CONTENT AREA
-- ─────────────────────────────────────────────
local CONTENT_Y = TITLEBAR_H + TAB_BAR_H
local CONTENT_H = SHOP_H - CONTENT_Y

local contentArea = Instance.new("Frame")
contentArea.Name              = "ContentArea"
contentArea.Size              = UDim2.new(1, 0, 0, CONTENT_H)
contentArea.Position          = UDim2.new(0, 0, 0, CONTENT_Y)
contentArea.BackgroundColor3  = C.panelMid
contentArea.BorderSizePixel   = 0
contentArea.ClipsDescendants  = true
contentArea.Parent            = shopFrame

-- ─────────────────────────────────────────────
--  SCROLL FRAME FACTORY
-- ─────────────────────────────────────────────
local function makeScrollFrame(parent, scrollH)
	local sf = Instance.new("ScrollingFrame")
	sf.Size              = UDim2.new(1, 0, 1, 0)
	sf.BackgroundTransparency = 1
	sf.BorderSizePixel   = 0
	sf.ScrollBarThickness = 6
	sf.ScrollBarImageColor3 = C.accent
	sf.CanvasSize        = UDim2.new(0, 0, 0, scrollH or 0)
	sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sf.ScrollingDirection = Enum.ScrollingDirection.Y
	sf.Parent            = parent
	return sf
end

-- ─────────────────────────────────────────────
--  ITEM CARD BUILDERS
--  Returns a table with an "update" function that refreshes button state.
-- ─────────────────────────────────────────────

-- Tracks all card updaters so we can refresh all buttons when cash changes
local allCardUpdaters = {}

-- ── LIST CARD (for Office and Employee tabs) ──────────────────
local function makeListCard(parent, config, isEmployee)
	local CARD_H = 115

	local card = Instance.new("Frame")
	card.Size              = UDim2.new(1, -20, 0, CARD_H)
	card.BackgroundColor3  = C.panelLight
	card.BorderSizePixel   = 0
	card.LayoutOrder       = config.order or 99
	card.Parent            = parent
	corner(card, 10)
	stroke(card, C.border, 1)

	-- Left colour accent bar
	local rarityStr = config.rarity or "Common"
	local rarityData = RARITY[rarityStr] or RARITY.Common
	local accentBar = Instance.new("Frame")
	accentBar.Size              = UDim2.new(0, 5, 1, -16)
	accentBar.Position          = UDim2.new(0, 0, 0, 8)
	accentBar.BackgroundColor3  = rarityData.color
	accentBar.BorderSizePixel   = 0
	accentBar.Parent            = card
	corner(accentBar, 3)

	-- Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size     = UDim2.new(1, -220, 0, 24)
	nameLabel.Position = UDim2.new(0, 18, 0, 12)
	nameLabel.Text     = config.name or "?"
	nameLabel.TextColor3 = C.textWhite
	nameLabel.Font     = Enum.Font.GothamBlack
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextScaled = false
	nameLabel.Parent   = card

	-- Rarity badge
	local rarityBadge = Instance.new("Frame")
	rarityBadge.Size              = UDim2.new(0, 85, 0, 22)
	rarityBadge.Position          = UDim2.new(0, 18, 0, 38)
	rarityBadge.BackgroundColor3  = rarityData.bg
	rarityBadge.BorderSizePixel   = 0
	rarityBadge.Parent            = card
	corner(rarityBadge, 11)
	stroke(rarityBadge, rarityData.color, 1)

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Size     = UDim2.new(1, 0, 1, 0)
	rarityLabel.Text     = "◆  " .. (rarityStr:upper())
	rarityLabel.TextColor3 = rarityData.color
	rarityLabel.Font     = Enum.Font.GothamBold
	rarityLabel.TextSize = 11
	rarityLabel.TextScaled = false
	rarityLabel.Parent   = rarityBadge

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.BackgroundTransparency = 1
	descLabel.Size     = UDim2.new(1, -220, 0, 30)
	descLabel.Position = UDim2.new(0, 18, 0, 63)
	descLabel.Text     = config.description or ""
	descLabel.TextColor3 = C.textDim
	descLabel.Font     = Enum.Font.Gotham
	descLabel.TextSize = 12
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.TextScaled = false
	descLabel.Parent   = card

	-- Income bonus / rate label
	local bonusText = ""
	if isEmployee then
		bonusText = string.format("+$%d/s per hire", config.incomeBonus or 0)
	else
		bonusText = string.format("+$%d/s income", config.incomeRate or 0)
	end
	local bonusLabel = Instance.new("TextLabel")
	bonusLabel.BackgroundTransparency = 1
	bonusLabel.Size     = UDim2.new(0, 150, 0, 18)
	bonusLabel.Position = UDim2.new(0, 115, 0, 40)
	bonusLabel.Text     = bonusText
	bonusLabel.TextColor3 = Color3.fromRGB(100, 215, 130)
	bonusLabel.Font     = Enum.Font.GothamBold
	bonusLabel.TextSize = 12
	bonusLabel.TextXAlignment = Enum.TextXAlignment.Left
	bonusLabel.TextScaled = false
	bonusLabel.Parent   = card

	-- Price label (right side)
	local priceStr = config.price == 0 and "FREE" or formatCash(config.price)
	local priceLabel = Instance.new("TextLabel")
	priceLabel.BackgroundTransparency = 1
	priceLabel.Size     = UDim2.new(0, 140, 0, 28)
	priceLabel.Position = UDim2.new(1, -200, 0, 14)
	priceLabel.Text     = priceStr
	priceLabel.TextColor3 = C.gold
	priceLabel.Font     = Enum.Font.GothamBlack
	priceLabel.TextSize = 18
	priceLabel.TextXAlignment = Enum.TextXAlignment.Right
	priceLabel.TextScaled = false
	priceLabel.Parent   = card

	-- Buy / Owned button
	local buyBtn = makeButton(card, "Buy  " .. priceStr, C.accent, C.textWhite, 14)
	buyBtn.Size     = UDim2.new(0, 175, 0, 38)
	buyBtn.Position = UDim2.new(1, -190, 0.5, 0)
	buyBtn.AnchorPoint = Vector2.new(0, 0.5)

	-- Employee count badge (shown next to buy button for repeat-hireable items)
	local countBadge = nil
	if isEmployee then
		countBadge = Instance.new("TextLabel")
		countBadge.BackgroundTransparency = 1
		countBadge.Size     = UDim2.new(0, 80, 0, 20)
		countBadge.Position = UDim2.new(1, -200, 1, -26)
		countBadge.Text     = "Owned: 0"
		countBadge.TextColor3 = C.textDim
		countBadge.Font     = Enum.Font.Gotham
		countBadge.TextSize = 11
		countBadge.TextXAlignment = Enum.TextXAlignment.Right
		countBadge.TextScaled = false
		countBadge.Parent   = card
	end

	-- Update function — called when cash changes or purchase resolves
	local function updateCard()
		local price = config.price or 0
		local id    = config.id

		if isEmployee then
			-- Employees can be bought multiple times
			local count    = ShopController.GetEmployeeCount(id)
			local canAfford = ShopController.CanAfford(price)

			if countBadge then
				countBadge.Text = count > 0 and string.format("Hired: %d", count) or ""
				countBadge.TextColor3 = count > 0 and Color3.fromRGB(100, 215, 130) or C.textDim
			end

			if canAfford then
				buyBtn.BackgroundColor3 = C.accent
				buyBtn.TextColor3       = C.textWhite
				buyBtn.Text             = "Hire  " .. priceStr
				buyBtn.Active           = true
			else
				buyBtn.BackgroundColor3 = C.cantAfford
				buyBtn.TextColor3       = C.textDim
				buyBtn.Text             = "Hire  " .. priceStr
				buyBtn.Active           = false
			end
		else
			-- Upgrades can only be purchased once
			local owned    = ShopController.OwnsUpgrade(id)
			local canAfford = ShopController.CanAfford(price) and not owned

			if owned then
				buyBtn.BackgroundColor3 = C.owned
				buyBtn.TextColor3       = C.textWhite
				buyBtn.Text             = "✓  OWNED"
				buyBtn.Active           = false
			elseif ShopController.CanAfford(price) then
				buyBtn.BackgroundColor3 = C.accent
				buyBtn.TextColor3       = C.textWhite
				buyBtn.Text             = "Buy  " .. priceStr
				buyBtn.Active           = true
			else
				buyBtn.BackgroundColor3 = C.cantAfford
				buyBtn.TextColor3       = C.textDim
				buyBtn.Text             = "Buy  " .. priceStr
				buyBtn.Active           = false
			end
			_ = canAfford  -- suppress unused warning
		end
	end

	-- Wire buy button
	buyBtn.MouseButton1Click:Connect(function()
		if not buyBtn.Active then return end
		local id = config.id
		if isEmployee then
			ShopController.BuyEmployee(id)
		else
			ShopController.BuyUpgrade(id)
		end
	end)

	buyBtn.MouseEnter:Connect(function()
		if buyBtn.Active then
			TweenService:Create(buyBtn, TweenInfo.new(0.1), { BackgroundColor3 = C.accentHover }):Play()
		end
	end)
	buyBtn.MouseLeave:Connect(function()
		updateCard()
	end)

	table.insert(allCardUpdaters, updateCard)
	updateCard()

	return { frame = card, update = updateCard }
end

-- ── GRID CARD (for Luxury tab) ────────────────────────────────
local function makeGridCard(parent, itemConfig)
	local CARD_W = 195
	local CARD_H = 230

	local rarity     = itemConfig.rarity or LuxuryConfig.GetRarity(itemConfig.price)
	if type(rarity) ~= "string" then rarity = "Common" end
	local rarityData = RARITY[rarity] or RARITY.Common
	local priceStr   = formatCash(itemConfig.price)

	local card = Instance.new("Frame")
	card.Size              = UDim2.new(0, CARD_W, 0, CARD_H)
	card.BackgroundColor3  = C.panelLight
	card.BorderSizePixel   = 0
	card.Parent            = parent
	corner(card, 10)
	stroke(card, rarityData.color, 1.2)

	-- Top colour bar (rarity colour)
	local topBar = Instance.new("Frame")
	topBar.Size              = UDim2.new(1, 0, 0, 6)
	topBar.BackgroundColor3  = rarityData.color
	topBar.BorderSizePixel   = 0
	topBar.Parent            = card
	corner(topBar, 4)

	-- Rarity badge
	local rarityBadge = Instance.new("Frame")
	rarityBadge.Size              = UDim2.new(1, -20, 0, 22)
	rarityBadge.Position          = UDim2.new(0, 10, 0, 12)
	rarityBadge.BackgroundColor3  = rarityData.bg
	rarityBadge.BorderSizePixel   = 0
	rarityBadge.Parent            = card
	corner(rarityBadge, 11)
	stroke(rarityBadge, rarityData.color, 1)

	local rarityLbl = Instance.new("TextLabel")
	rarityLbl.BackgroundTransparency = 1
	rarityLbl.Size     = UDim2.new(1, 0, 1, 0)
	rarityLbl.Text     = "◆  " .. rarity:upper()
	rarityLbl.TextColor3 = rarityData.color
	rarityLbl.Font     = Enum.Font.GothamBold
	rarityLbl.TextSize = 10
	rarityLbl.TextScaled = false
	rarityLbl.Parent   = rarityBadge

	-- Item name
	local nameLbl = Instance.new("TextLabel")
	nameLbl.BackgroundTransparency = 1
	nameLbl.Size     = UDim2.new(1, -16, 0, 36)
	nameLbl.Position = UDim2.new(0, 8, 0, 40)
	nameLbl.Text     = itemConfig.name or "?"
	nameLbl.TextColor3 = C.textWhite
	nameLbl.Font     = Enum.Font.GothamBold
	nameLbl.TextSize = 14
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.TextWrapped = true
	nameLbl.TextScaled = false
	nameLbl.Parent   = card

	-- Description
	local descLbl = Instance.new("TextLabel")
	descLbl.BackgroundTransparency = 1
	descLbl.Size     = UDim2.new(1, -16, 0, 60)
	descLbl.Position = UDim2.new(0, 8, 0, 80)
	descLbl.Text     = itemConfig.description or ""
	descLbl.TextColor3 = C.textDim
	descLbl.Font     = Enum.Font.Gotham
	descLbl.TextSize = 11
	descLbl.TextXAlignment = Enum.TextXAlignment.Left
	descLbl.TextWrapped = true
	descLbl.TextScaled = false
	descLbl.Parent   = card

	-- Price
	local priceLbl = Instance.new("TextLabel")
	priceLbl.BackgroundTransparency = 1
	priceLbl.Size     = UDim2.new(1, -16, 0, 22)
	priceLbl.Position = UDim2.new(0, 8, 0, 146)
	priceLbl.Text     = priceStr
	priceLbl.TextColor3 = C.gold
	priceLbl.Font     = Enum.Font.GothamBlack
	priceLbl.TextSize = 16
	priceLbl.TextXAlignment = Enum.TextXAlignment.Left
	priceLbl.TextScaled = false
	priceLbl.Parent   = card

	-- Buy button
	local buyBtn = makeButton(card, "Buy", C.accent, C.textWhite, 13)
	buyBtn.Size     = UDim2.new(1, -16, 0, 34)
	buyBtn.Position = UDim2.new(0, 8, 0, 172)

	local function updateCard()
		local owned     = ShopController.OwnsLuxury(itemConfig.id)
		local canAfford = ShopController.CanAfford(itemConfig.price)

		if owned then
			buyBtn.BackgroundColor3 = C.owned
			buyBtn.TextColor3       = C.textWhite
			buyBtn.Text             = "✓  OWNED"
			buyBtn.Active           = false
			stroke(card, rarityData.color, 2.5)
		elseif canAfford then
			buyBtn.BackgroundColor3 = C.accent
			buyBtn.TextColor3       = C.textWhite
			buyBtn.Text             = "Buy  " .. priceStr
			buyBtn.Active           = true
			stroke(card, rarityData.color, 1.2)
		else
			buyBtn.BackgroundColor3 = C.cantAfford
			buyBtn.TextColor3       = C.textDim
			buyBtn.Text             = "Buy  " .. priceStr
			buyBtn.Active           = false
			stroke(card, C.border, 1)
		end
	end

	buyBtn.MouseButton1Click:Connect(function()
		if not buyBtn.Active then return end
		ShopController.BuyLuxury(itemConfig.id)
	end)

	buyBtn.MouseEnter:Connect(function()
		if buyBtn.Active then
			TweenService:Create(buyBtn, TweenInfo.new(0.1), { BackgroundColor3 = C.accentHover }):Play()
		end
	end)
	buyBtn.MouseLeave:Connect(function()
		updateCard()
	end)

	table.insert(allCardUpdaters, updateCard)
	updateCard()

	return { frame = card, update = updateCard }
end

-- ─────────────────────────────────────────────
--  BUILD TAB PAGES
-- ─────────────────────────────────────────────
local tabPages = {}  -- { [tabName] = Frame }

local function buildOfficeTab()
	local page = Instance.new("Frame")
	page.Name              = "OfficePage"
	page.Size              = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.Visible           = false
	page.Parent            = contentArea

	local scroll = makeScrollFrame(page)
	local list   = Instance.new("UIListLayout")
	list.FillDirection         = Enum.FillDirection.Vertical
	list.HorizontalAlignment   = Enum.HorizontalAlignment.Center
	list.SortOrder             = Enum.SortOrder.LayoutOrder
	list.Padding               = UDim.new(0, 10)
	list.Parent                = scroll
	padding(scroll, 12, 10, 12, 10)

	for _, upgrade in ipairs(GameConfig.OfficeUpgrades) do
		-- Assign rarity based on price tier
		local rarity = "Common"
		local _, _, r = pcall(LuxuryConfig.GetRarity, upgrade.price)  -- reuse helper
		if upgrade.price == 0 then rarity = "Common"
		elseif upgrade.price < 500000 then rarity = "Common"
		elseif upgrade.price < 5000000 then rarity = "Rare"
		elseif upgrade.price < 25000000 then rarity = "Epic"
		else rarity = "Legendary" end
		upgrade.rarity = rarity

		makeListCard(scroll, upgrade, false)
	end

	return page
end

local function buildEmployeesTab()
	local page = Instance.new("Frame")
	page.Name              = "EmployeesPage"
	page.Size              = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.Visible           = false
	page.Parent            = contentArea

	local scroll = makeScrollFrame(page)
	local list   = Instance.new("UIListLayout")
	list.FillDirection         = Enum.FillDirection.Vertical
	list.HorizontalAlignment   = Enum.HorizontalAlignment.Center
	list.SortOrder             = Enum.SortOrder.LayoutOrder
	list.Padding               = UDim.new(0, 10)
	list.Parent                = scroll
	padding(scroll, 12, 10, 12, 10)

	for _, emp in ipairs(GameConfig.Employees) do
		-- Assign rarity
		if emp.price < 500000 then emp.rarity = "Common"
		elseif emp.price < 5000000 then emp.rarity = "Rare"
		else emp.rarity = "Epic" end

		makeListCard(scroll, emp, true)
	end

	return page
end

local function buildLuxuryTab()
	local page = Instance.new("Frame")
	page.Name              = "LuxuryPage"
	page.Size              = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.Visible           = false
	page.Parent            = contentArea

	-- Sub-category filter bar
	local FILTER_H = 46
	local filterBar = Instance.new("Frame")
	filterBar.Name              = "FilterBar"
	filterBar.Size              = UDim2.new(1, 0, 0, FILTER_H)
	filterBar.BackgroundColor3  = C.darkBg
	filterBar.BorderSizePixel   = 0
	filterBar.Parent            = page

	local filterLayout = Instance.new("UIListLayout")
	filterLayout.FillDirection       = Enum.FillDirection.Horizontal
	filterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	filterLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	filterLayout.Padding             = UDim.new(0, 4)
	filterLayout.Parent              = filterBar
	padding(filterBar, 8, 8, 8, 8)

	-- Grid area below filter bar
	local gridScroll = makeScrollFrame(
		Instance.new("Frame") -- wrapper frame
	)
	local gridWrapper = gridScroll.Parent
	gridWrapper.Name              = "GridWrapper"
	gridWrapper.Size              = UDim2.new(1, 0, 1, -FILTER_H)
	gridWrapper.Position          = UDim2.new(0, 0, 0, FILTER_H)
	gridWrapper.BackgroundTransparency = 1
	gridWrapper.Parent            = page
	gridScroll.Parent             = gridWrapper

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize           = UDim2.new(0, 195, 0, 230)
	gridLayout.CellPadding        = UDim2.new(0, 10, 0, 10)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.SortOrder          = Enum.SortOrder.LayoutOrder
	gridLayout.Parent             = gridScroll
	padding(gridScroll, 10, 10, 10, 10)

	-- Build all grid cards and store refs by category
	local allCards = {}  -- { card = { frame, update }, category = "..." }
	for _, item in ipairs(LuxuryConfig.Items) do
		local cardData = makeGridCard(gridScroll, item)
		table.insert(allCards, { card = cardData, category = item.category })
	end

	-- Filter buttons
	local activeFilter    = "All"
	local filterButtons   = {}

	local function applyFilter(category)
		activeFilter = category
		for _, btn in pairs(filterButtons) do
			btn.BackgroundColor3 = C.tabInactive
			btn.TextColor3       = C.textDim
			btn.Font             = Enum.Font.Gotham
		end
		local activeBtn = filterButtons[category]
		if activeBtn then
			activeBtn.BackgroundColor3 = C.accent
			activeBtn.TextColor3       = C.textWhite
			activeBtn.Font             = Enum.Font.GothamBold
		end

		-- Show/hide cards based on filter
		for _, entry in ipairs(allCards) do
			local show = (category == "All") or (entry.category == category)
			entry.card.frame.Visible = show
		end
	end

	for i, catName in ipairs(LuxuryConfig.Categories) do
		local filterBtn = makeButton(filterBar, catName, C.tabInactive, C.textDim, 13)
		filterBtn.Size        = UDim2.new(0, 90, 0, FILTER_H - 16)
		filterBtn.LayoutOrder = i
		filterBtn.Font        = Enum.Font.Gotham
		filterButtons[catName] = filterBtn

		filterBtn.MouseButton1Click:Connect(function()
			applyFilter(catName)
		end)
		filterBtn.MouseEnter:Connect(function()
			if activeFilter ~= catName then
				TweenService:Create(filterBtn, TweenInfo.new(0.1), { BackgroundColor3 = C.panelLight }):Play()
			end
		end)
		filterBtn.MouseLeave:Connect(function()
			if activeFilter ~= catName then
				TweenService:Create(filterBtn, TweenInfo.new(0.1), { BackgroundColor3 = C.tabInactive }):Play()
			end
		end)
	end

	applyFilter("All")  -- start on All tab

	return page
end

-- ─────────────────────────────────────────────
--  ASSEMBLE TABS
-- ─────────────────────────────────────────────
tabPages["Office"]    = buildOfficeTab()
tabPages["Employees"] = buildEmployeesTab()
tabPages["Luxury"]    = buildLuxuryTab()

-- Build tab buttons now that pages exist
for i, tabName in ipairs(TAB_NAMES) do
	local btn = makeButton(tabBar, tabName, C.tabInactive, C.textDim, 15)
	btn.Size        = UDim2.new(0, 150, 1, 0)
	btn.LayoutOrder = i
	btn.Font        = Enum.Font.Gotham
	tabButtons[tabName] = btn

	btn.MouseButton1Click:Connect(function()
		-- Hide all pages
		for _, page in pairs(tabPages) do
			page.Visible = false
		end
		-- Show selected page
		local selectedPage = tabPages[tabName]
		if selectedPage then selectedPage.Visible = true end
		setTabActive(tabName)
	end)

	btn.MouseEnter:Connect(function()
		if activeTab ~= tabName then
			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = C.panelLight }):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		if activeTab ~= tabName then
			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = C.tabInactive }):Play()
		end
	end)
end

-- Show Office tab by default
tabPages["Office"].Visible = true
setTabActive("Office")

-- ─────────────────────────────────────────────
--  REFRESH ALL CARDS
--  Called when cash changes or a purchase completes.
-- ─────────────────────────────────────────────
local function refreshAllCards()
	for _, updateFn in ipairs(allCardUpdaters) do
		updateFn()
	end
end

-- ─────────────────────────────────────────────
--  OPEN / CLOSE ANIMATION
-- ─────────────────────────────────────────────
local OPEN_TWEEN  = TweenInfo.new(0.3, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local CLOSE_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quad,  Enum.EasingDirection.In)

local function openShop()
	screenGui.Enabled = true
	shopFrame.Size    = UDim2.new(0, SHOP_W, 0, 0)
	shopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	TweenService:Create(shopFrame, OPEN_TWEEN, {
		Size = UDim2.new(0, SHOP_W, 0, SHOP_H)
	}):Play()
	refreshAllCards()
	titleCash.Text = "💰 " .. formatCash(ShopController.GetCash())
end

local function closeShop()
	local tween = TweenService:Create(shopFrame, CLOSE_TWEEN, {
		Size = UDim2.new(0, SHOP_W, 0, 0)
	})
	tween:Play()
	tween.Completed:Connect(function()
		screenGui.Enabled = false
	end)
end

-- ─────────────────────────────────────────────
--  SHOPCONTROLLER CALLBACKS
-- ─────────────────────────────────────────────
ShopController.OnShopToggled(function(isOpen)
	if isOpen then
		openShop()
	else
		closeShop()
	end
end)

ShopController.OnCashChanged(function(cash)
	-- Update title bar cash display if shop is open
	if screenGui.Enabled then
		titleCash.Text = "💰 " .. formatCash(cash)
	end
	-- Refresh button affordability
	refreshAllCards()
end)

ShopController.OnPurchaseResult(function(purchaseType, itemId, success, message)
	-- Refresh all card states after any purchase or data load
	refreshAllCards()
	-- Show feedback message (brief label)
	if purchaseType ~= "init" and purchaseType ~= "rebirth" then
		-- Simple notification: flash the title bar
		local notifColor = success and Color3.fromRGB(30, 185, 80) or Color3.fromRGB(200, 50, 50)
		local originalColor = titleBar.BackgroundColor3
		TweenService:Create(titleBar, TweenInfo.new(0.15), { BackgroundColor3 = notifColor }):Play()
		task.wait(0.3)
		TweenService:Create(titleBar, TweenInfo.new(0.3), { BackgroundColor3 = C.accentDark }):Play()
	end
end)

ShopController.OnRebirthOccurred(function()
	refreshAllCards()
end)

ShopController.OnDataLoaded(function()
	refreshAllCards()
	titleCash.Text = "💰 " .. formatCash(ShopController.GetCash())
end)

print("[ShopGui] Loaded.")
