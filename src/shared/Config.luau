-- Brainrot Bazaar: shared tuning. One place for every number the game balances on.

local Config = {}

-- Money
Config.START_MONEY = 100
Config.REBIRTH_BASE_COST = 10000
Config.REBIRTH_MULTIPLIER_STEP = 0.25

-- Conveyor (the brainrot lane on the north side, z = -45, running west to east)
Config.CONVEYOR_SPAWN_INTERVAL = 7 -- seconds between spawns
Config.CONVEYOR_SPEED = 3 -- studs per second
Config.CONVEYOR_MAX = 8 -- brainrots on the belt at once
Config.CONVEYOR_LIFETIME = 75 -- seconds before an unbought brainrot walks off
Config.CONVEYOR_START_X = -42
Config.CONVEYOR_END_X = 42
Config.CONVEYOR_Z = -45
Config.CONVEYOR_Y = 1 -- belt top

-- Bases (six plots ringing the plaza; the server builds them at runtime)
Config.BASE_COUNT = 6
Config.BASE_SLOT_COUNT = 8
Config.BASE_POSITIONS = {
	Vector3.new(50, 0, 0),
	Vector3.new(35, 0, 35),
	Vector3.new(0, 0, 50),
	Vector3.new(-35, 0, 35),
	Vector3.new(-50, 0, 0),
	Vector3.new(-35, 0, -35),
}
Config.BASE_COLORS = {
	Color3.fromRGB(220, 60, 60),
	Color3.fromRGB(60, 120, 220),
	Color3.fromRGB(60, 200, 90),
	Color3.fromRGB(240, 200, 40),
	Color3.fromRGB(170, 80, 220),
	Color3.fromRGB(240, 130, 40),
}

-- Base lock (the steal defence)
Config.LOCK_DURATION = 60 -- seconds a lock holds
Config.LOCK_COOLDOWN = 150 -- seconds before the owner can lock again

-- Movement
Config.NORMAL_SPEED = 16
Config.CARRY_SPEED = 10 -- slowed while hauling a stolen brainrot

-- Tsunami Es Teh (the hazard wave)
Config.WAVE_INTERVAL = 180 -- seconds between waves
Config.WAVE_WARNING = 15 -- seconds of warning before the wall sweeps
Config.WAVE_SWEEP_TIME = 12 -- seconds for the wall to cross the map

-- Si Pencuri Lele (the NPC thief)
Config.THIEF_INTERVAL = 90 -- seconds between thief visits

return Config
