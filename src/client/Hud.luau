-- Brainrot Bazaar: the HUD. One ScreenGui over the 3D world: money bar, your
-- base's brainrots, the rarity ladder, lock and rebirth buttons, wave banner,
-- toasts and the carrying warning. Nothing here touches game state — the
-- server sends it and this only shows it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Util = require(Shared:WaitForChild("Util"))

local Hud = {}
local gui = nil
local moneyLabel = nil
local incomeLabel = nil
local rebirthLabel = nil
local baseRows = {}
local ladderRows = {}
local lockButton = nil
local rebirthButton = nil
local banner = nil
local toastLabel = nil
local carryingLabel = nil
local lockCallback = nil
local rebirthCallback = nil
local toastToken = 0

local PANEL_BG = Color3.fromRGB(20, 20, 30)
local PANEL_STROKE = Color3.fromRGB(255, 215, 0)

local function panel(parent, name, position, size, anchor)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = anchor or Vector2.new(0, 0)
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = PANEL_BG
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Color = PANEL_STROKE
	stroke.Thickness = 2
	stroke.Transparency = 0.4
	stroke.Parent = frame
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame
	return frame
end

local function textLabel(parent, name, position, size, text, textSize, color, bold)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

function Hud.build(player)
	gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Money bar, top center (kept clear of the top-left Roblox menu buttons).
	local moneyBar = panel(gui, "MoneyBar", UDim2.new(0.5, 0, 0, 12), UDim2.fromOffset(480, 64), Vector2.new(0.5, 0))
	moneyLabel = textLabel(moneyBar, "Money", UDim2.new(0, 16, 0, 6), UDim2.new(1, -32, 0, 34), "$100", 30, Color3.fromRGB(120, 255, 120), true)
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Center
	incomeLabel = textLabel(moneyBar, "Income", UDim2.new(0, 16, 0, 38), UDim2.new(0.5, -16, 0, 20), "+$0/dtk", 18, Color3.fromRGB(255, 255, 255), false)
	incomeLabel.TextXAlignment = Enum.TextXAlignment.Center
	rebirthLabel = textLabel(moneyBar, "Rebirth", UDim2.new(0.5, 0, 0, 38), UDim2.new(0.5, -16, 0, 20), "Rebirth 0 (x1.00)", 18, Color3.fromRGB(255, 215, 0), false)
	rebirthLabel.TextXAlignment = Enum.TextXAlignment.Center

	-- Your base's brainrots, left side.
	local basePanel = panel(gui, "BasePanel", UDim2.new(0, 12, 0, 92), UDim2.fromOffset(270, 300))
	textLabel(basePanel, "Title", UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 0, 26), "BASEKU", 22, Color3.fromRGB(255, 215, 0), true)
	for i = 1, 8 do
		baseRows[i] = textLabel(basePanel, "Row" .. tostring(i), UDim2.new(0, 12, 0, 36 + (i - 1) * 30), UDim2.new(1, -24, 0, 26), "— slot kosong —", 16, Color3.fromRGB(200, 200, 200), false)
	end

	-- Rarity ladder, right side.
	local ladderPanel = panel(gui, "LadderPanel", UDim2.new(1, -12, 0, 92), UDim2.fromOffset(270, 260), Vector2.new(1, 0))
	textLabel(ladderPanel, "Title", UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 0, 26), "TANGGA RARITY", 22, Color3.fromRGB(255, 215, 0), true)
	for i, rarity in ipairs(Catalog.RARITIES) do
		local cheapest = Catalog.cheapestOfRarity(i)
		local text = rarity.name .. " — " .. cheapest.name .. " " .. Util.formatMoney(cheapest.cost)
		ladderRows[i] = textLabel(ladderPanel, "Row" .. tostring(i), UDim2.new(0, 12, 0, 36 + (i - 1) * 32), UDim2.new(1, -24, 0, 28), text, 16, Color3.fromRGB(200, 200, 200), true)
	end

	-- Wave warning banner, center under the money bar.
	banner = panel(gui, "Banner", UDim2.new(0.5, 0, 0, 86), UDim2.fromOffset(560, 44), Vector2.new(0.5, 0))
	banner.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
	local bannerText = textLabel(banner, "Text", UDim2.new(0, 8, 0, 0), UDim2.new(1, -16, 1, 0), "TSUNAMI ES TEH DATANG! LARI KE BASEMU!", 22, Color3.fromRGB(255, 255, 255), true)
	bannerText.TextXAlignment = Enum.TextXAlignment.Center
	banner.Visible = false

	-- Toasts, center screen.
	toastLabel = textLabel(gui, "Toast", UDim2.new(0.5, 0, 0, 0.4, 0), UDim2.fromOffset(520, 44), "", 22, Color3.fromRGB(255, 255, 255), true)
	toastLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	toastLabel.TextXAlignment = Enum.TextXAlignment.Center
	toastLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	toastLabel.BackgroundTransparency = 0.25
	toastLabel.Visible = false

	-- Carrying warning, above the buttons.
	carryingLabel = textLabel(gui, "Carrying", UDim2.new(0.5, 0, 1, -128), UDim2.fromOffset(520, 36), "", 20, Color3.fromRGB(255, 215, 0), true)
	carryingLabel.AnchorPoint = Vector2.new(0.5, 0)
	carryingLabel.TextXAlignment = Enum.TextXAlignment.Center
	carryingLabel.Visible = false

	-- Lock and rebirth buttons, bottom center.
	local buttons = panel(gui, "Buttons", UDim2.new(0.5, 0, 1, -84), UDim2.fromOffset(540, 64), Vector2.new(0.5, 1))
	lockButton = Instance.new("TextButton")
	lockButton.Name = "LockButton"
	lockButton.Position = UDim2.new(0, 10, 0, 10)
	lockButton.Size = UDim2.new(0.5, -15, 1, -20)
	lockButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	lockButton.Text = "Kunci Base (60 dtk)"
	lockButton.TextSize = 20
	lockButton.TextColor3 = Color3.fromRGB(30, 30, 30)
	lockButton.Font = Enum.Font.GothamBold
	lockButton.Parent = buttons
	rebirthButton = Instance.new("TextButton")
	rebirthButton.Name = "RebirthButton"
	rebirthButton.Position = UDim2.new(0.5, 5, 0, 10)
	rebirthButton.Size = UDim2.new(0.5, -15, 1, -20)
	rebirthButton.BackgroundColor3 = Color3.fromRGB(120, 200, 255)
	rebirthButton.Text = "Rebirth"
	rebirthButton.TextSize = 20
	rebirthButton.TextColor3 = Color3.fromRGB(30, 30, 30)
	rebirthButton.Font = Enum.Font.GothamBold
	rebirthButton.Parent = buttons
	lockButton.MouseButton1Click:Connect(function()
		if lockCallback then
			lockCallback()
		end
	end)
	rebirthButton.MouseButton1Click:Connect(function()
		if rebirthCallback then
			rebirthCallback()
		end
	end)

	textLabel(gui, "Hint", UDim2.new(0.5, 0, 1, -16), UDim2.fromOffset(620, 20), "Dekati conveyor di utara untuk beli brainrot — jaga basemu dari pencuri!", 15, Color3.fromRGB(230, 230, 230), false).AnchorPoint = Vector2.new(0.5, 1)
end

function Hud.onLock(callback)
	lockCallback = callback
end

function Hud.onRebirth(callback)
	rebirthCallback = callback
end

function Hud.toast(text, kind)
	if not toastLabel then
		return
	end
	local color = Color3.fromRGB(255, 255, 255)
	if kind == "good" then
		color = Color3.fromRGB(120, 255, 120)
	elseif kind == "bad" then
		color = Color3.fromRGB(255, 90, 90)
	elseif kind == "warn" then
		color = Color3.fromRGB(255, 215, 0)
	end
	toastLabel.Text = text
	toastLabel.TextColor3 = color
	toastLabel.Visible = true
	toastToken += 1
	local token = toastToken
	task.delay(3, function()
		if token == toastToken then
			toastLabel.Visible = false
		end
	end)
end

function Hud.update(state)
	if not gui then
		return
	end
	moneyLabel.Text = Util.formatMoney(state.money)
	incomeLabel.Text = "+" .. Util.formatMoney(state.income) .. "/dtk"
	rebirthLabel.Text = "Rebirth " .. tostring(state.rebirths) .. " (x" .. string.format("%.2f", state.multiplier) .. ")"
	for i = 1, 8 do
		local owned = state.owned[i]
		if owned then
			local text = owned.name .. " — " .. Util.formatRate(owned.rate)
			if owned.mutation ~= "" then
				text = "[" .. owned.mutation .. "] " .. text
			end
			baseRows[i].Text = text
			baseRows[i].TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			baseRows[i].Text = "— slot kosong —"
			baseRows[i].TextColor3 = Color3.fromRGB(200, 200, 200)
		end
	end
	for i, rarity in ipairs(Catalog.RARITIES) do
		local cheapest = Catalog.cheapestOfRarity(i)
		if state.money >= cheapest.cost then
			ladderRows[i].TextColor3 = Color3.fromRGB(120, 255, 120)
		else
			ladderRows[i].TextColor3 = Color3.fromRGB(200, 200, 200)
		end
	end
	if state.lockRemaining > 0 then
		lockButton.Text = "Terkunci (" .. tostring(state.lockRemaining) .. " dtk)"
	elseif state.lockCooldown > 0 then
		lockButton.Text = "Cooldown (" .. tostring(state.lockCooldown) .. " dtk)"
	else
		lockButton.Text = "Kunci Base (60 dtk)"
	end
	rebirthButton.Text = "Rebirth — " .. Util.formatMoney(state.rebirthCost) .. " (x" .. string.format("%.2f", state.multiplier + 0.25) .. ")"
	if state.waveWarning then
		banner.Visible = true
	else
		banner.Visible = false
	end
	if state.carryingName then
		carryingLabel.Text = "Kamu membawa " .. state.carryingName .. " — LARI KE BASEMU!"
		carryingLabel.Visible = true
	else
		carryingLabel.Visible = false
	end
end

return Hud
