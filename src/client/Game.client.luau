-- Brainrot Bazaar: client boot. Builds the HUD and the world effects,
-- then routes every server message to the right piece of UI.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hud = require(script.Parent:WaitForChild("Hud"))
local WorldClient = require(script.Parent:WaitForChild("WorldClient"))

Hud.build()
Hud.bindRemotes()
Hud.startClock()
WorldClient.build()

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateUpdate = remotes:WaitForChild("StateUpdate")
local notify = remotes:WaitForChild("Notify")

stateUpdate.OnClientEvent:Connect(function(snapshot)
	Hud.update(snapshot)
end)

notify.OnClientEvent:Connect(function(kind, text)
	if kind == "toast" then
		Hud.toast(text)
	elseif kind == "tsunamiWarning" then
		WorldClient.showTsunamiWarning()
		Hud.toast(text)
	elseif kind == "tsunamiEnd" then
		WorldClient.hideTsunami()
	end
end)

print("Brainrot Bazaar client siap.")
