-- Brainrot Bazaar: the threats. Two of them, both real in code:
-- the Tsunami Es Teh that sweeps the map and makes everyone dash home, and
-- Si Pencuri Lele, an NPC thief who raids unlocked bases. Stealing between
-- players rides on the same carrying rules (see GameState.stealBrainrot).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Threat = {}
local waveRunning = false

-- Tour helper for TOUR.json: start a wave right now.
function Threat.startWaveNow(_arg)
	task.spawn(function()
		Threat.runWave()
	end)
end

function Threat.runWave()
	if waveRunning then
		return
	end
	waveRunning = true
	local GameState = require(script.Parent:WaitForChild("GameState"))
	local World = require(script.Parent:WaitForChild("World"))
	GameState.waveWarning = true
	GameState.pushAll()
	GameState.notifyAll("TSUNAMI ES TEH datang dalam 15 detik! Lari ke basemu!", "warn")
	task.wait(Config.WAVE_WARNING)
	GameState.waveWarning = false
	GameState.pushAll()
	local wall = World.createWaveWall()
	local knocked = {}
	local tween = TweenService:Create(wall, TweenInfo.new(Config.WAVE_SWEEP_TIME, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(0, 13, 70),
	})
	tween:Play()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local wallZ = wall.Position.Z
		for _, player in ipairs(Players:GetPlayers()) do
			local state = GameState.players[player]
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and state and not knocked[player] then
				local safe = state.baseIndex and World.isInsideBase(player, state.baseIndex)
				if not safe and math.abs(root.Position.Z - wallZ) < 4 then
					knocked[player] = true
					root.AssemblyLinearVelocity = Vector3.new(0, 25, 50)
					if state.carrying then
						GameState.dropCarried(player, "wave")
						GameState.notify(player, "Tsunami menjatuhkan brainrot curianmu!", "bad")
					end
				end
			end
		end
	end)
	tween.Completed:Wait()
	conn:Disconnect()
	wall:Destroy()
	GameState.notifyAll("Tsunami Es Teh lewat! Pasar aman lagi.", "good")
	GameState.pushAll()
	waveRunning = false
end

local function walkModelTo(model, target, speed, opts)
	opts = opts or {}
	while model.Parent do
		local pos = model.PrimaryPart.Position
		local delta = Vector3.new(target.X - pos.X, 0, target.Z - pos.Z)
		local dist = delta.Magnitude
		if dist < 1.5 then
			return true
		end
		if opts.stopCheck and opts.stopCheck() then
			return false
		end
		local step = math.min(dist, speed * 0.1)
		local nextPos = Vector3.new(pos.X + delta.Unit.X * step, 1.7, pos.Z + delta.Unit.Z * step)
		local cf = CFrame.new(nextPos)
		model:PivotTo(cf)
		if opts.onStep then
			opts.onStep(cf)
		end
		task.wait(0.1)
	end
	return false
end

local function pickThiefTarget()
	local GameState = require(script.Parent:WaitForChild("GameState"))
	local bestPlayer, bestValue = nil, 0
	for player, state in pairs(GameState.players) do
		if state.baseIndex and not GameState.isBaseLocked(state.baseIndex) and #state.owned > 0 then
			local value = 0
			for _, id in ipairs(state.owned) do
				local record = GameState.brainrots[id]
				if record then
					value += record.rate
				end
			end
			if value > bestValue then
				bestValue, bestPlayer = value, player
			end
		end
	end
	return bestPlayer
end

local function richestBrainrot(player)
	local GameState = require(script.Parent:WaitForChild("GameState"))
	local state = GameState.players[player]
	local best, bestRate = nil, 0
	for _, id in ipairs(state.owned) do
		local record = GameState.brainrots[id]
		if record and record.rate > bestRate then
			best, bestRate = record, record.rate
		end
	end
	return best
end

function Threat.runThief()
	local GameState = require(script.Parent:WaitForChild("GameState"))
	local World = require(script.Parent:WaitForChild("World"))
	local target = pickThiefTarget()
	if not target then
		return
	end
	local targetState = GameState.players[target]
	if not targetState then
		return
	end
	local thief = World.createThiefModel(CFrame.new(-65, 1.7, 0))
	GameState.notifyAll("Si Pencuri Lele muncul di pasar! Jaga basemu!", "warn")
	local base = World.bases[targetState.baseIndex]
	local arrived = walkModelTo(thief, Vector3.new(base.position.X, 1.7, base.position.Z), 8, {
		stopCheck = function()
			return not GameState.players[target]
		end,
	})
	if not arrived or not thief.Parent then
		thief:Destroy()
		return
	end
	local record = richestBrainrot(target)
	if not record then
		thief:Destroy()
		return
	end
	World.freeSlot(record)
	record.state = "stolen_npc"
	record.carrier = thief
	for i, id in ipairs(targetState.owned) do
		if id == record.id then
			table.remove(targetState.owned, i)
			break
		end
	end
	World.refreshPrompt(record)
	GameState.notify(target, "Si Pencuri Lele mengambil " .. record.def.name .. "! Tangkap dia!", "bad")
	GameState.pushState(target)
	local function playerNear()
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and (root.Position - thief.PrimaryPart.Position).Magnitude < 4 then
				return true
			end
		end
		return false
	end
	local escaped = walkModelTo(thief, Vector3.new(-65, 1.7, 0), 9, {
		stopCheck = playerNear,
		onStep = function(cf)
			if record.model and record.model.Parent then
				record.model:PivotTo(cf * CFrame.new(0, 5, 0))
			end
		end,
	})
	if not escaped then
		-- Caught: the brainrot goes home to its owner.
		record.state = "base"
		record.carrier = nil
		table.insert(targetState.owned, record.id)
		World.placeOnBase(record, targetState.baseIndex)
		World.refreshPrompt(record)
		GameState.notify(target, record.def.name .. " kembali! Kamu menangkap pencurinya!", "good")
		GameState.pushState(target)
	else
		-- He got away with it: the brainrot is gone for good.
		if record.model then
			record.model:Destroy()
		end
		GameState.unregisterBrainrot(record.id)
		GameState.notify(target, "Si Pencuri Lele kabur dengan " .. record.def.name .. "!", "bad")
	end
	thief:Destroy()
end

function Threat.start()
	local GameState = require(script.Parent:WaitForChild("GameState"))
	local World = require(script.Parent:WaitForChild("World"))
	task.spawn(function()
		while true do
			task.wait(Config.WAVE_INTERVAL)
			Threat.runWave()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(Config.THIEF_INTERVAL)
			Threat.runThief()
		end
	end)
	-- Carried brainrots ride above their carrier's head; reaching your own
	-- base delivers them, and the victim tagging you drops them.
	RunService.Heartbeat:Connect(function()
		for player, state in pairs(GameState.players) do
			if state.carrying then
				local record = GameState.brainrots[state.carrying]
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if record and record.model and root then
					record.model:PivotTo(CFrame.new(root.Position + Vector3.new(0, 5, 0)))
					if state.baseIndex and World.isInsideBase(player, state.baseIndex) then
						GameState.deliverCarried(player)
					else
						local victim = record.owner
						if victim and victim ~= player then
							local victimChar = victim.Character
							local victimRoot = victimChar and victimChar:FindFirstChild("HumanoidRootPart")
							if victimRoot and (victimRoot.Position - root.Position).Magnitude < 4 then
								GameState.dropCarried(player, "tagged")
							end
						end
					end
				end
			end
		end
	end)
end

return Threat
