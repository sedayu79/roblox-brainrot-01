# Brainrot Bazaar — Curi Lele Terbang

A 3D Steal-a-Brainrot game for make.fun's "Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01).

**The game:** you spawn in Pasar Absurd, a market plaza with a conveyor lane on the north side. Absurd brainrot characters ride the belt — buy one with a prompt and it walks to your base and earns money every second. Spend it on rarer brainrots, climb six rarities (Common → Rare → Epic → Legendary → Mythic → Brainrot God), roll mutations (Emas ×2, Lava ×3, Pelangi ×5), and rebirth for a permanent income boost. Two threats keep you running home: other players (or Si Pencuri Lele, the NPC thief) can steal from your base unless you lock it for 60 seconds, and every three minutes a Tsunami Es Teh sweeps the map — get caught outside your base and you drop whatever you were carrying.

**The cast (all original):** Lele Terbang, Nasi Goreng Samurai, Es Teh Raksasa, Ayam Geprek DJ, Kapten Krupuk, Bakso Blaster, Raja Rendang, Hantu Indomie, Dewa Durian, Naga Sate, Sultan Lele Terbang, Maha Ratu Es Teh.

**Layout (Rojo, `default.project.json`):**
- `src/shared/` — `Catalog.luau` (cast, rarities, mutations), `Config.luau` (tuning), `Util.luau` (money formatting)
- `src/server/` — `Main.server.luau` (boot), `GameState.luau` (single source of truth), `World.luau` (bases, brainrot models, billboards), `Conveyor.luau` (spawning, belt, buying), `Economy.luau` (income tick), `Threat.luau` (tsunami wave, thief, carrying)
- `src/client/` — `Game.client.luau` (boot), `Hud.luau` (money bar, base list, rarity ladder, lock/rebirth buttons, toasts), `WorldClient.luau` (tsunami vignette)

**Build & verify:**

    rojo build -o game.rbxl
    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

`main.ts` (Node 22, standard library only) copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.

`PLAY.json` still names no place yet — fill it with your published place (place id + universe id) after publishing from Roblox Studio, and replace `screenshots/` with captures of the game running in Studio (the first by name is the cover and must match the thumbnail you upload for the game on Roblox).
