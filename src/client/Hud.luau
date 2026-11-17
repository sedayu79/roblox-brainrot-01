-- Brainrot Bazaar: the HUD — money bar, rarity ladder, owned list,
-- base lock and rebirth buttons, and toasts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Util = require(Shared:WaitForChild("Util"))

local Hud = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local moneyLabel
local incomeLabel
local lockButton
local rebirthButton
local toastLabel
local ownedList
local carryingLabel
local lockUntil = 0
local lockReadyAt = 0

local function makeLabel(parent, name, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize
	label.TextStrokeTransparency = 0.5
	label.Parent = parent
	return label
end

function Hud.build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	-- Top-center money bar (kept clear of the top-left Roblox menu).
	local bar = Instance.new("Frame")
	bar.Name = "MoneyBar"
	bar.Size = UDim2.new(0, 320, 0, 64)
	bar.Position = UDim2.new(0.5, -160, 0, 12)
	bar.BackgroundColor3 = Color3.fromRGB(20, 16, 32)
	bar.BackgroundTransparency = 0.25
	bar.BorderSizePixel = 0
	bar.Parent = gui
	moneyLabel = makeLabel(bar, "Money", UDim2.new(1, 0, 0.55, 0), UDim2.new(0, 0, 0, 4), 28, Color3.fromRGB(140, 255, 140))
	moneyLabel.Text = "$100"
	incomeLabel = makeLabel(bar, "Income", UDim2.new(1, 0, 0.4, 0), UDim2.new(0, 0, 0.55, 0), 16, Color3.fromRGB(255, 255, 255))
	incomeLabel.Text = "$0/dtk"

	-- Left: the rarity ladder, all twelve brainrots.
	local ladder = Instance.new("Frame")
	ladder.Name = "Ladder"
	ladder.Size = UDim2.new(0, 260, 0, 330)
	ladder.Position = UDim2.new(0, 12, 0, 90)
	ladder.BackgroundColor3 = Color3.fromRGB(20, 16, 32)
	ladder.BackgroundTransparency = 0.25
	ladder.BorderSizePixel = 0
	ladder.Parent = gui
	local title = makeLabel(ladder, "Title", UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 6), 18, Color3.fromRGB(255, 215, 0))
	title.Text = "TANGGA BRAINROT"
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 2)
	layout.Parent = ladder
	for _, char in ipairs(Catalog.Characters) do
		local row = makeLabel(ladder, char.id, UDim2.new(1, -12, 0, 20), UDim2.new(0, 6, 0, 0), 14, Catalog.RarityColors[char.rarity])
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Text = char.name .. "  •  " .. char.rarity .. "  •  $" .. tostring(char.income) .. "/dtk"
	end

	-- Right: lock and rebirth buttons.
	lockButton = Instance.new("TextButton")
	lockButton.Name = "LockButton"
	lockButton.Size = UDim2.new(0, 200, 0, 48)
	lockButton.Position = UDim2.new(1, -212, 0, 90)
	lockButton.BackgroundColor3 = Color3.fromRGB(70, 120, 220)
	lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	lockButton.Font = Enum.Font.GothamBold
	lockButton.TextSize = 18
	lockButton.Text = "Kunci Base (60 dtk)"
	lockButton.Parent = gui
	rebirthButton = Instance.new("TextButton")
	rebirthButton.Name = "RebirthButton"
	rebirthButton.Size = UDim2.new(0, 200, 0, 48)
	rebirthButton.Position = UDim2.new(1, -212, 0, 150)
	rebirthButton.BackgroundColor3 = Color3.fromRGB(120, 200, 255)
	rebirthButton.TextColor3 = Color3.fromRGB(30, 30, 30)
	rebirthButton.Font = Enum.Font.GothamBold
	rebirthButton.TextSize = 18
	rebirthButton.Text = "Rebirth"
	rebirthButton.Parent = gui

	-- Bottom-left: the brainrots standing on your base.
	local ownedFrame = Instance.new("Frame")
	ownedFrame.Name = "OwnedList"
	ownedFrame.Size = UDim2.new(0, 260, 0, 150)
	ownedFrame.Position = UDim2.new(0, 12, 1, -162)
	ownedFrame.BackgroundColor3 = Color3.fromRGB(20, 16, 32)
	ownedFrame.BackgroundTransparency = 0.25
	ownedFrame.BorderSizePixel = 0
	ownedFrame.Parent = gui
	local ownedTitle = makeLabel(ownedFrame, "Title", UDim2.new(1, 0, 0, 24), UDim2.new(0, 6, 0, 4), 16, Color3.fromRGB(255, 215, 0))
	ownedTitle.TextXAlignment = Enum.TextXAlignment.Left
	ownedTitle.Text = "BASEKU"
	ownedList = makeLabel(ownedFrame, "Owned", UDim2.new(1, -12, 1, -34), UDim2.new(0, 6, 0, 28), 13, Color3.fromRGB(255, 255, 255))
	ownedList.TextXAlignment = Enum.TextXAlignment.Left
	ownedList.TextYAlignment = Enum.TextYAlignment.Top
	ownedList.TextWrapped = true
	ownedList.Text = "Base kosong. Beli brainrot di conveyor utara!"

	-- Carrying warning, above the bottom-center toasts.
	carryingLabel = makeLabel(gui, "Carrying", UDim2.new(0, 520, 0, 30), UDim2.new(0.5, -260, 1, -120), 18, Color3.fromRGB(255, 215, 0))
	carryingLabel.Text = ""

	-- Toast line, bottom-center.
	toastLabel = makeLabel(gui, "Toast", UDim2.new(0, 520, 0, 30), UDim2.new(0.5, -260, 1, -50), 18, Color3.fromRGB(255, 240, 150))
	toastLabel.Text = ""

	-- Hint line at the very bottom.
	local hint = makeLabel(gui, "Hint", UDim2.new(0, 620, 0, 20), UDim2.new(0.5, -310, 1, -18), 14, Color3.fromRGB(230, 230, 230))
	hint.Text = "Dekati conveyor di utara untuk beli brainrot — jaga basemu dari pencuri!"
end

function Hud.bindRemotes()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	lockButton.MouseButton1Click:Connect(function()
		remotes:WaitForChild("LockBase"):FireServer()
	end)
	rebirthButton.MouseButton1Click:Connect(function()
		remotes:WaitForChild("Rebirth"):FireServer()
	end)
end

-- Refresh the lock button's countdown once a second.
function Hud.startClock()
	task.spawn(function()
		while true do
			task.wait(1)
			if lockButton ~= nil then
				local now = os.time()
				if now < lockUntil then
					lockButton.Text = "Terkunci (" .. Util.formatClock(lockUntil - now) .. ")"
				elseif now < lockReadyAt then
					lockButton.Text = "Kunci cooldown (" .. Util.formatClock(lockReadyAt - now) .. ")"
				else
					lockButton.Text = "Kunci Base (60 dtk)"
				end
			end
		end
	end)
end

function Hud.update(snapshot)
	if moneyLabel == nil then
		return
	end
	moneyLabel.Text = Util.formatMoney(snapshot.money)
	incomeLabel.Text = Util.formatMoney(snapshot.income) .. "/dtk  •  Rebirth x" .. tostring(snapshot.rebirths)
	lockUntil = snapshot.lockUntil or 0
	lockReadyAt = snapshot.lockReadyAt or 0
	rebirthButton.Text = "Rebirth (" .. Util.formatMoney(snapshot.rebirthCost) .. ")"
	if snapshot.carrying then
		carryingLabel.Text = "Kamu membawa brainrot curian — LARI KE BASEMU!"
	else
		carryingLabel.Text = ""
	end
	local lines = {}
	for _, item in ipairs(snapshot.owned) do
		table.insert(lines, item.name .. " (" .. item.rarity .. ")  $" .. tostring(math.floor(item.income)) .. "/dtk")
	end
	if #lines == 0 then
		ownedList.Text = "Base kosong. Beli brainrot di conveyor utara!"
	else
		ownedList.Text = table.concat(lines, "\n")
	end
end

function Hud.toast(text)
	if toastLabel == nil then
		return
	end
	toastLabel.Text = text
	task.delay(4, function()
		if toastLabel ~= nil and toastLabel.Text == text then
			toastLabel.Text = ""
		end
	end)
end

return Hud
