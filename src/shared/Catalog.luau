-- Brainrot Bazaar: the cast, the rarity ladder and the mutations.
-- Every character is an original Indonesian joke: a flying catfish,
-- a samurai plate of fried rice, a giant iced tea, and friends.

local Catalog = {}

Catalog.Rarities = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Brainrot God" }

Catalog.RarityColors = {
	Common = Color3.fromRGB(200, 200, 200),
	Rare = Color3.fromRGB(80, 170, 255),
	Epic = Color3.fromRGB(170, 90, 255),
	Legendary = Color3.fromRGB(255, 180, 40),
	Mythic = Color3.fromRGB(255, 70, 90),
	["Brainrot God"] = Color3.fromRGB(255, 215, 0),
}

Catalog.Characters = {
	{ id = "lele_terbang", name = "Lele Terbang", rarity = "Common", cost = 50, income = 2, color = Color3.fromRGB(90, 120, 200), blurb = "Ikan lele yang menolak berenang. Ia terbang." },
	{ id = "nasi_goreng_samurai", name = "Nasi Goreng Samurai", rarity = "Common", cost = 150, income = 5, color = Color3.fromRGB(220, 160, 60), blurb = "Nasi goreng bersenjatakan sumpit katana." },
	{ id = "es_teh_raksasa", name = "Es Teh Raksasa", rarity = "Rare", cost = 400, income = 12, color = Color3.fromRGB(200, 120, 40), blurb = "Segelas es teh setinggi rumah. Manisnya kebangetan." },
	{ id = "ayam_geprek_dj", name = "Ayam Geprek DJ", rarity = "Rare", cost = 900, income = 25, color = Color3.fromRGB(255, 90, 90), blurb = "Ayam geprek yang nge-DJ di warung jam 2 pagi." },
	{ id = "kapten_krupuk", name = "Kapten Krupuk", rarity = "Epic", cost = 2000, income = 55, color = Color3.fromRGB(255, 220, 150), blurb = "Kapten kapal kerupuk. Renyah, tapi berwibawa." },
	{ id = "bakso_blaster", name = "Bakso Blaster", rarity = "Epic", cost = 4500, income = 120, color = Color3.fromRGB(160, 90, 60), blurb = "Bakso yang menembakkan kuah panas ke musuh." },
	{ id = "raja_rendang", name = "Raja Rendang", rarity = "Legendary", cost = 10000, income = 260, color = Color3.fromRGB(120, 60, 20), blurb = "Raja segala rendang. Dagingnya empuk, tahtanya abadi." },
	{ id = "hantu_indomie", name = "Hantu Indomie", rarity = "Legendary", cost = 22000, income = 550, color = Color3.fromRGB(255, 240, 120), blurb = "Hantu mie instan yang menghantui dapur kos." },
	{ id = "dewa_durian", name = "Dewa Durian", rarity = "Mythic", cost = 50000, income = 1200, color = Color3.fromRGB(180, 220, 60), blurb = "Dewa durian. Baunya sakral, rasanya surga." },
	{ id = "naga_sate", name = "Naga Sate", rarity = "Mythic", cost = 120000, income = 2800, color = Color3.fromRGB(255, 120, 40), blurb = "Naga yang badannya tusukan sate. Jangan digigit." },
	{ id = "sultan_lele_terbang", name = "Sultan Lele Terbang", rarity = "Brainrot God", cost = 300000, income = 7000, color = Color3.fromRGB(255, 215, 0), blurb = "Lele terbang yang sudah jadi sultan. Punya istana di awan." },
	{ id = "maha_ratu_es_teh", name = "Maha Ratu Es Teh", rarity = "Brainrot God", cost = 750000, income = 18000, color = Color3.fromRGB(255, 150, 180), blurb = "Ratu segala es teh. Satu tegukan, langsung kaya." },
}

Catalog.Mutations = {
	{ id = "biasa", name = "", mult = 1, chance = 0.70, color = Color3.fromRGB(255, 255, 255) },
	{ id = "emas", name = "Emas", mult = 2, chance = 0.18, color = Color3.fromRGB(255, 215, 0) },
	{ id = "lava", name = "Lava", mult = 3, chance = 0.09, color = Color3.fromRGB(255, 80, 20) },
	{ id = "pelangi", name = "Pelangi", mult = 5, chance = 0.03, color = Color3.fromRGB(150, 220, 255) },
}

function Catalog.getById(id)
	for _, char in ipairs(Catalog.Characters) do
		if char.id == id then
			return char
		end
	end
	return nil
end

function Catalog.getMutationById(id)
	for _, mutation in ipairs(Catalog.Mutations) do
		if mutation.id == id then
			return mutation
		end
	end
	return Catalog.Mutations[1]
end

function Catalog.randomCharacter()
	return Catalog.Characters[math.random(1, #Catalog.Characters)]
end

function Catalog.rollMutation()
	local roll = math.random()
	local running = 0
	for _, mutation in ipairs(Catalog.Mutations) do
		running += mutation.chance
		if roll <= running then
			return mutation
		end
	end
	return Catalog.Mutations[1]
end

function Catalog.incomeOf(char, mutation)
	return char.income * mutation.mult
end

function Catalog.displayName(char, mutation)
	if mutation.id == "biasa" then
		return char.name
	end
	return mutation.name .. " " .. char.name
end

return Catalog
