-- Brainrot Bazaar: client boot — builds the HUD, wires the lock and rebirth
-- buttons to the server, and listens for state updates and toasts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local Hud = require(script.Parent:WaitForChild("Hud"))
local WorldClient = require(script.Parent:WaitForChild("WorldClient"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StateUpdate = Remotes:WaitForChild("StateUpdate")
local Notify = Remotes:WaitForChild("Notify")

Hud.build(player)
WorldClient.start()

StateUpdate.OnClientEvent:Connect(function(state)
	Hud.update(state)
	WorldClient.update(state)
end)

Notify.OnClientEvent:Connect(function(text, kind)
	Hud.toast(text, kind)
end)

Hud.onLock(function()
	Remotes:WaitForChild("LockBase"):FireServer()
end)

Hud.onRebirth(function()
	Remotes:WaitForChild("Rebirth"):FireServer()
end)
