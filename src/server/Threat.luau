-- Brainrot Bazaar: the two threats that force a dash home — the
-- Tsunami Es Teh wave and Si Pencuri Lele, the NPC thief — plus the
-- stealing and carrying rules between players.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Config = require(Shared:WaitForChild("Config"))
local GameState = require(script.Parent:WaitForChild("GameState"))
local World = require(script.Parent:WaitForChild("World"))

local Threat = {}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notify = remotes:WaitForChild("Notify")

local function toast(player, text)
	notify:FireClient(player, "toast", text)
end

-- Walk a brainrot onto a free slot of its owner's base and arm the
-- steal prompt on it, so other players can try to take it.
function Threat.placeOnBase(player, entry)
	local char = Catalog.getById(entry.charId)
	if char == nil then
		return false
	end
	local mutation = Catalog.getMutationById(entry.mutationId)
	local base = World.baseOf(player)
	local model = entry.model
	if base == nil or model == nil then
		return false
	end
	task.spawn(function()
		World.glideModel(model, CFrame.new(base.slots[entry.slot]), 2.5)
		Threat.armStealPrompt(player, entry, model, char, mutation)
	end)
	return true
end

function Threat.armStealPrompt(owner, entry, model, char, mutation)
	local body = model:FindFirstChild("Body")
	if body == nil then
		return
	end
	local old = body:FindFirstChild("StealPrompt")
	if old ~= nil then
		old:Destroy()
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Curi"
	prompt.ObjectText = Catalog.displayName(char, mutation)
	prompt.HoldDuration = 1.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	prompt.Triggered:Connect(function(thief)
		Threat.trySteal(thief, owner, entry)
	end)
end

function Threat.trySteal(thief, owner, entry)
	local thiefState = GameState.get(thief)
	local ownerState = GameState.get(owner)
	if thiefState == nil or ownerState == nil then
		return
	end
	if thief == owner then
		return
	end
	if thiefState.carrying ~= nil then
		toast(thief, "Kamu sudah membawa satu brainrot!")
		return
	end
	if GameState.isLocked(owner) then
		toast(thief, "Base " .. owner.DisplayName .. " terkunci!")
		return
	end
	if GameState.findBrainrot(owner, entry.uid) == nil then
		return
	end
	GameState.removeBrainrot(owner, entry.uid)
	entry.stolenFrom = owner
	thiefState.carrying = entry
	local body = entry.model and entry.model:FindFirstChild("Body")
	local stealPrompt = body and body:FindFirstChild("StealPrompt")
	if stealPrompt ~= nil then
		stealPrompt:Destroy()
	end
	local char = Catalog.getById(entry.charId)
	local mutation = Catalog.getMutationById(entry.mutationId)
	local display = char and Catalog.displayName(char, mutation) or "brainrot"
	toast(thief, "Kamu mencuri " .. display .. "! Bawa pulang ke basemu!")
	toast(owner, thief.DisplayName .. " mencuri " .. display .. " dari basemu! Kejar dia!")
	-- The stolen brainrot rides above its thief until it is delivered.
	task.spawn(function()
		while entry.model ~= nil and entry.model.Parent ~= nil do
			local character = thief.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root == nil then
				break
			end
			entry.model:PivotTo(CFrame.new(root.Position + Vector3.new(0, 5, 0)))
			local base = World.baseOf(thief)
			if base ~= nil and World.isInsideBase(thief, base) then
				Threat.deposit(thief, entry)
				return
			end
			task.wait(0.1)
		end
	end)
end

-- The thief reached their own base: the brainrot is theirs now.
function Threat.deposit(thief, entry)
	local state = GameState.get(thief)
	if state == nil or state.carrying ~= entry then
		return
	end
	state.carrying = nil
	local fresh = GameState.addBrainrot(thief, entry.charId, entry.mutationId)
	if fresh == nil then
		-- Base full: the brainrot escapes back to its old owner.
		Threat.returnToOwner(entry)
		toast(thief, "Base penuh! Brainrot curianmu kabur pulang.")
		return
	end
	fresh.model = entry.model
	Threat.placeOnBase(thief, fresh)
	local char = Catalog.getById(entry.charId)
	local mutation = Catalog.getMutationById(entry.mutationId)
	toast(thief, "Berhasil! " .. Catalog.displayName(char, mutation) .. " sekarang milikmu!")
end

-- Send a carried brainrot home to the player it was stolen from.
function Threat.returnToOwner(entry)
	local victim = entry.stolenFrom
	if victim == nil or GameState.get(victim) == nil then
		if entry.model ~= nil then
			entry.model:Destroy()
		end
		return
	end
	local fresh = GameState.addBrainrot(victim, entry.charId, entry.mutationId)
	if fresh == nil then
		if entry.model ~= nil then
			entry.model:Destroy()
		end
		return
	end
	fresh.model = entry.model
	Threat.placeOnBase(victim, fresh)
	local char = Catalog.getById(entry.charId)
	local mutation = Catalog.getMutationById(entry.mutationId)
	toast(victim, Catalog.displayName(char, mutation) .. " kembali ke basemu!")
end

-- The carrier dropped what they were holding: it goes home.
function Threat.dropCarried(player)
	local state = GameState.get(player)
	if state == nil or state.carrying == nil then
		return
	end
	local entry = state.carrying
	state.carrying = nil
	Threat.returnToOwner(entry)
end

local function runTsunami()
	notify:FireAllClients("tsunamiWarning", "TSUNAMI ES TEH datang! Lari ke base!")
	task.wait(Config.TsunamiWarningSeconds)
	-- The wave: a huge translucent wall sweeping north to south.
	local wave = Instance.new("Part")
	wave.Name = "TsunamiWave"
	wave.Size = Vector3.new(240, 30, 8)
	wave.Position = Vector3.new(0, 10, -70)
	wave.Color = Color3.fromRGB(60, 140, 255)
	wave.Material = Enum.Material.SmoothPlastic
	wave.Transparency = 0.35
	wave.Anchored = true
	wave.CanCollide = false
	wave.Parent = workspace
	for _ = 1, 100 do
		if wave.Parent == nil then
			break
		end
		wave.Position += Vector3.new(0, 0, 1.5)
		task.wait(0.08)
	end
	-- Anyone caught outside their own base drops what they carry
	-- and loses a slice of their cash.
	for _, player in ipairs(Players:GetPlayers()) do
		local base = World.baseOf(player)
		local safe = base ~= nil and World.isInsideBase(player, base)
		if not safe then
			local state = GameState.get(player)
			if state ~= nil then
				if state.carrying ~= nil then
					Threat.dropCarried(player)
				end
				state.money = math.floor(state.money * (1 - Config.TsunamiCashLoss))
				toast(player, "Tsunami Es Teh menyapumu! -10% uang.")
			end
		end
	end
	wave:Destroy()
	notify:FireAllClients("tsunamiEnd", "")
end

local function runThief()
	-- Pick a random unlocked base that actually holds brainrots.
	local candidates = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local state = GameState.get(player)
		if state ~= nil and #state.owned > 0 and not GameState.isLocked(player) then
			table.insert(candidates, player)
		end
	end
	if #candidates == 0 then
		return
	end
	local victim = candidates[math.random(1, #candidates)]
	local state = GameState.get(victim)
	if state == nil or #state.owned == 0 then
		return
	end
	local entry = state.owned[math.random(1, #state.owned)]
	local base = World.baseOf(victim)
	if base == nil then
		return
	end
	local model = World.makeThiefModel()
	model.Parent = workspace
	model:PivotTo(CFrame.new(Vector3.new(0, 1, -60)))
	notify:FireAllClients("toast", "Si Pencuri Lele muncul di pasar! Jaga basemu!")
	World.glideModel(model, CFrame.new(base.center + Vector3.new(0, 1, 0)), 6)
	if model.Parent == nil then
		return
	end
	if GameState.findBrainrot(victim, entry.uid) ~= nil then
		GameState.removeBrainrot(victim, entry.uid)
		if entry.model ~= nil then
			entry.model:Destroy()
		end
		local char = Catalog.getById(entry.charId)
		local mutation = Catalog.getMutationById(entry.mutationId)
		toast(victim, "Si Pencuri Lele mencuri " .. Catalog.displayName(char, mutation) .. " dari basemu!")
	end
	World.glideModel(model, CFrame.new(Vector3.new(60, 1, -60)), 6)
	model:Destroy()
end

-- Tour helper for TOUR.json: start a wave right now.
function Threat.startWaveNow(_arg)
	task.spawn(runTsunami)
end

function Threat.start()
	task.spawn(function()
		while true do
			task.wait(Config.TsunamiInterval)
			task.spawn(runTsunami)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(Config.ThiefInterval)
			task.spawn(runThief)
		end
	end)
end

return Threat
