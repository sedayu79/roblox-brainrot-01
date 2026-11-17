-- Brainrot Bazaar: single source of truth for every player's data.
-- Money, owned brainrots, rebirths, base lock and what a player is
-- carrying live here; no other server module keeps its own copy.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Config = require(Shared:WaitForChild("Config"))

local GameState = {}

GameState.Players = {}
local nextUid = 0

local function freshState()
	return {
		money = Config.StartCash,
		rebirths = 0,
		owned = {}, -- { uid, charId, mutationId, slot, model, stolenFrom }
		lockUntil = 0,
		lockReadyAt = 0,
		carrying = nil, -- owned entry stolen from someone else
		baseIndex = nil,
	}
end

function GameState.addPlayer(player)
	if GameState.Players[player] == nil then
		GameState.Players[player] = freshState()
	end
	return GameState.Players[player]
end

function GameState.removePlayer(player)
	GameState.Players[player] = nil
end

function GameState.get(player)
	return GameState.Players[player]
end

function GameState.incomePerSecond(player)
	local state = GameState.Players[player]
	if state == nil then
		return 0
	end
	local total = 0
	for _, entry in ipairs(state.owned) do
		local char = Catalog.getById(entry.charId)
		if char then
			local mutation = Catalog.getMutationById(entry.mutationId)
			total += char.income * mutation.mult
		end
	end
	return total * (1 + Config.RebirthBonus * state.rebirths)
end

function GameState.trySpend(player, amount)
	local state = GameState.Players[player]
	if state == nil or state.money < amount then
		return false
	end
	state.money -= amount
	return true
end

function GameState.freeSlot(state)
	local used = {}
	for _, entry in ipairs(state.owned) do
		used[entry.slot] = true
	end
	for slot = 1, Config.MaxBaseSlots do
		if not used[slot] then
			return slot
		end
	end
	return nil
end

function GameState.addBrainrot(player, charId, mutationId)
	local state = GameState.Players[player]
	if state == nil then
		return nil
	end
	local slot = GameState.freeSlot(state)
	if slot == nil then
		return nil
	end
	nextUid += 1
	local entry = {
		uid = nextUid,
		charId = charId,
		mutationId = mutationId,
		slot = slot,
		model = nil,
		stolenFrom = nil,
	}
	table.insert(state.owned, entry)
	return entry
end

function GameState.removeBrainrot(player, uid)
	local state = GameState.Players[player]
	if state == nil then
		return nil
	end
	for i, entry in ipairs(state.owned) do
		if entry.uid == uid then
			table.remove(state.owned, i)
			return entry
		end
	end
	return nil
end

function GameState.findBrainrot(player, uid)
	local state = GameState.Players[player]
	if state == nil then
		return nil
	end
	for _, entry in ipairs(state.owned) do
		if entry.uid == uid then
			return entry
		end
	end
	return nil
end

function GameState.isLocked(player)
	local state = GameState.Players[player]
	if state == nil then
		return false
	end
	return os.time() < state.lockUntil
end

function GameState.lockBase(player)
	local state = GameState.Players[player]
	if state == nil then
		return false, "Data pemain belum siap."
	end
	local now = os.time()
	if now < state.lockReadyAt then
		return false, "Kunci base masih cooldown."
	end
	state.lockUntil = now + Config.LockDuration
	state.lockReadyAt = state.lockUntil + Config.LockCooldown
	return true, "Base terkunci " .. Config.LockDuration .. " detik!"
end

function GameState.rebirthCost(player)
	local state = GameState.Players[player]
	if state == nil then
		return Config.RebirthBaseCost
	end
	return Config.RebirthBaseCost * (state.rebirths + 1)
end

function GameState.tryRebirth(player)
	local state = GameState.Players[player]
	if state == nil then
		return false, "Data pemain belum siap.", nil
	end
	local cost = GameState.rebirthCost(player)
	if state.money < cost then
		return false, "Uang tidak cukup untuk rebirth.", nil
	end
	state.money = Config.StartCash
	state.rebirths += 1
	local removed = state.owned
	state.owned = {}
	return true, "Rebirth ke-" .. state.rebirths .. "! Income +25% permanen.", removed
end

function GameState.snapshot(player)
	local state = GameState.Players[player]
	if state == nil then
		return nil
	end
	local ownedList = {}
	for _, entry in ipairs(state.owned) do
		local char = Catalog.getById(entry.charId)
		if char then
			local mutation = Catalog.getMutationById(entry.mutationId)
			table.insert(ownedList, {
				name = Catalog.displayName(char, mutation),
				rarity = char.rarity,
				income = char.income * mutation.mult,
			})
		end
	end
	return {
		money = state.money,
		income = GameState.incomePerSecond(player),
		rebirths = state.rebirths,
		rebirthCost = GameState.rebirthCost(player),
		lockUntil = state.lockUntil,
		lockReadyAt = state.lockReadyAt,
		carrying = state.carrying ~= nil,
		owned = ownedList,
	}
end

-- Tour helper for TOUR.json: give every player test money in Studio.
function GameState.tourGrantAll(amount)
	local value = tonumber(amount) or 5000
	local Players = game:GetService("Players")
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local stateUpdate = remotes:WaitForChild("StateUpdate")
	for _, player in ipairs(Players:GetPlayers()) do
		local state = GameState.Players[player]
		if state ~= nil then
			state.money += value
			local snapshot = GameState.snapshot(player)
			if snapshot ~= nil then
				stateUpdate:FireClient(player, snapshot)
			end
		end
	end
end

return GameState
