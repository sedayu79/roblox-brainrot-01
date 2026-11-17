-- Brainrot Bazaar: client-side world effects. The default 3D camera does the
-- looking; this module adds the red vignette that pulses while a tsunami
-- warning is up, so the danger reads even before you read the banner.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local WorldClient = {}
local vignette = nil
local warningActive = false

function WorldClient.start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	vignette = Instance.new("Frame")
	vignette.Name = "WaveVignette"
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
	vignette.BackgroundTransparency = 1
	vignette.BorderSizePixel = 0
	vignette.Visible = false
	local gui = Instance.new("ScreenGui")
	gui.Name = "WorldEffectsGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = -1
	gui.Parent = playerGui
	vignette.Parent = gui
	RunService.RenderStepped:Connect(function()
		if not vignette then
			return
		end
		if warningActive then
			vignette.Visible = true
			vignette.BackgroundTransparency = 0.86 + math.sin(os.clock() * 5) * 0.06
		else
			vignette.Visible = false
		end
	end)
end

function WorldClient.update(state)
	warningActive = state.waveWarning == true
end

return WorldClient
