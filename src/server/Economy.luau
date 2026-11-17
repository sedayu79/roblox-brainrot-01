-- Brainrot Bazaar: the economy tick. Every second each player's brainrots pay
-- out, and the new balance goes to their HUD.

local Players = game:GetService("Players")

local Economy = {}

function Economy.start()
	task.spawn(function()
		while true do
			task.wait(1)
			local GameState = require(script.Parent:WaitForChild("GameState"))
			for _, player in ipairs(Players:GetPlayers()) do
				local income = GameState.incomePerSecond(player)
				if income > 0 then
					GameState.addMoney(player, income)
				end
				GameState.pushState(player)
			end
		end
	end)
end

return Economy
