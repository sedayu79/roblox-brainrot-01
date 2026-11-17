-- Brainrot Bazaar: boots the server — builds the bases, wires the remotes,
-- starts the conveyor, the economy tick and the threats, and keeps the
-- brainrots on their base slots gently bobbing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameState = require(script.Parent:WaitForChild("GameState"))
local World = require(script.Parent:WaitForChild("World"))
local Conveyor = require(script.Parent:WaitForChild("Conveyor"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local Threat = require(script.Parent:WaitForChild("Threat"))

World.buildBases()

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
Remotes:WaitForChild("LockBase").OnServerEvent:Connect(function(player)
	GameState.lockBase(player)
end)
Remotes:WaitForChild("Rebirth").OnServerEvent:Connect(function(player)
	GameState.rebirth(player)
end)

Players.PlayerAdded:Connect(function(player)
	GameState.newPlayer(player)
end)
Players.PlayerRemoving:Connect(function(player)
	GameState.removePlayer(player)
end)
for _, player in ipairs(Players:GetPlayers()) do
	GameState.newPlayer(player)
end

Conveyor.start()
Economy.start()
Threat.start()

-- Brainrots parked on a base bob gently so the base looks alive.
RunService.Heartbeat:Connect(function()
	local t = os.clock()
	for _, record in pairs(GameState.brainrots) do
		if record.state == "base" and not record.moving and record.slotCF and record.model and record.model.Parent then
			local bob = math.sin(t * 2 + (record.phase or 0)) * 0.15
			record.model:PivotTo(record.slotCF * CFrame.new(0, bob, 0))
		end
	end
end)

print("Brainrot Bazaar server ready: 6 bases, conveyor live, tsunami armed.")
