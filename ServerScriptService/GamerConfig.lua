-- Game Configurations (ModuleScript in ReplicatedStorage)
local GameConfig = {}

-- Seed Configuration
GameConfig.Seeds = {
	basic_seed = {
		name = "Magic Wheat",
		cost = 10,
		growTime = 30, -- seconds
		coinReward = 15,
		expReward = 5,
		unlockLevel = 1,
		tier = "basic"
	},
	stellar_seed = {
		name = "Stellar Corn",
		cost = 50,
		growTime = 120,
		coinReward = 80,
		expReward = 15,
		unlockLevel = 5,
		tier = "stellar"
	},
	cosmic_seed = {
		name = "Cosmic Berries",
		cost = 200,
		growTime = 300,
		coinReward = 350,
		expReward = 35,
		unlockLevel = 15,
		tier = "cosmic"
	},
	divine_seed = {
		name = "Divine Crystals",
		cost = 1000,
		growTime = 600,
		coinReward = 1800,
		expReward = 100,
		unlockLevel = 30,
		tier = "divine"
	}
}


return GameConfig
