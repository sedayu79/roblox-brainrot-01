-- Brainrot Bazaar: the conveyor. Brainrots roll in on the north lane, ride the
-- belt west to east, and a player who walks up can buy one with a prompt.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Config = require(Shared:WaitForChild("Config"))

local Conveyor = {}
local folder = nil

function Conveyor.countOnBelt()
	local count = 0
	local GameState = require(script.Parent:WaitForChild("GameState"))
	for _, record in pairs(GameState.brainrots) do
		if record.state == "conveyor" then
			count += 1
		end
	end
	return count
end

function Conveyor.spawnBrainrot()
	if Conveyor.countOnBelt() >= Config.CONVEYOR_MAX then
		return
	end
	local GameState = require(script.Parent:WaitForChild("GameState"))
	local World = require(script.Parent:WaitForChild("World"))
	local def = Catalog.rollBrainrot()
	local mutation = Catalog.rollMutation()
	local rate = def.rate * mutation.mult
	local cf = CFrame.new(Config.CONVEYOR_START_X, Config.CONVEYOR_Y + def.size.Y / 2, Config.CONVEYOR_Z)
	local model = World.buildBrainrotModel(def, mutation, rate, cf)
	model.Parent = folder
	local id = GameState.nextId()
	local record = {
		id = id,
		def = def,
		mutation = mutation,
		rate = rate,
		cost = def.cost,
		owner = nil,
		state = "conveyor",
		model = model,
		slotIndex = nil,
		bornAt = os.clock(),
		beltX = Config.CONVEYOR_START_X,
		phase = math.random() * math.pi * 2,
	}
	GameState.registerBrainrot(record)
	World.refreshPrompt(record)
end

function Conveyor.start()
	folder = Instance.new("Folder")
	folder.Name = "ConveyorBrainrots"
	folder.Parent = Workspace
	Conveyor.spawnBrainrot()
	task.spawn(function()
		while true do
			task.wait(Config.CONVEYOR_SPAWN_INTERVAL)
			Conveyor.spawnBrainrot()
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		local GameState = require(script.Parent:WaitForChild("GameState"))
		local toRemove = {}
		for id, record in pairs(GameState.brainrots) do
			if record.state == "conveyor" and record.model and record.model.Parent then
				record.beltX += Config.CONVEYOR_SPEED * dt
				local bob = math.sin(os.clock() * 3 + record.phase) * 0.15
				local cf = CFrame.new(
					record.beltX,
					Config.CONVEYOR_Y + record.def.size.Y / 2 + bob,
					Config.CONVEYOR_Z
				)
				record.model:PivotTo(cf)
				if record.beltX >= Config.CONVEYOR_END_X or os.clock() - record.bornAt > Config.CONVEYOR_LIFETIME then
					table.insert(toRemove, id)
				end
			end
		end
		for _, id in ipairs(toRemove) do
			local record = GameState.brainrots[id]
			if record and record.model then
				record.model:Destroy()
			end
			GameState.unregisterBrainrot(id)
		end
	end)
end

return Conveyor
