-- Brainrot Bazaar: tuning knobs for the whole game.
-- One place for every number the designers tweak, so the server and
-- the client always agree on timings, prices and rewards.

local Config = {}

-- Starting money for a fresh player.
Config.StartCash = 100

-- How often a new brainrot rolls onto the conveyor (seconds).
Config.SpawnInterval = 7

-- Conveyor lane: brainrots enter at x = -45 and ride to x = +45.
Config.BeltZ = -45
Config.BeltEnterX = -45
Config.BeltExitX = 45
Config.BeltRideSeconds = 14

-- Player bases: six plots around the plaza edges.
Config.BaseSpots = {
	Vector3.new(-48, 0, -20),
	Vector3.new(-48, 0, 0),
	Vector3.new(-48, 0, 20),
	Vector3.new(48, 0, -20),
	Vector3.new(48, 0, 0),
	Vector3.new(48, 0, 20),
}
Config.BaseSize = 16
Config.MaxBaseSlots = 8

-- Base lock: a locked base cannot be stolen from.
Config.LockDuration = 60
Config.LockCooldown = 120

-- Tsunami Es Teh sweeps the map on this timer.
Config.TsunamiInterval = 180
Config.TsunamiWarningSeconds = 10
Config.TsunamiCashLoss = 0.10

-- Si Pencuri Lele, the NPC thief, visits on this timer.
Config.ThiefInterval = 75

-- Rebirth: each rebirth adds +25% income and costs more than the last.
Config.RebirthBaseCost = 50000
Config.RebirthBonus = 0.25

return Config
