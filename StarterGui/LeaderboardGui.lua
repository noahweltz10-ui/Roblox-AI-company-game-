--[[
	LeaderboardGui.lua
	StarterGui > LeaderboardGui (LocalScript)

	Builds and manages the right-side leaderboard panel.
	  - Shows top 10 players by current cash
	  - Updates every GameConfig.LeaderboardUpdateInterval seconds (server broadcasts)
	  - Displays rank, player name, formatted cash, and rebirth count
	  - Dark navy + electric blue theme matching the rest of the game UI

	SETUP IN STUDIO:
	  1. In StarterGui, create a LocalScript named "LeaderboardGui"
	  2. Paste this entire file into it
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player = Players.LocalPlayer

-- ─────────────────────────────────────────────
--  THEME
-- ─────────────────────────────────────────────
local DARK_BG    = Color3.fromRGB(10,  15,  35)
local PANEL_BG   = Color3.fromRGB(14,  22,  48)
local ROW_ALT    = Color3.fromRGB(18,  28,  58)
local ACCENT     = Color3.fromRGB(30,  140, 255)
local GOLD       = Color3.fromRGB(255, 195, 30)
local SILVER     = Color3.fromRGB(190, 200, 215)
local BRONZE     = Color3.fromRGB(205, 127, 50)
local TEXT_WHITE = Color3.fromRGB(255, 255, 255)
local TEXT_LIGHT = Color3.fromRGB(175, 195, 225)
local TEXT_DIM   = Color3.fromRGB(110, 130, 165)
local MY_COLOR   = Color3.fromRGB(80,  210, 130)  -- highlight for local player

local RANK_COLORS = { GOLD, SILVER, BRONZE }

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
			return string.format("$%.1f%s", amount / fmt.threshold, fmt.suffix)
		end
	end
	return "$" .. tostring(amount):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

-- ─────────────────────────────────────────────
--  UI HELPERS
-- ─────────────────────────────────────────────
local function makeCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function makeStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color           = color or ACCENT
	s.Thickness       = thickness or 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent          = parent
	return s
end

-- ─────────────────────────────────────────────
--  SCREENGUI
-- ─────────────────────────────────────────────
local playerGui = player:WaitForChild("PlayerGui")

local screenGui          = Instance.new("ScreenGui")
screenGui.Name           = "LeaderboardGui"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder   = 2
screenGui.Parent         = playerGui

-- ─────────────────────────────────────────────
--  MAIN PANEL
-- ─────────────────────────────────────────────
local PANEL_W = 240
local HEADER_H = 54
local ROW_H   = 42
local MAX_ROWS = 10
local PANEL_H = HEADER_H + (ROW_H * MAX_ROWS) + 12

local panel = Instance.new("Frame")
panel.Name              = "LeaderboardPanel"
panel.Size              = UDim2.new(0, PANEL_W, 0, PANEL_H)
panel.Position          = UDim2.new(1, -PANEL_W - 14, 0.5, -PANEL_H / 2)
panel.AnchorPoint       = Vector2.new(0, 0)
panel.BackgroundColor3  = PANEL_BG
panel.BackgroundTransparency = 0.12
panel.BorderSizePixel   = 0
panel.Parent            = screenGui
makeCorner(panel, 12)
makeStroke(panel, ACCENT, 1.5)

-- ─────────────────────────────────────────────
--  HEADER
-- ─────────────────────────────────────────────
local header = Instance.new("Frame")
header.Name              = "Header"
header.Size              = UDim2.new(1, 0, 0, HEADER_H)
header.Position          = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3  = ACCENT
header.BackgroundTransparency = 0.15
header.BorderSizePixel   = 0
header.Parent            = panel

-- Rounded top corners only — achieved by making bottom corners square via a rect frame
local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent       = header

-- Cover bottom corners of header so only top is rounded
local headerCover = Instance.new("Frame")
headerCover.Size             = UDim2.new(1, 0, 0, 12)
headerCover.Position         = UDim2.new(0, 0, 1, -12)
headerCover.BackgroundColor3 = ACCENT
headerCover.BackgroundTransparency = 0.15
headerCover.BorderSizePixel  = 0
headerCover.Parent           = header

local headerIcon = Instance.new("TextLabel")
headerIcon.BackgroundTransparency = 1
headerIcon.Size     = UDim2.new(0, 34, 0, 34)
headerIcon.Position = UDim2.new(0, 12, 0.5, 0)
headerIcon.AnchorPoint = Vector2.new(0, 0.5)
headerIcon.Text     = "🏆"
headerIcon.TextSize = 24
headerIcon.Font     = Enum.Font.GothamBold
headerIcon.TextScaled = false
headerIcon.Parent   = header

local headerTitle = Instance.new("TextLabel")
headerTitle.BackgroundTransparency = 1
headerTitle.Size     = UDim2.new(1, -55, 0, 22)
headerTitle.Position = UDim2.new(0, 50, 0, 8)
headerTitle.Text     = "LEADERBOARD"
headerTitle.TextColor3 = TEXT_WHITE
headerTitle.Font     = Enum.Font.GothamBlack
headerTitle.TextSize = 16
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.TextScaled = false
headerTitle.Parent   = header

local headerSub = Instance.new("TextLabel")
headerSub.BackgroundTransparency = 1
headerSub.Size     = UDim2.new(1, -55, 0, 14)
headerSub.Position = UDim2.new(0, 50, 0, 32)
headerSub.Text     = "Top players by net worth"
headerSub.TextColor3 = Color3.fromRGB(160, 200, 255)
headerSub.Font     = Enum.Font.Gotham
headerSub.TextSize = 11
headerSub.TextXAlignment = Enum.TextXAlignment.Left
headerSub.TextScaled = false
headerSub.Parent   = header

-- ─────────────────────────────────────────────
--  ROW FRAMES  (pre-built, updated with data)
-- ─────────────────────────────────────────────
local rows = {}  -- array of { frame, rankLabel, nameLabel, cashLabel, rebirthLabel }

for i = 1, MAX_ROWS do
	local isAlt = (i % 2 == 0)
	local yPos  = HEADER_H + (i - 1) * ROW_H

	local row = Instance.new("Frame")
	row.Name              = "Row_" .. i
	row.Size              = UDim2.new(1, -2, 0, ROW_H)
	row.Position          = UDim2.new(0, 1, 0, yPos)
	row.BackgroundColor3  = isAlt and ROW_ALT or PANEL_BG
	row.BackgroundTransparency = 0.05
	row.BorderSizePixel   = 0
	row.Visible           = false  -- hidden until data arrives
	row.Parent            = panel

	-- Rank number / medal
	local rankLabel = Instance.new("TextLabel")
	rankLabel.BackgroundTransparency = 1
	rankLabel.Size     = UDim2.new(0, 32, 1, 0)
	rankLabel.Position = UDim2.new(0, 6, 0, 0)
	rankLabel.Text     = tostring(i)
	rankLabel.TextColor3 = i <= 3 and (RANK_COLORS[i] or TEXT_LIGHT) or TEXT_DIM
	rankLabel.Font     = Enum.Font.GothamBlack
	rankLabel.TextSize = i <= 3 and 17 or 14
	rankLabel.TextScaled = false
	rankLabel.Parent   = row

	-- Player name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size     = UDim2.new(1, -140, 1, 0)
	nameLabel.Position = UDim2.new(0, 42, 0, 0)
	nameLabel.Text     = "—"
	nameLabel.TextColor3 = TEXT_LIGHT
	nameLabel.Font     = Enum.Font.GothamBold
	nameLabel.TextSize = 13
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate   = Enum.TextTruncate.AtEnd
	nameLabel.TextScaled = false
	nameLabel.Parent   = row

	-- Cash amount
	local cashLabel = Instance.new("TextLabel")
	cashLabel.BackgroundTransparency = 1
	cashLabel.Size     = UDim2.new(0, 80, 1, 0)
	cashLabel.Position = UDim2.new(1, -86, 0, 0)
	cashLabel.Text     = "$0"
	cashLabel.TextColor3 = TEXT_WHITE
	cashLabel.Font     = Enum.Font.Gotham
	cashLabel.TextSize = 12
	cashLabel.TextXAlignment = Enum.TextXAlignment.Right
	cashLabel.TextScaled = false
	cashLabel.Parent   = row

	-- Rebirth stars (small, top-right of name cell)
	local rebirthLabel = Instance.new("TextLabel")
	rebirthLabel.BackgroundTransparency = 1
	rebirthLabel.Size     = UDim2.new(0, 36, 0, 14)
	rebirthLabel.Position = UDim2.new(0, 42, 0, 3)
	rebirthLabel.Text     = ""
	rebirthLabel.TextColor3 = GOLD
	rebirthLabel.Font     = Enum.Font.GothamBold
	rebirthLabel.TextSize = 9
	rebirthLabel.TextXAlignment = Enum.TextXAlignment.Left
	rebirthLabel.Visible  = false
	rebirthLabel.TextScaled = false
	rebirthLabel.Parent   = row

	rows[i] = {
		frame        = row,
		rankLabel    = rankLabel,
		nameLabel    = nameLabel,
		cashLabel    = cashLabel,
		rebirthLabel = rebirthLabel,
	}
end

-- Divider line at bottom of header
local divider = Instance.new("Frame")
divider.Name             = "Divider"
divider.Size             = UDim2.new(1, -20, 0, 1)
divider.Position         = UDim2.new(0, 10, 0, HEADER_H)
divider.BackgroundColor3 = ACCENT
divider.BackgroundTransparency = 0.5
divider.BorderSizePixel  = 0
divider.Parent           = panel

-- ─────────────────────────────────────────────
--  UPDATE FUNCTION
-- ─────────────────────────────────────────────
local function updateLeaderboard(entries)
	for i = 1, MAX_ROWS do
		local rowData = rows[i]
		local entry   = entries[i]

		if entry then
			rowData.frame.Visible     = true
			rowData.nameLabel.Text    = entry.name or "?"
			rowData.cashLabel.Text    = entry.formatted or formatCash(entry.cash or 0)

			-- Highlight local player's row
			local isMe = (entry.name == player.Name)
			rowData.nameLabel.TextColor3 = isMe and MY_COLOR or TEXT_LIGHT
			rowData.cashLabel.TextColor3 = isMe and MY_COLOR or TEXT_WHITE
			rowData.rankLabel.TextColor3 = i <= 3 and RANK_COLORS[i] or (isMe and MY_COLOR or TEXT_DIM)

			-- Rebirth count
			local rc = entry.rebirths or 0
			if rc > 0 then
				rowData.rebirthLabel.Visible = true
				rowData.rebirthLabel.Text    = string.rep("✦", math.min(rc, 5))
			else
				rowData.rebirthLabel.Visible = false
			end

			-- Shift name down slightly if rebirth label is showing
			rowData.nameLabel.Position = rc > 0
				and UDim2.new(0, 42, 0, 13)
				or  UDim2.new(0, 42, 0, 0)
		else
			rowData.frame.Visible = false
		end
	end
end

-- ─────────────────────────────────────────────
--  LISTEN FOR SERVER BROADCASTS
-- ─────────────────────────────────────────────
local RemoteEvents      = ReplicatedStorage:WaitForChild("RemoteEvents", 15)
local leaderboardUpdate = RemoteEvents and RemoteEvents:WaitForChild("LeaderboardUpdate", 10)

if leaderboardUpdate then
	leaderboardUpdate.OnClientEvent:Connect(function(entries)
		updateLeaderboard(entries or {})
	end)
else
	warn("[LeaderboardGui] LeaderboardUpdate RemoteEvent not found.")
end

-- ─────────────────────────────────────────────
--  COLLAPSE TOGGLE  (click header to collapse panel)
-- ─────────────────────────────────────────────
local collapsed = false
local COLLAPSED_H = HEADER_H + 4

local function setCollapsed(isCollapsed)
	collapsed = isCollapsed
	TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, PANEL_W, 0, isCollapsed and COLLAPSED_H or PANEL_H)
	}):Play()
	for i = 1, MAX_ROWS do
		rows[i].frame.Visible = not isCollapsed and (rows[i].frame.Visible or false)
	end
	divider.Visible = not isCollapsed
end

-- Make header a button for collapsing
local headerButton = Instance.new("TextButton")
headerButton.BackgroundTransparency = 1
headerButton.Size     = UDim2.new(1, 0, 1, 0)
headerButton.Text     = ""
headerButton.Parent   = header

local collapseArrow = Instance.new("TextLabel")
collapseArrow.BackgroundTransparency = 1
collapseArrow.Size     = UDim2.new(0, 20, 0, 20)
collapseArrow.Position = UDim2.new(1, -26, 0.5, 0)
collapseArrow.AnchorPoint = Vector2.new(0, 0.5)
collapseArrow.Text     = "▲"
collapseArrow.TextColor3 = Color3.fromRGB(160, 200, 255)
collapseArrow.TextSize = 12
collapseArrow.Font     = Enum.Font.GothamBold
collapseArrow.TextScaled = false
collapseArrow.Parent   = header

headerButton.MouseButton1Click:Connect(function()
	setCollapsed(not collapsed)
	collapseArrow.Text = collapsed and "▼" or "▲"
end)

print("[LeaderboardGui] Loaded.")
