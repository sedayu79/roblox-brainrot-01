-- Brainrot Bazaar: builds the physical world — player bases and the
-- brainrot models that walk around in it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Config = require(Shared:WaitForChild("Config"))

local World = {}

World.Bases = {}

local BASE_COLORS = {
	Color3.fromRGB(90, 160, 220),
	Color3.fromRGB(220, 120, 90),
	Color3.fromRGB(120, 200, 110),
	Color3.fromRGB(220, 190, 70),
	Color3.fromRGB(180, 120, 220),
	Color3.fromRGB(90, 200, 200),
}

local function makePart(name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function slotPosition(center, slot)
	-- Eight slots: two rows of four across the base floor.
	local col = (slot - 1) % 4
	local row = math.floor((slot - 1) / 4)
	local x = center.X - 5.25 + col * 3.5
	local z = center.Z - 2.5 + row * 5
	return Vector3.new(x, center.Y + 1, z)
end

function World.buildBases()
	local folder = Instance.new("Folder")
	folder.Name = "Bases"
	folder.Parent = workspace
	for index, center in ipairs(Config.BaseSpots) do
		local tint = BASE_COLORS[(index - 1) % #BASE_COLORS + 1]
		local floor = makePart("BaseFloor" .. index, Vector3.new(Config.BaseSize, 1, Config.BaseSize), Vector3.new(center.X, 0.5, center.Z), tint, Enum.Material.Concrete)
		floor.Parent = folder
		-- Low see-through walls so the plot reads as a base.
		for _, offset in ipairs({ Vector3.new(0, 1.5, -Config.BaseSize / 2), Vector3.new(0, 1.5, Config.BaseSize / 2) }) do
			local wall = makePart("BaseWall" .. index, Vector3.new(Config.BaseSize, 2, 0.6), center + offset, tint, Enum.Material.SmoothPlastic)
			wall.Transparency = 0.35
			wall.Parent = folder
		end
		-- Sign post at the front corner, with a billboard for the owner's name.
		local sign = makePart("BaseSign" .. index, Vector3.new(1, 4, 1), center + Vector3.new(-Config.BaseSize / 2 + 1, 2.5, Config.BaseSize / 2 - 1), Color3.fromRGB(60, 45, 30), Enum.Material.Wood)
		sign.Parent = folder
		local board = Instance.new("BillboardGui")
		board.Name = "BaseBoard"
		board.Size = UDim2.fromOffset(180, 60)
		board.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
		board.AlwaysOnTop = true
		board.Adornee = sign
		board.Parent = sign
		local label = Instance.new("TextLabel")
		label.Name = "OwnerLabel"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
		label.BackgroundTransparency = 0.2
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 20
		label.Text = "BASE " .. index .. "\n(kosong)"
		label.Parent = board
		-- Slot pads so players can see where brainrots stand.
		local slots = {}
		for slot = 1, Config.MaxBaseSlots do
			local pos = slotPosition(center, slot)
			slots[slot] = pos
			local pad = makePart("SlotPad" .. slot, Vector3.new(3, 0.2, 3), Vector3.new(pos.X, 1.1, pos.Z), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
			pad.Transparency = 0.7
			pad.CanCollide = false
			pad.Parent = folder
		end
		World.Bases[index] = {
			index = index,
			center = center,
			owner = nil,
			slots = slots,
			sign = sign,
			board = board,
			ownerLabel = label,
		}
	end
	return World.Bases
end

function World.claimBase(player)
	for _, base in ipairs(World.Bases) do
		if base.owner == nil then
			base.owner = player
			base.ownerLabel.Text = "BASE " .. base.index .. "\n" .. player.DisplayName
			return base
		end
	end
	return nil
end

function World.releaseBase(player)
	for _, base in ipairs(World.Bases) do
		if base.owner == player then
			base.owner = nil
			base.ownerLabel.Text = "BASE " .. base.index .. "\n(kosong)"
			return base
		end
	end
	return nil
end

function World.baseOf(player)
	for _, base in ipairs(World.Bases) do
		if base.owner == player then
			return base
		end
	end
	return nil
end

function World.isInsideBase(player, base)
	local character = player.Character
	if character == nil then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return false
	end
	local half = Config.BaseSize / 2
	return math.abs(root.Position.X - base.center.X) <= half
		and math.abs(root.Position.Z - base.center.Z) <= half
end

-- Glide a model from where it is to a target CFrame in small steps.
function World.glideModel(model, targetCFrame, seconds)
	local start = model:GetPivot()
	local steps = math.max(1, math.floor(seconds / 0.05))
	for step = 1, steps do
		if model.Parent == nil then
			return false
		end
		local alpha = step / steps
		model:PivotTo(start:Lerp(targetCFrame, alpha))
		task.wait(0.05)
	end
	return model.Parent ~= nil
end

function World.makeBrainrotModel(char, mutation, price)
	local display = Catalog.displayName(char, mutation)
	local model = Instance.new("Model")
	model.Name = display
	local body = makePart("Body", Vector3.new(3, 3, 3), Vector3.new(0, 1.5, 0), char.color, Enum.Material.SmoothPlastic)
	body.Parent = model
	local head = makePart("Head", Vector3.new(2, 2, 2), Vector3.new(0, 4, 0), char.color, Enum.Material.SmoothPlastic)
	head.Parent = model
	local snout = makePart("Snout", Vector3.new(1.4, 0.8, 1.2), Vector3.new(0, 3.8, 1.4), Color3.fromRGB(255, 220, 180), Enum.Material.SmoothPlastic)
	snout.Parent = model
	-- Mutation crown: a glowing block on top, tinted by the mutation.
	if mutation.id ~= "biasa" then
		local crown = makePart("MutationCrown", Vector3.new(2.4, 0.6, 2.4), Vector3.new(0, 5.3, 0), mutation.color, Enum.Material.Neon)
		crown.Parent = model
	end
	model.PrimaryPart = body
	-- Billboard: name, rarity, income and price, readable from the plaza.
	local board = Instance.new("BillboardGui")
	board.Name = "BrainrotBoard"
	board.Size = UDim2.fromOffset(220, 90)
	board.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
	board.AlwaysOnTop = true
	board.Adornee = body
	board.Parent = body
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.4, 0)
	title.BackgroundTransparency = 1
	title.TextColor3 = Catalog.RarityColors[char.rarity]
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 22
	title.TextStrokeTransparency = 0.4
	title.Text = display
	title.Parent = board
	local rarity = Instance.new("TextLabel")
	rarity.Name = "Rarity"
	rarity.Size = UDim2.new(1, 0, 0.3, 0)
	rarity.Position = UDim2.new(0, 0, 0.4, 0)
	rarity.BackgroundTransparency = 1
	rarity.TextColor3 = Color3.fromRGB(255, 255, 255)
	rarity.Font = Enum.Font.GothamBold
	rarity.TextSize = 16
	rarity.Text = char.rarity .. "  •  $" .. tostring(char.income * mutation.mult) .. "/dtk"
	rarity.Parent = board
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "Price"
	priceLabel.Size = UDim2.new(1, 0, 0.3, 0)
	priceLabel.Position = UDim2.new(0, 0, 0.7, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.TextColor3 = Color3.fromRGB(140, 255, 140)
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.TextSize = 18
	priceLabel.Text = "BELI $" .. tostring(price)
	priceLabel.Parent = board
	-- Buy prompt lives on the body; the conveyor wires it up.
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Beli"
	prompt.ObjectText = display
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	return model
end

function World.makeThiefModel()
	local model = Instance.new("Model")
	model.Name = "Si Pencuri Lele"
	local body = makePart("Body", Vector3.new(2.5, 3, 1.5), Vector3.new(0, 1.5, 0), Color3.fromRGB(40, 40, 50), Enum.Material.SmoothPlastic)
	body.Parent = model
	local head = makePart("Head", Vector3.new(2, 2, 2), Vector3.new(0, 4, 0), Color3.fromRGB(90, 120, 200), Enum.Material.SmoothPlastic)
	head.Parent = model
	local mask = makePart("Mask", Vector3.new(2.2, 0.7, 0.5), Vector3.new(0, 4.2, 1), Color3.fromRGB(20, 20, 25), Enum.Material.SmoothPlastic)
	mask.Parent = model
	model.PrimaryPart = body
	local board = Instance.new("BillboardGui")
	board.Name = "ThiefBoard"
	board.Size = UDim2.fromOffset(220, 30)
	board.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	board.AlwaysOnTop = true
	board.Adornee = body
	board.Parent = body
	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 80, 80)
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 22
	label.Text = "SI PENCURI LELE!"
	label.Parent = board
	return model
end

return World
