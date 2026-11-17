-- Brainrot Bazaar: the cast. Twelve original absurd characters on a ladder of
-- six rarities, each with a price, an income per second, a look and an accessory.
-- Nothing here is copied from another brainrot game: the names are our own.

local Catalog = {}

Catalog.RARITIES = {
	{ name = "Common", color = Color3.fromRGB(160, 200, 160), weight = 40 },
	{ name = "Rare", color = Color3.fromRGB(80, 160, 255), weight = 25 },
	{ name = "Epic", color = Color3.fromRGB(180, 90, 255), weight = 15 },
	{ name = "Legendary", color = Color3.fromRGB(255, 200, 40), weight = 10 },
	{ name = "Mythic", color = Color3.fromRGB(255, 80, 120), weight = 6 },
	{ name = "Brainrot God", color = Color3.fromRGB(255, 80, 200), weight = 4 },
}

-- accessory: the extra parts World.buildBrainrotModel bolts onto the body.
Catalog.BRAINROTS = {
	{ id = "lele_terbang", name = "Lele Terbang", rarity = 1, cost = 50, rate = 5,
		color = Color3.fromRGB(120, 160, 200), size = Vector3.new(3, 2.4, 3), shape = "Block", accessory = "wings",
		blurb = "A catfish that learned to fly and never looked back." },
	{ id = "nasi_samurai", name = "Nasi Goreng Samurai", rarity = 1, cost = 100, rate = 8,
		color = Color3.fromRGB(240, 160, 60), size = Vector3.new(3, 3, 3), shape = "Block", accessory = "katana",
		blurb = "Fried rice with a katana. Honor is served hot." },
	{ id = "es_teh_raksasa", name = "Es Teh Raksasa", rarity = 2, cost = 300, rate = 18,
		color = Color3.fromRGB(200, 140, 40), size = Vector3.new(3, 4, 3), shape = "Block", accessory = "straw",
		blurb = "A giant iced tea. Sweet, cold, and judging you." },
	{ id = "ayam_dj", name = "Ayam Geprek DJ", rarity = 2, cost = 500, rate = 28,
		color = Color3.fromRGB(220, 70, 60), size = Vector3.new(3, 3, 3), shape = "Ball", accessory = "headphones",
		blurb = "A smashed fried chicken that drops beats, not crumbs." },
	{ id = "kapten_krupuk", name = "Kapten Krupuk", rarity = 3, cost = 1200, rate = 55,
		color = Color3.fromRGB(245, 225, 170), size = Vector3.new(3.4, 3, 3.4), shape = "Block", accessory = "captainHat",
		blurb = "Captain of the cracker fleet. Crunchy and in charge." },
	{ id = "bakso_blaster", name = "Bakso Blaster", rarity = 3, cost = 2000, rate = 85,
		color = Color3.fromRGB(150, 100, 60), size = Vector3.new(3.4, 3.4, 3.4), shape = "Ball", accessory = "blaster",
		blurb = "A meatball with a blaster. Soup's on, forever." },
	{ id = "raja_rendang", name = "Raja Rendang", rarity = 4, cost = 5000, rate = 170,
		color = Color3.fromRGB(140, 40, 30), size = Vector3.new(3.6, 3.6, 3.6), shape = "Block", accessory = "crown",
		blurb = "The slow-cooked king. Four hours on the throne." },
	{ id = "hantu_indomie", name = "Hantu Indomie", rarity = 4, cost = 8000, rate = 240,
		color = Color3.fromRGB(250, 230, 140), size = Vector3.new(3.2, 4, 3.2), shape = "Block", accessory = "ghost",
		blurb = "An instant-noodle ghost. Gone in three minutes." },
	{ id = "dewa_durian", name = "Dewa Durian", rarity = 5, cost = 20000, rate = 480,
		color = Color3.fromRGB(120, 180, 60), size = Vector3.new(4, 4, 4), shape = "Ball", accessory = "horns",
		blurb = "The durian god. Smells like victory. And durian." },
	{ id = "naga_sate", name = "Naga Sate", rarity = 5, cost = 35000, rate = 700,
		color = Color3.fromRGB(220, 80, 50), size = Vector3.new(4.4, 3.6, 4.4), shape = "Block", accessory = "dragon",
		blurb = "A satay dragon. Ten skewers of pure fire." },
	{ id = "sultan_lele", name = "Sultan Lele Terbang", rarity = 6, cost = 100000, rate = 1500,
		color = Color3.fromRGB(255, 210, 60), size = Vector3.new(4.6, 4, 4.6), shape = "Block", accessory = "sultan",
		blurb = "The flying catfish, crowned. All rivers bow." },
	{ id = "ratu_es_teh", name = "Maha Ratu Es Teh", rarity = 6, cost = 200000, rate = 2400,
		color = Color3.fromRGB(255, 150, 200), size = Vector3.new(4.4, 4.6, 4.4), shape = "Block", accessory = "queen",
		blurb = "Supreme queen of iced tea. Sweetness is law." },
}

-- Mutations rolled on spawn: a name, an income multiplier and a tint.
Catalog.MUTATIONS = {
	{ id = "none", name = "", mult = 1, tint = nil, weight = 70 },
	{ id = "emas", name = "EMAS", mult = 2, tint = Color3.fromRGB(255, 215, 0), weight = 15 },
	{ id = "lava", name = "LAVA", mult = 3, tint = Color3.fromRGB(255, 90, 30), weight = 10 },
	{ id = "pelangi", name = "PELANGI", mult = 5, tint = Color3.fromRGB(200, 80, 255), weight = 5 },
}

function Catalog.getById(id)
	for _, def in ipairs(Catalog.BRAINROTS) do
		if def.id == id then
			return def
		end
	end
	return nil
end

function Catalog.rarityName(index)
	return Catalog.RARITIES[index].name
end

function Catalog.rarityColor(index)
	return Catalog.RARITIES[index].color
end

-- Cheapest brainrot of each rarity, for the HUD ladder.
function Catalog.cheapestOfRarity(index)
	local best = nil
	for _, def in ipairs(Catalog.BRAINROTS) do
		if def.rarity == index and (best == nil or def.cost < best.cost) then
			best = def
		end
	end
	return best
end

local function rollWeighted(list, weightKey)
	local total = 0
	for _, entry in ipairs(list) do
		total += entry[weightKey]
	end
	local roll = math.random() * total
	for _, entry in ipairs(list) do
		roll -= entry[weightKey]
		if roll <= 0 then
			return entry
		end
	end
	return list[1]
end

function Catalog.rollBrainrot()
	local rarity = rollWeighted(Catalog.RARITIES, "weight")
	local pool = {}
	for _, def in ipairs(Catalog.BRAINROTS) do
		if def.rarity == table.find(Catalog.RARITIES, rarity) then
			table.insert(pool, def)
		end
	end
	return pool[math.random(1, #pool)]
end

function Catalog.rollMutation()
	return rollWeighted(Catalog.MUTATIONS, "weight")
end

function Catalog.rebirthCost(rebirths)
	return 10000 * (2 ^ rebirths)
end

return Catalog
