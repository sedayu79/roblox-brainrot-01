-- Brainrot Bazaar: the conveyor lane. Every few seconds a new
-- brainrot rides the belt; buy it with the prompt before it rides
-- off the end, and it walks to a free slot on your base.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Config = require(Shared:WaitForChild("Config"))
local GameState = require(script.Parent:WaitForChild("GameState"))
local World = require(script.Parent:WaitForChild("World"))
local Threat = require(script.Parent:WaitForChild("Threat"))

local Conveyor = {}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notify = remotes:WaitForChild("Notify")

local function beltPosition(x)
	return Vector3.new(x, 1, Config.BeltZ)
end

-- Ride the belt west to east. Returns false when the model was sold
-- or destroyed mid-ride, so the caller knows not to despawn it.
local function rideBelt(model)
	local steps = math.floor(Config.BeltRideSeconds / 0.1)
	for step = 1, steps do
		if model.Parent == nil or model:GetAttribute("Sold") then
			return false
		end
		local alpha = step / steps
		local x = Config.BeltEnterX + (Config.BeltExitX - Config.BeltEnterX) * alpha
		model:PivotTo(CFrame.new(beltPosition(x)))
		task.wait(0.1)
	end
	return model.Parent ~= nil and not model:GetAttribute("Sold")
end

function Conveyor.spawnOne()
	local char = Catalog.randomCharacter()
	local mutation = Catalog.rollMutation()
	local model = World.makeBrainrotModel(char, mutation, char.cost)
	model.Parent = workspace
	model:PivotTo(CFrame.new(beltPosition(Config.BeltEnterX)))
	local body = model:FindFirstChild("Body")
	local prompt = body and body:FindFirstChild("BuyPrompt")
	if prompt == nil then
		model:Destroy()
		return
	end
	prompt.Triggered:Connect(function(player)
		if model:GetAttribute("Sold") then
			return
		end
		local state = GameState.get(player)
		if state == nil then
			return
		end
		if World.baseOf(player) == nil then
			notify:FireClient(player, "toast", "Kamu belum punya base!")
			return
		end
		if state.money < char.cost then
			notify:FireClient(player, "toast", "Uang tidak cukup! " .. char.name .. " harganya $" .. tostring(char.cost) .. ".")
			return
		end
		local entry = GameState.addBrainrot(player, char.id, mutation.id)
		if entry == nil then
			notify:FireClient(player, "toast", "Base penuh! Rebirth untuk mengosongkannya.")
			return
		end
		GameState.trySpend(player, char.cost)
		model:SetAttribute("Sold", true)
		prompt:Destroy()
		entry.model = model
		Threat.placeOnBase(player, entry)
		notify:FireClient(player, "toast", "Dibeli: " .. Catalog.displayName(char, mutation) .. " ($" .. tostring(char.income * mutation.mult) .. "/dtk)!")
	end)
	local reachedEnd = rideBelt(model)
	if reachedEnd then
		-- Nobody bought it: it rides off the end and vanishes.
		model:Destroy()
	end
end

function Conveyor.start()
	task.spawn(function()
		while true do
			task.wait(Config.SpawnInterval)
			task.spawn(Conveyor.spawnOne)
		end
	end)
end

return Conveyor
