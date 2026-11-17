-- Brainrot Bazaar: the single source of truth. Every player's money, brainrots,
-- base, lock and rebirth lives here; every other server module reads it or asks it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local GameState = {}

GameState.players = {} -- [Player] = { money, rebirths, multiplier, owned, baseIndex, lockUntil, lockCooldownUntil, carrying }
GameState.brainrots = {} -- [id] = { id, def, mutation, rate, cost, owner, state, model, slotIndex, bornAt, beltX }
GameState.nextBrainrotId = 1
GameState.startedAt = os.time()

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StateUpdate = Remotes:WaitForChild("StateUpdate")
local Notify = Remotes:WaitForChild("Notify")

-- Seconds since the server started; locks and cooldowns are measured on it.
function GameState.now()
	return os.time() - GameState.startedAt
end

function GameState.nextId()
	local id = "br" .. tostring(GameState.nextBrainrotId)
	GameState.nextBrainrotId += 1
	return id
end

function GameState.notify(player, text, kind)
	Notify:FireClient(player, text, kind or "info")
end

function GameState.notifyAll(text, kind)
	for _, player in ipairs(Players:GetPlayers()) do
		GameState.notify(player, text, kind)
	end
end

function GameState.registerBrainrot(record)
	GameState.brainrots[record.id] = record
	-- One prompt, two jobs: on the belt it sells, on a base it steals.
	local prompt = record.model.PrimaryPart:FindFirstChild("Interact")
	if prompt then
		prompt.Triggered:Connect(function(player)
			if record.state == "conveyor" then
				GameState.buyBrainrot(player, record.id)
			elseif record.state == "base" then
				GameState.stealBrainrot(player, record.id)
			end
		end)
	end
end

function GameState.unregisterBrainrot(id)
	GameState.brainrots[id] = nil
end

function GameState.incomePerSecond(player)
	local state = GameState.players[player]
	if not state then
		return 0
	end
	local total = 0
	for _, id in ipairs(state.owned) do
		local record = GameState.brainrots[id]
		if record and record.state == "base" then
			total += record.rate
		end
	end
	return total * state.multiplier
end

function GameState.addMoney(player, amount)
	local state = GameState.players[player]
	if state then
		state.money += amount
	end
end

-- The state the HUD shows, sent to one client every second and on every change.
function GameState.serialize(player)
	local state = GameState.players[player]
	if not state then
		return nil
	end
	local owned = {}
	for _, id in ipairs(state.owned) do
		local record = GameState.brainrots[id]
		if record then
			table.insert(owned, {
				name = record.def.name,
				rarity = Catalog.rarityName(record.def.rarity),
				rate = record.rate,
				mutation = record.mutation.name,
			})
		end
	end
	local now = GameState.now()
	local carryingName = nil
	if state.carrying then
		local record = GameState.brainrots[state.carrying]
		if record then
			carryingName = record.def.name
		end
	end
	return {
		money = math.floor(state.money),
		income = math.floor(GameState.incomePerSecond(player)),
		rebirths = state.rebirths,
		multiplier = state.multiplier,
		rebirthCost = Catalog.rebirthCost(state.rebirths),
		owned = owned,
		baseIndex = state.baseIndex,
		lockRemaining = math.max(0, state.lockUntil - now),
		lockCooldown = math.max(0, state.lockCooldownUntil - now),
		carryingName = carryingName,
		waveWarning = GameState.waveWarning or false,
	}
end

function GameState.pushState(player)
	local data = GameState.serialize(player)
	if data then
		StateUpdate:FireClient(player, data)
	end
end

function GameState.pushAll()
	for _, player in ipairs(Players:GetPlayers()) do
		GameState.pushState(player)
	end
end

function GameState.isBaseLocked(index)
	for _, state in pairs(GameState.players) do
		if state.baseIndex == index and state.lockUntil > GameState.now() then
			return true
		end
	end
	return false
end

function GameState.freeBase()
	for index = 1, Config.BASE_COUNT do
		local taken = false
		for _, state in pairs(GameState.players) do
			if state.baseIndex == index then
				taken = true
				break
			end
		end
		if not taken then
			return index
		end
	end
	return nil
end

function GameState.newPlayer(player)
	local World = require(script.Parent:WaitForChild("World"))
	local baseIndex = GameState.freeBase()
	GameState.players[player] = {
		money = Config.START_MONEY,
		rebirths = 0,
		multiplier = 1,
		owned = {},
		baseIndex = baseIndex,
		lockUntil = 0,
		lockCooldownUntil = 0,
		carrying = nil,
	}
	if baseIndex then
		World.claimBase(baseIndex, player)
		GameState.notify(player, "Selamat datang di Pasar Brainrot! Basemu: plot " .. tostring(baseIndex), "good")
	else
		GameState.notify(player, "Semua base penuh — tunggu ada yang pergi, lalu join lagi.", "bad")
	end
	task.delay(0.5, function()
		GameState.pushState(player)
	end)
end

function GameState.removePlayer(player)
	local World = require(script.Parent:WaitForChild("World"))
	local state = GameState.players[player]
	if not state then
		return
	end
	if state.carrying then
		GameState.dropCarried(player, "left")
	end
	for _, id in ipairs(state.owned) do
		local record = GameState.brainrots[id]
		if record and record.model then
			record.model:Destroy()
		end
		GameState.unregisterBrainrot(id)
	end
	if state.baseIndex then
		World.releaseBase(state.baseIndex)
	end
	GameState.players[player] = nil
end

-- Buy a brainrot off the conveyor and put it on the buyer's base.
function GameState.buyBrainrot(player, id)
	local World = require(script.Parent:WaitForChild("World"))
	local state = GameState.players[player]
	local record = GameState.brainrots[id]
	if not state or not record or record.state ~= "conveyor" then
		return false
	end
	if not state.baseIndex then
		GameState.notify(player, "Kamu belum punya base!", "bad")
		return false
	end
	if #state.owned >= Config.BASE_SLOT_COUNT then
		GameState.notify(player, "Basemu penuh! Rebirth untuk slot baru.", "bad")
		return false
	end
	if state.money < record.cost then
		GameState.notify(player, "Uang kurang! Butuh " .. Util.formatMoney(record.cost) .. ".", "bad")
		return false
	end
	state.money -= record.cost
	record.state = "base"
	record.owner = player
	table.insert(state.owned, id)
	local slotIndex = World.placeOnBase(record, state.baseIndex)
	record.slotIndex = slotIndex
	World.refreshPrompt(record)
	GameState.notify(player, "Dibeli: " .. record.def.name .. " (" .. Util.formatRate(record.rate) .. ")!", "good")
	GameState.pushState(player)
	return true
end

-- Steal a brainrot from another player's unlocked base; the thief must carry it home.
function GameState.stealBrainrot(player, id)
	local state = GameState.players[player]
	local record = GameState.brainrots[id]
	if not state or not record or record.state ~= "base" then
		return false
	end
	if record.owner == player then
		return false
	end
	if state.carrying then
		GameState.notify(player, "Kamu sudah membawa satu brainrot!", "bad")
		return false
	end
	if not state.baseIndex then
		GameState.notify(player, "Kamu belum punya base!", "bad")
		return false
	end
	if #state.owned >= Config.BASE_SLOT_COUNT then
		GameState.notify(player, "Basemu penuh!", "bad")
		return false
	end
	local victimState = GameState.players[record.owner]
	if not victimState or GameState.isBaseLocked(victimState.baseIndex) then
		GameState.notify(player, "Base itu sedang terkunci!", "bad")
		return false
	end
	local World = require(script.Parent:WaitForChild("World"))
	World.freeSlot(record)
	record.state = "carried"
	record.carrier = player
	state.carrying = id
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.CARRY_SPEED
		end
	end
	World.refreshPrompt(record)
	GameState.notify(player, "Kamu mencuri " .. record.def.name .. "! Lari ke basemu!", "warn")
	if record.owner then
		GameState.notify(record.owner, player.Name .. " mencuri " .. record.def.name .. " dari basemu! Kejar dia!", "bad")
	end
	GameState.pushState(player)
	return true
end

-- The carrier reached their own base: the brainrot is theirs now.
function GameState.deliverCarried(player)
	local World = require(script.Parent:WaitForChild("World"))
	local state = GameState.players[player]
	if not state or not state.carrying then
		return false
	end
	local record = GameState.brainrots[state.carrying]
	if not record then
		state.carrying = nil
		return false
	end
	local victim = record.owner
	record.state = "base"
	record.owner = player
	record.carrier = nil
	state.carrying = nil
	table.insert(state.owned, record.id)
	local slotIndex = World.placeOnBase(record, state.baseIndex)
	record.slotIndex = slotIndex
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.NORMAL_SPEED
		end
	end
	World.refreshPrompt(record)
	GameState.notify(player, "Berhasil! " .. record.def.name .. " sekarang milikmu!", "good")
	if victim and victim ~= player then
		local victimState = GameState.players[victim]
		if victimState then
			for i, ownedId in ipairs(victimState.owned) do
				if ownedId == record.id then
					table.remove(victimState.owned, i)
					break
				end
			end
			GameState.notify(victim, record.def.name .. " berhasil dicuri!", "bad")
			GameState.pushState(victim)
		end
	end
	GameState.pushState(player)
	return true
end

-- The carrier dropped it (tagged, caught by the wave, or left): it goes home.
function GameState.dropCarried(player, why)
	local World = require(script.Parent:WaitForChild("World"))
	local state = GameState.players[player]
	if not state or not state.carrying then
		return false
	end
	local record = GameState.brainrots[state.carrying]
	state.carrying = nil
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.NORMAL_SPEED
		end
	end
	if not record then
		return false
	end
	record.state = "base"
	record.carrier = nil
	if record.owner and GameState.players[record.owner] then
		local ownerState = GameState.players[record.owner]
		local slotIndex = World.placeOnBase(record, ownerState.baseIndex)
		record.slotIndex = slotIndex
		World.refreshPrompt(record)
		if why == "tagged" then
			GameState.notify(record.owner, record.def.name .. " kembali! Kamu menangkap pencurinya!", "good")
		end
		GameState.pushState(record.owner)
	else
		if record.model then
			record.model:Destroy()
		end
		GameState.unregisterBrainrot(record.id)
	end
	GameState.pushState(player)
	return true
end

-- Lock your base for a minute so nobody can steal from it.
function GameState.lockBase(player)
	local World = require(script.Parent:WaitForChild("World"))
	local state = GameState.players[player]
	if not state or not state.baseIndex then
		return false
	end
	local now = GameState.now()
	if state.lockCooldownUntil > now then
		GameState.notify(player, "Kunci masih cooldown: " .. tostring(state.lockCooldownUntil - now) .. " detik lagi.", "bad")
		return false
	end
	state.lockUntil = now + Config.LOCK_DURATION
	state.lockCooldownUntil = now + Config.LOCK_COOLDOWN
	World.setBaseLock(state.baseIndex, true)
	task.delay(Config.LOCK_DURATION, function()
		if GameState.players[player] and state.lockUntil <= GameState.now() then
			World.setBaseLock(state.baseIndex, false)
		end
	end)
	GameState.notify(player, "Base terkunci selama " .. tostring(Config.LOCK_DURATION) .. " detik!", "good")
	GameState.pushState(player)
	return true
end

-- Rebirth: give up your money and brainrots for a permanent income boost.
function GameState.rebirth(player)
	local World = require(script.Parent:WaitForChild("World"))
	local state = GameState.players[player]
	if not state then
		return false
	end
	local cost = Catalog.rebirthCost(state.rebirths)
	if state.money < cost then
		GameState.notify(player, "Rebirth butuh " .. Util.formatMoney(cost) .. "!", "bad")
		return false
	end
	for _, id in ipairs(state.owned) do
		local record = GameState.brainrots[id]
		if record and record.model then
			record.model:Destroy()
		end
		GameState.unregisterBrainrot(id)
	end
	state.owned = {}
	state.money = Config.START_MONEY
	state.rebirths += 1
	state.multiplier = 1 + Config.REBIRTH_MULTIPLIER_STEP * state.rebirths
	GameState.notify(player, "REBIRTH " .. tostring(state.rebirths) .. "! Pendapatan x" .. string.format("%.2f", state.multiplier) .. " selamanya!", "good")
	GameState.pushState(player)
	return true
end

-- Tour helper for TOUR.json: give every player test money in Studio.
function GameState.tourGrantAll(amount)
	local value = tonumber(amount) or 5000
	for _, player in ipairs(Players:GetPlayers()) do
		GameState.addMoney(player, value)
		GameState.pushState(player)
	end
end

return GameState
