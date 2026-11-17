-- Brainrot Bazaar: client-side world effects — the tsunami warning
-- vignette that tells the player to run home.

local Players = game:GetService("Players")

local WorldClient = {}

local vignette
local warningLabel

function WorldClient.build()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "WorldEffects"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 5
	gui.Parent = playerGui
	vignette = Instance.new("Frame")
	vignette.Name = "TsunamiVignette"
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.BackgroundColor3 = Color3.fromRGB(40, 110, 255)
	vignette.BackgroundTransparency = 0.75
	vignette.BorderSizePixel = 0
	vignette.Visible = false
	vignette.Parent = gui
	warningLabel = Instance.new("TextLabel")
	warningLabel.Name = "Warning"
	warningLabel.Size = UDim2.new(0, 600, 0, 60)
	warningLabel.Position = UDim2.new(0.5, -300, 0.3, 0)
	warningLabel.BackgroundTransparency = 1
	warningLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	warningLabel.Font = Enum.Font.GothamBlack
	warningLabel.TextSize = 32
	warningLabel.TextStrokeTransparency = 0.3
	warningLabel.Text = ""
	warningLabel.Parent = vignette
end

function WorldClient.showTsunamiWarning()
	if vignette == nil then
		return
	end
	warningLabel.Text = "TSUNAMI ES TEH! LARI KE BASE!"
	vignette.Visible = true
end

function WorldClient.hideTsunami()
	if vignette == nil then
		return
	end
	vignette.Visible = false
end

return WorldClient
