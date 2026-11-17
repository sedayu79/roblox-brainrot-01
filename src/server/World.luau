-- Brainrot Bazaar: builds everything the place shows — the six bases, every
-- brainrot model (body, face, accessory, billboard, prompt), the tsunami wall
-- and the thief. GameState owns the data; this module owns the instances.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local World = {}
World.bases = {} -- [index] = { position, color, yaw, baseCF, slots, sign, lockField, owner }

local function newPart(name, size, color, cf, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = true
	part.Size = size
	part.Color = color
	part.CFrame = cf
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function weldTo(body, part)
	local weld = Instance.new("Weld")
	weld.Part0 = body
	weld.Part1 = part
	weld.C0 = body.CFrame:Inverse() * part.CFrame
	weld.Parent = body
	part.Anchored = false
	part.CanCollide = false
end

-- One base: a pad, three walls, a front lip, eight slot pads, a sign and a lock field.
function World.buildBases()
	local folder = Instance.new("Folder")
	folder.Name = "Bases"
	folder.Parent = Workspace
	for index, position in ipairs(Config.BASE_POSITIONS) do
		local color = Config.BASE_COLORS[index]
		local backward = Vector3.new(position.X, 0, position.Z)
		if backward.Magnitude < 1 then
			backward = Vector3.new(0, 0, 1)
		end
		backward = backward.Unit
		local yaw = math.atan2(backward.X, backward.Z)
		local baseCF = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
		local base = {
			index = index,
			position = position,
			color = color,
			yaw = yaw,
			baseCF = baseCF,
			slots = {},
			owner = nil,
		}
		local function at(lx, y, lz)
			return baseCF * CFrame.new(lx, y, lz)
		end
		local pad = newPart("Pad", Vector3.new(16, 0.5, 16), color, at(0, 0.25, 0))
		pad.Parent = folder
		local back = newPart("BackWall", Vector3.new(16, 6, 1), color, at(0, 3, 7.5))
		back.Parent = folder
		local sideL = newPart("SideWallL", Vector3.new(1, 6, 16), color, at(-7.5, 3, 0))
		sideL.Parent = folder
		local sideR = newPart("SideWallR", Vector3.new(1, 6, 16), color, at(7.5, 3, 0))
		sideR.Parent = folder
		local lip = newPart("FrontLip", Vector3.new(16, 1, 1), color, at(0, 0.5, -7.5))
		lip.Parent = folder
		for _, lx in ipairs({ -5.25, -1.75, 1.75, 5.25 }) do
			for _, lz in ipairs({ -3.5, 3.5 }) do
				local slotPad = newPart("Slot", Vector3.new(3, 0.2, 3), Color3.fromRGB(255, 255, 255), at(lx, 0.6, lz))
				slotPad.Transparency = 0.5
				slotPad.Parent = folder
				table.insert(base.slots, { cf = at(lx, 0.7, lz), takenBy = nil, pad = slotPad })
			end
		end
		local pole = newPart("SignPole", Vector3.new(0.6, 5, 0.6), Color3.fromRGB(70, 50, 30), at(0, 4.5, 7))
		pole.Parent = folder
		local board = newPart("Sign", Vector3.new(9, 3, 0.5), Color3.fromRGB(40, 40, 45), at(0, 7.5, 7))
		board.Parent = folder
		local signGui = Instance.new("BillboardGui")
		signGui.Name = "BaseSign"
		signGui.Adornee = board
		signGui.Size = UDim2.fromOffset(260, 70)
		signGui.StudsOffsetWorldSpace = Vector3.new(0, 0, -1)
		signGui.AlwaysOnTop = true
		signGui.Parent = board
		local signLabel = Instance.new("TextLabel")
		signLabel.Name = "SignText"
		signLabel.Size = UDim2.fromScale(1, 1)
		signLabel.BackgroundTransparency = 1
		signLabel.Text = "Base " .. tostring(index) .. " — kosong"
		signLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		signLabel.TextScaled = true
		signLabel.Font = Enum.Font.GothamBold
		signLabel.Parent = signGui
		base.signLabel = signLabel
		local lockField = newPart("LockField", Vector3.new(16, 6, 0.5), Color3.fromRGB(255, 215, 0), at(0, 3, -7.5))
		lockField.Transparency = 0.7
		lockField.CanCollide = false
		lockField.Visible = false
		lockField.Material = Enum.Material.Neon
		lockField.Parent = folder
		base.lockField = lockField
		World.bases[index] = base
	end
end

function World.claimBase(index, player)
	local base = World.bases[index]
	if not base then
		return
	end
	base.owner = player
	base.signLabel.Text = player.Name .. "'s Base"
end

function World.releaseBase(index)
	local base = World.bases[index]
	if not base then
		return
	end
	base.owner = nil
	base.signLabel.Text = "Base " .. tostring(index) .. " — kosong"
	World.setBaseLock(index, false)
end

function World.setBaseLock(index, locked)
	local base = World.bases[index]
	if not base then
		return
	end
	base.lockField.Visible = locked
	base.lockField.CanCollide = locked
end

function World.isInsideBase(player, index)
	local base = World.bases[index]
	local character = player.Character
	if not base or not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local localPos = base.baseCF:PointToObjectSpace(root.Position)
	return math.abs(localPos.X) <= 8 and math.abs(localPos.Z) <= 8
end

function World.freeSlot(record)
	if record.slotIndex and record.baseIndex then
		local base = World.bases[record.baseIndex]
		if base and base.slots[record.slotIndex] then
			base.slots[record.slotIndex].takenBy = nil
		end
	end
	record.slotIndex = nil
	record.slotCF = nil
end

-- Move a brainrot onto a free slot of a base; returns the slot number.
function World.placeOnBase(record, baseIndex)
	local base = World.bases[baseIndex]
	if not base then
		return nil
	end
	local slotIndex = nil
	for i, slot in ipairs(base.slots) do
		if not slot.takenBy then
			slotIndex = i
			break
		end
	end
	if not slotIndex then
		return nil
	end
	World.freeSlot(record)
	base.slots[slotIndex].takenBy = record.id
	record.baseIndex = baseIndex
	record.slotIndex = slotIndex
	local slot = base.slots[slotIndex]
	local body = record.model.PrimaryPart
	local targetCF = slot.cf * CFrame.new(0, record.def.size.Y / 2 + 0.1, 0)
		* CFrame.Angles(0, base.yaw + math.pi, 0)
	record.slotCF = targetCF
	record.moving = true
	local tween = TweenService:Create(body, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = targetCF })
	tween.Completed:Connect(function()
		record.moving = false
	end)
	tween:Play()
	return slotIndex
end

local function addEyes(model, body, size)
	local eyeY = size.Y * 0.2
	local eyeZ = size.Z / 2 + 0.06
	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Size = Vector3.new(0.55, 0.7, 0.1)
		eye.Color = Color3.fromRGB(255, 255, 255)
		eye.CFrame = body.CFrame * CFrame.new(side * size.X * 0.22, eyeY, eyeZ)
		eye.Parent = model
		weldTo(body, eye)
		local pupil = Instance.new("Part")
		pupil.Name = "Pupil"
		pupil.Size = Vector3.new(0.25, 0.35, 0.06)
		pupil.Color = Color3.fromRGB(20, 20, 20)
		pupil.CFrame = body.CFrame * CFrame.new(side * size.X * 0.22, eyeY, eyeZ + 0.05)
		pupil.Parent = model
		weldTo(body, pupil)
	end
end

local function addAccessory(model, body, def)
	local size = def.size
	local top = body.CFrame * CFrame.new(0, size.Y / 2, 0)
	local function accPart(name, partSize, color, cf, shape)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = partSize
		part.Color = color
		part.CFrame = cf
		if shape == "Ball" then
			part.Shape = Enum.PartType.Ball
		elseif shape == "Cylinder" then
			part.Shape = Enum.PartType.Cylinder
			part.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
		end
		part.Parent = model
		weldTo(body, part)
		return part
	end
	if def.accessory == "wings" then
		accPart("WingL", Vector3.new(2, 0.2, 1.4), Color3.fromRGB(255, 255, 255), body.CFrame * CFrame.new(-size.X / 2 - 0.9, 0.4, 0) * CFrame.Angles(0, 0, math.rad(25)))
		accPart("WingR", Vector3.new(2, 0.2, 1.4), Color3.fromRGB(255, 255, 255), body.CFrame * CFrame.new(size.X / 2 + 0.9, 0.4, 0) * CFrame.Angles(0, 0, math.rad(-25)))
	elseif def.accessory == "katana" then
		accPart("Katana", Vector3.new(0.25, 3.4, 0.6), Color3.fromRGB(200, 200, 210), body.CFrame * CFrame.new(size.X / 2 + 0.5, 0.6, 0.4) * CFrame.Angles(math.rad(35), 0, 0))
		accPart("Headband", Vector3.new(size.X + 0.2, 0.4, 0.2), Color3.fromRGB(200, 30, 30), body.CFrame * CFrame.new(0, size.Y / 2 - 0.4, size.Z / 2 + 0.05))
	elseif def.accessory == "straw" then
		accPart("Straw", Vector3.new(0.4, 2.6, 0.4), Color3.fromRGB(230, 40, 40), top * CFrame.new(0.5, 1.1, 0) * CFrame.Angles(0, 0, math.rad(-18)))
	elseif def.accessory == "headphones" then
		accPart("PhonesL", Vector3.new(0.5, 1.2, 1.2), Color3.fromRGB(30, 30, 35), body.CFrame * CFrame.new(-size.X / 2 - 0.2, 0.4, 0))
		accPart("PhonesR", Vector3.new(0.5, 1.2, 1.2), Color3.fromRGB(30, 30, 35), body.CFrame * CFrame.new(size.X / 2 + 0.2, 0.4, 0))
		accPart("Band", Vector3.new(size.X + 0.4, 0.4, 0.8), Color3.fromRGB(30, 30, 35), top * CFrame.new(0, 0.1, 0))
	elseif def.accessory == "captainHat" then
		accPart("HatTop", Vector3.new(size.X * 0.7, 0.9, size.Z * 0.7), Color3.fromRGB(255, 255, 255), top * CFrame.new(0, 0.45, 0))
		accPart("HatBrim", Vector3.new(size.X + 0.4, 0.25, size.Z + 0.4), Color3.fromRGB(30, 30, 40), top * CFrame.new(0, 0.05, 0))
	elseif def.accessory == "blaster" then
		accPart("Blaster", Vector3.new(0.9, 0.9, 2.6), Color3.fromRGB(90, 90, 100), body.CFrame * CFrame.new(0, 0, size.Z / 2 + 1))
	elseif def.accessory == "crown" then
		accPart("CrownBase", Vector3.new(size.X * 0.6, 0.6, size.Z * 0.6), Color3.fromRGB(255, 215, 0), top * CFrame.new(0, 0.3, 0))
		accPart("Spike1", Vector3.new(0.4, 0.9, 0.4), Color3.fromRGB(255, 215, 0), top * CFrame.new(-size.X * 0.2, 0.9, 0))
		accPart("Spike2", Vector3.new(0.4, 1.1, 0.4), Color3.fromRGB(255, 215, 0), top * CFrame.new(0, 1, 0))
		accPart("Spike3", Vector3.new(0.4, 0.9, 0.4), Color3.fromRGB(255, 215, 0), top * CFrame.new(size.X * 0.2, 0.9, 0))
	elseif def.accessory == "ghost" then
		-- The ghost's see-through body is set on the body itself; give it a little tail.
		accPart("GhostTail", Vector3.new(size.X * 0.5, 1, size.Z * 0.5), Color3.fromRGB(250, 230, 140), body.CFrame * CFrame.new(0, -size.Y / 2 - 0.3, 0))
	elseif def.accessory == "horns" then
		local hornL = Instance.new("WedgePart")
		hornL.Name = "HornL"
		hornL.Size = Vector3.new(0.7, 1.6, 0.7)
		hornL.Color = Color3.fromRGB(240, 230, 200)
		hornL.CFrame = top * CFrame.new(-size.X * 0.25, 0.7, 0) * CFrame.Angles(0, 0, math.rad(20))
		hornL.Parent = model
		weldTo(body, hornL)
		local hornR = Instance.new("WedgePart")
		hornR.Name = "HornR"
		hornR.Size = Vector3.new(0.7, 1.6, 0.7)
		hornR.Color = Color3.fromRGB(240, 230, 200)
		hornR.CFrame = top * CFrame.new(size.X * 0.25, 0.7, 0) * CFrame.Angles(0, 0, math.rad(-20))
		hornR.Parent = model
		weldTo(body, hornR)
	elseif def.accessory == "dragon" then
		accPart("WingL", Vector3.new(2.4, 0.2, 1.8), Color3.fromRGB(255, 180, 60), body.CFrame * CFrame.new(-size.X / 2 - 1, 0.6, -0.4) * CFrame.Angles(0, 0, math.rad(30)))
		accPart("WingR", Vector3.new(2.4, 0.2, 1.8), Color3.fromRGB(255, 180, 60), body.CFrame * CFrame.new(size.X / 2 + 1, 0.6, -0.4) * CFrame.Angles(0, 0, math.rad(-30)))
		accPart("HornL", Vector3.new(0.5, 1.2, 0.5), Color3.fromRGB(240, 230, 200), top * CFrame.new(-size.X * 0.2, 0.6, 0))
		accPart("HornR", Vector3.new(0.5, 1.2, 0.5), Color3.fromRGB(240, 230, 200), top * CFrame.new(size.X * 0.2, 0.6, 0))
	elseif def.accessory == "sultan" then
		accPart("CrownBase", Vector3.new(size.X * 0.6, 0.6, size.Z * 0.6), Color3.fromRGB(255, 215, 0), top * CFrame.new(0, 0.3, 0))
		accPart("Spike2", Vector3.new(0.4, 1.1, 0.4), Color3.fromRGB(255, 215, 0), top * CFrame.new(0, 1, 0))
		accPart("WingL", Vector3.new(2, 0.2, 1.4), Color3.fromRGB(255, 255, 255), body.CFrame * CFrame.new(-size.X / 2 - 0.9, 0.4, 0) * CFrame.Angles(0, 0, math.rad(25)))
		accPart("WingR", Vector3.new(2, 0.2, 1.4), Color3.fromRGB(255, 255, 255), body.CFrame * CFrame.new(size.X / 2 + 0.9, 0.4, 0) * CFrame.Angles(0, 0, math.rad(-25)))
	elseif def.accessory == "queen" then
		accPart("CrownBase", Vector3.new(size.X * 0.6, 0.6, size.Z * 0.6), Color3.fromRGB(255, 215, 0), top * CFrame.new(0, 0.3, 0))
		accPart("Spike1", Vector3.new(0.4, 0.9, 0.4), Color3.fromRGB(255, 215, 0), top * CFrame.new(-size.X * 0.2, 0.9, 0))
		accPart("Spike2", Vector3.new(0.4, 1.1, 0.4), Color3.fromRGB(255, 215, 0), top * CFrame.new(0, 1, 0))
		accPart("Spike3", Vector3.new(0.4, 0.9, 0.4), Color3.fromRGB(255, 215, 0), top * CFrame.new(size.X * 0.2, 0.9, 0))
		accPart("Straw", Vector3.new(0.4, 2.6, 0.4), Color3.fromRGB(255, 80, 160), top * CFrame.new(0.5, 1.1, 0) * CFrame.Angles(0, 0, math.rad(-18)))
	end
end

-- The name / rarity / $ per second label floating over a brainrot.
function World.setBillboard(model, def, mutation, rate, ownerName)
	local body = model.PrimaryPart
	local old = body:FindFirstChild("BrainrotLabel")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Adornee = body
	gui.Size = UDim2.fromOffset(220, 84)
	gui.StudsOffsetWorldSpace = Vector3.new(0, def.size.Y / 2 + 2.4, 0)
	gui.AlwaysOnTop = true
	gui.Parent = body
	local function label(name, y, text, color, bold)
		local t = Instance.new("TextLabel")
		t.Name = name
		t.Size = UDim2.new(1, 0, 0, 26)
		t.Position = UDim2.new(0, 0, 0, y)
		t.BackgroundTransparency = 1
		t.Text = text
		t.TextColor3 = color
		t.TextScaled = true
		t.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
		t.TextStrokeTransparency = 0.4
		t.Parent = gui
		return t
	end
	local title = def.name
	if mutation and mutation.name ~= "" then
		title = mutation.name .. " " .. title
	end
	label("NameLabel", 0, title, Color3.fromRGB(255, 255, 255), true)
	label("RarityLabel", 26, Catalog.rarityName(def.rarity), Catalog.rarityColor(def.rarity), true)
	label("RateLabel", 52, Util.formatRate(rate), Color3.fromRGB(120, 255, 120), true)
	if ownerName then
		gui.Size = UDim2.fromOffset(220, 110)
		label("OwnerLabel", 78, "Milik: " .. ownerName, Color3.fromRGB(255, 255, 255), false)
	end
end

-- Build one brainrot's model at a CFrame. The prompt is configured by refreshPrompt.
function World.buildBrainrotModel(def, mutation, rate, cf)
	local model = Instance.new("Model")
	model.Name = def.id
	local bodyColor = def.color
	if mutation and mutation.tint then
		bodyColor = mutation.tint
	end
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Anchored = true
	body.CanCollide = true
	body.Size = def.size
	body.Color = bodyColor
	body.Material = Enum.Material.SmoothPlastic
	body.CFrame = cf
	if def.shape == "Ball" then
		body.Shape = Enum.PartType.Ball
	end
	if def.accessory == "ghost" then
		body.Transparency = 0.35
	end
	body.Parent = model
	model.PrimaryPart = body
	addEyes(model, body, def.size)
	addAccessory(model, body, def)
	World.setBillboard(model, def, mutation, rate, nil)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Interact"
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	model.Parent = Workspace
	return model
end

-- Set the prompt's text and availability from the brainrot's state.
function World.refreshPrompt(record)
	local model = record.model
	if not model then
		return
	end
	local prompt = model.PrimaryPart:FindFirstChild("Interact")
	if not prompt then
		return
	end
	if record.state == "conveyor" then
		local text = record.def.name .. " — " .. Util.formatMoney(record.cost)
		if record.mutation.name ~= "" then
			text = text .. " [" .. record.mutation.name .. "]"
		end
		prompt.ActionText = "Beli"
		prompt.ObjectText = text
		prompt.HoldDuration = 0.3
		prompt.Enabled = true
	elseif record.state == "base" then
		prompt.ActionText = "Curi"
		prompt.ObjectText = record.def.name .. " — " .. Util.formatRate(record.rate)
		prompt.HoldDuration = 0.5
		local locked = false
		if record.owner then
			local GameState = require(script.Parent:WaitForChild("GameState"))
			local ownerState = GameState.players[record.owner]
			if ownerState and ownerState.baseIndex then
				locked = GameState.isBaseLocked(ownerState.baseIndex)
			end
		end
		prompt.Enabled = not locked
	else
		prompt.Enabled = false
	end
end

-- The tsunami wall: a tall amber slab that sweeps the map from north to south.
function World.createWaveWall()
	local wall = Instance.new("Part")
	wall.Name = "TsunamiWall"
	wall.Anchored = true
	wall.CanCollide = false
	wall.Size = Vector3.new(150, 26, 2)
	wall.Color = Color3.fromRGB(255, 170, 40)
	wall.Material = Enum.Material.Neon
	wall.Transparency = 0.45
	wall.CFrame = CFrame.new(0, 13, -70)
	wall.Parent = Workspace
	return wall
end

-- Si Pencuri Lele: the NPC thief, moved by CFrame (no Humanoid needed).
function World.createThiefModel(cf)
	local model = Instance.new("Model")
	model.Name = "PencuriLele"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Anchored = true
	body.CanCollide = false
	body.Size = Vector3.new(3, 3.4, 2)
	body.Color = Color3.fromRGB(40, 40, 50)
	body.CFrame = cf
	body.Parent = model
	model.PrimaryPart = body
	local mask = Instance.new("Part")
	mask.Name = "Mask"
	mask.Size = Vector3.new(2.4, 0.7, 0.3)
	mask.Color = Color3.fromRGB(15, 15, 15)
	mask.CFrame = cf * CFrame.new(0, 0.6, 1.05)
	mask.Parent = model
	weldTo(body, mask)
	local sack = Instance.new("Part")
	sack.Name = "Sack"
	sack.Size = Vector3.new(2, 2, 1.4)
	sack.Color = Color3.fromRGB(140, 100, 50)
	sack.CFrame = cf * CFrame.new(0, 0.4, -1.4)
	sack.Parent = model
	weldTo(body, sack)
	local gui = Instance.new("BillboardGui")
	gui.Name = "ThiefLabel"
	gui.Adornee = body
	gui.Size = UDim2.fromOffset(220, 30)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.Parent = body
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "SI PENCURI LELE!"
	label.TextColor3 = Color3.fromRGB(255, 80, 80)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	model.Parent = Workspace
	return model
end

return World
