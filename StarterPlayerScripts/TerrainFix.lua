--[[
	TerrainFix.lua
	StarterPlayerScripts > TerrainFix (LocalScript)

	Forces terrain grass blades off on the client every frame.
	This cannot be overridden by any server script.
]]

local RunService = game:GetService("RunService")
local terrain    = workspace.Terrain

RunService.Heartbeat:Connect(function()
	if terrain.Decoration then
		terrain.Decoration = false
	end
end)

print("[TerrainFix] Grass decoration disabled.")
