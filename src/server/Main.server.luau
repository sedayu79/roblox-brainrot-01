-- Brainrot Bazaar: server boot. Builds the world, claims a base for
-- every player who joins, and starts the conveyor, the economy tick
-- and the threats.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameState = require(script.Parent:WaitForChild("GameState"))
local World = require(script.Parent:WaitForChild("World"))
local Conveyor = require(script.Parent:WaitForChild("Conveyor"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local Threat = require(script.Parent:WaitForChild("Threat"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notify = remotes:WaitForChild("Notify")
local lockBaseRemote = remotes:WaitForChild("LockBase")
local rebirthRemote = remotes:WaitForChild("Rebirth")
local stateUpdate = remotes:WaitForChild("StateUpdate")

World.buildBases()

local function sendState(player)
	local snapshot = GameState.snapshot(player)
	if snapshot ~= nil then
		stateUpdate:FireClient(player, snapshot)
	end
end

local function onPlayerAdded(player)
	GameState.addPlayer(player)
	local base = World.claimBase(player)
	if base == nil then
		notify:FireClient(player, "toast", "Semua base penuh! Tunggu giliran.")
	else
		notify:FireClient(player, "toast", "Selamat datang di Pasar Absurd! Base " .. base.index .. " milikmu.")
	end
	sendState(player)
end

local function onPlayerRemoving(player)
	local state = GameState.get(player)
	if state ~= nil then
		if state.carrying ~= nil then
			Threat.dropCarried(player)
		end
		for _, entry in ipairs(state.owned) do
			if entry.model ~= nil then
				entry.model:Destroy()
			end
		end
	end
	World.releaseBase(player)
	GameState.removePlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

lockBaseRemote.OnServerEvent:Connect(function(player)
	local _, message = GameState.lockBase(player)
	notify:FireClient(player, "toast", message)
	sendState(player)
end)

rebirthRemote.OnServerEvent:Connect(function(player)
	local ok, message, removed = GameState.tryRebirth(player)
	if ok and removed ~= nil then
		for _, entry in ipairs(removed) do
			if entry.model ~= nil then
				entry.model:Destroy()
			end
		end
	end
	notify:FireClient(player, "toast", message)
	sendState(player)
end)

Conveyor.start()
Economy.start()
Threat.start()

print("Brainrot Bazaar server siap: conveyor, ekonomi, tsunami dan pencuri jalan.")
