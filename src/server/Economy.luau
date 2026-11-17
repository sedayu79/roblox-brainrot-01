-- Brainrot Bazaar: the income tick. Once a second, every brainrot on
-- every base pays its owner, and the client HUD gets fresh numbers.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameState = require(script.Parent:WaitForChild("GameState"))

local Economy = {}

function Economy.start()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local stateUpdate = remotes:WaitForChild("StateUpdate")
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local state = GameState.get(player)
				if state ~= nil then
					local income = GameState.incomePerSecond(player)
					state.money += income
					local snapshot = GameState.snapshot(player)
					if snapshot ~= nil then
						stateUpdate:FireClient(player, snapshot)
					end
				end
			end
		end
	end)
end

return Economy
