--[[
	TimeOfDayGui.lua
	StarterGui > TimeOfDayGui (LocalScript)

	Per-player time of day selector.
	- Small gear icon button on screen
	- Click to open a panel with time presets
	- Player can lock to a specific time or enable auto cycle
	- Only affects the local player's lighting (client-side)

	SETUP IN STUDIO:
	  1. In StarterGui, create a LocalScript named "TimeOfDayGui"
	  2. Paste this entire file into it
]]

local Players      = game:GetService("Players")
local Lighting     = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────────
--  TIME PRESETS
-- ─────────────────────────────────────────────
local TIME_PRESETS = {
	{ label = "🌅  Dawn",      time = 6,    name = "Dawn"    },
	{ label = "☀️  Morning",   time = 9,    name = "Morning" },
	{ label = "🌞  Noon",      time = 12,   name = "Noon"    },
	{ label = "🌇  Sunset",    time = 17,   name = "Sunset"  },
	{ label = "🌙  Night",     time = 21,   name = "Night"   },
	{ label = "🔄  Auto Cycle", time = nil, name = "Auto"    },
}

-- ─────────────────────────────────────────────
--  STATE
-- ─────────────────────────────────────────────
local lockedTime   = nil   -- nil = auto cycle
local cycleRunning = true
local DAY_LENGTH   = 600   -- seconds per full cycle (matches server)

-- ─────────────────────────────────────────────
--  THEME
-- ─────────────────────────────────────────────
local PANEL_BG   = Color3.fromRGB(14,  22,  50)
local ACCENT     = Color3.fromRGB(30,  140, 255)
local TEXT_WHITE = Color3.fromRGB(255, 255, 255)
local TEXT_DIM   = Color3.fromRGB(120, 140, 175)
local ACTIVE_BTN = Color3.fromRGB(30,  140, 255)
local INACTIVE_BTN = Color3.fromRGB(22, 34,  68)

-- ─────────────────────────────────────────────
--  LIGHTING UPDATER  (client-side only)
-- ─────────────────────────────────────────────
local function updateLightingForTime(clockTime)
	if clockTime >= 6 and clockTime < 8 then
		Lighting.Ambient        = Color3.fromRGB(100, 85,  80)
		Lighting.Brightness     = 1.5
		Lighting.OutdoorAmbient = Color3.fromRGB(180, 140, 100)
	elseif clockTime >= 8 and clockTime < 17 then
		Lighting.Ambient        = Color3.fromRGB(80,  80,  90)
		Lighting.Brightness     = 2.5
		Lighting.OutdoorAmbient = Color3.fromRGB(160, 170, 190)
	elseif clockTime >= 17 and clockTime < 20 then
		Lighting.Ambient        = Color3.fromRGB(110, 80,  60)
		Lighting.Brightness     = 1.8
		Lighting.OutdoorAmbient = Color3.fromRGB(200, 130, 80)
	else
		Lighting.Ambient        = Color3.fromRGB(30,  35,  60)
		Lighting.Brightness     = 0.5
		Lighting.OutdoorAmbient = Color3.fromRGB(40,  50,  80)
	end
end

-- ─────────────────────────────────────────────
--  CLIENT DAY CYCLE LOOP
-- ─────────────────────────────────────────────
task.spawn(function()
	while true do
		task.wait(0.5)
		if lockedTime == nil then
			-- Auto cycle
			local hoursPerSecond = 24 / DAY_LENGTH
			Lighting.ClockTime = (Lighting.ClockTime + hoursPerSecond * 0.5) % 24
			updateLightingForTime(Lighting.ClockTime)
		else
			-- Locked to specific time
			Lighting.ClockTime = lockedTime
			updateLightingForTime(lockedTime)
		end
	end
end)

-- ─────────────────────────────────────────────
--  BUILD GUI
-- ─────────────────────────────────────────────
local screenGui          = Instance.new("ScreenGui")
screenGui.Name           = "TimeOfDayGui"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder   = 5
screenGui.Parent         = playerGui

-- Gear button (bottom-left, above shop button)
local gearBtn = Instance.new("TextButton")
gearBtn.Name              = "GearButton"
gearBtn.Size              = UDim2.new(0, 46, 0, 46)
gearBtn.Position          = UDim2.new(0, 18, 1, -120)
gearBtn.AnchorPoint       = Vector2.new(0, 0)
gearBtn.BackgroundColor3  = PANEL_BG
gearBtn.BorderSizePixel   = 0
gearBtn.Text              = "⚙️"
gearBtn.TextSize          = 22
gearBtn.Font              = Enum.Font.GothamBold
gearBtn.TextScaled        = false
gearBtn.AutoButtonColor   = false
gearBtn.Parent            = screenGui

local gearCorner = Instance.new("UICorner")
gearCorner.CornerRadius = UDim.new(0, 10)
gearCorner.Parent       = gearBtn

local gearStroke = Instance.new("UIStroke")
gearStroke.Color     = ACCENT
gearStroke.Thickness = 1.5
gearStroke.Parent    = gearBtn

-- Settings panel (appears above gear button)
local panel = Instance.new("Frame")
panel.Name              = "SettingsPanel"
panel.Size              = UDim2.new(0, 200, 0, 260)
panel.Position          = UDim2.new(0, 18, 1, -390)
panel.BackgroundColor3  = PANEL_BG
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel   = 0
panel.Visible           = false
panel.Parent            = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent       = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color     = ACCENT
panelStroke.Thickness = 1.5
panelStroke.Parent    = panel

-- Panel title
local titleLabel = Instance.new("TextLabel")
titleLabel.BackgroundTransparency = 1
titleLabel.Size     = UDim2.new(1, 0, 0, 36)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Text     = "⚙️  TIME OF DAY"
titleLabel.TextColor3 = TEXT_WHITE
titleLabel.Font     = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextScaled = false
titleLabel.Parent   = panel

-- Divider
local divider = Instance.new("Frame")
divider.Size             = UDim2.new(1, -20, 0, 1)
divider.Position         = UDim2.new(0, 10, 0, 36)
divider.BackgroundColor3 = ACCENT
divider.BackgroundTransparency = 0.5
divider.BorderSizePixel  = 0
divider.Parent           = panel

-- Time preset buttons
local presetButtons = {}
local BUTTON_H = 34
local BUTTON_SPACING = 4
local START_Y = 44

for i, preset in ipairs(TIME_PRESETS) do
	local btn = Instance.new("TextButton")
	btn.Name              = preset.name
	btn.Size              = UDim2.new(1, -16, 0, BUTTON_H)
	btn.Position          = UDim2.new(0, 8, 0, START_Y + (i-1) * (BUTTON_H + BUTTON_SPACING))
	btn.BackgroundColor3  = INACTIVE_BTN
	btn.BorderSizePixel   = 0
	btn.Text              = preset.label
	btn.TextColor3        = TEXT_DIM
	btn.Font              = Enum.Font.Gotham
	btn.TextSize          = 13
	btn.TextXAlignment    = Enum.TextXAlignment.Left
	btn.TextScaled        = false
	btn.AutoButtonColor   = false
	btn.Parent            = panel

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent       = btn

	local btnPadding = Instance.new("UIPadding")
	btnPadding.PaddingLeft = UDim.new(0, 10)
	btnPadding.Parent      = btn

	presetButtons[i] = btn

	btn.MouseButton1Click:Connect(function()
		-- Update active button visuals
		for j, b in ipairs(presetButtons) do
			b.BackgroundColor3 = INACTIVE_BTN
			b.TextColor3       = TEXT_DIM
			b.Font             = Enum.Font.Gotham
		end
		btn.BackgroundColor3 = ACTIVE_BTN
		btn.TextColor3       = TEXT_WHITE
		btn.Font             = Enum.Font.GothamBold

		-- Apply time
		if preset.time then
			lockedTime = preset.time
			Lighting.ClockTime = preset.time
			updateLightingForTime(preset.time)
		else
			lockedTime = nil  -- auto cycle
		end
	end)

	btn.MouseEnter:Connect(function()
		if btn.BackgroundColor3 ~= ACTIVE_BTN then
			TweenService:Create(btn, TweenInfo.new(0.1), {
				BackgroundColor3 = Color3.fromRGB(30, 45, 85)
			}):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		if btn.TextColor3 ~= TEXT_WHITE then
			TweenService:Create(btn, TweenInfo.new(0.1), {
				BackgroundColor3 = INACTIVE_BTN
			}):Play()
		end
	end)
end

-- Set Auto Cycle as default active
presetButtons[#presetButtons].BackgroundColor3 = ACTIVE_BTN
presetButtons[#presetButtons].TextColor3       = TEXT_WHITE
presetButtons[#presetButtons].Font             = Enum.Font.GothamBold

-- ─────────────────────────────────────────────
--  GEAR BUTTON TOGGLE
-- ─────────────────────────────────────────────
local panelOpen = false

gearBtn.MouseButton1Click:Connect(function()
	panelOpen = not panelOpen
	if panelOpen then
		panel.Visible   = true
		panel.Position  = UDim2.new(0, 18, 1, -390)
		panel.Size      = UDim2.new(0, 200, 0, 0)
		TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 200, 0, 260)
		}):Play()
	else
		local tween = TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, 200, 0, 0)
		})
		tween:Play()
		tween.Completed:Connect(function()
			panel.Visible = false
		end)
	end
end)

-- Hover effect on gear button
gearBtn.MouseEnter:Connect(function()
	TweenService:Create(gearBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(22, 34, 68)
	}):Play()
end)
gearBtn.MouseLeave:Connect(function()
	TweenService:Create(gearBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = PANEL_BG
	}):Play()
end)

print("[TimeOfDayGui] Loaded.")
