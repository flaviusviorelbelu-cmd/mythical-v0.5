-- DataManager.lua - Simple like your Lunar (no over-engineering)
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local DataManager = {}

-- Simple DataStore (like your Lunar)
local playerDataStore = DataStoreService:GetDataStore("MythicalPlayerData")

-- Simple default data (like your Lunar)
local defaultPlayerData = {
	coins = 1000,  -- NEW: 1000 coins instead of 500
	gems = 50,
	seeds = {
		basic_seed = 10,
		stellar_seed = 5,
		cosmic_seed = 2
	},
	harvested = {
		basic_crop = 0,
		stellar_crop = 0,
		cosmic_crop = 0
	},
	plots = {},
	dataVersion = 2  -- NEW: Add version to force migration
}

-- Player data cache (simple)
local playerData = {}

-- Update the LoadPlayerData function
function DataManager.LoadPlayerData(player)
	local success, data = pcall(function()
		return playerDataStore:GetAsync(player.UserId)
	end)

	if success and data and data.dataVersion == 2 then
		print("[DataManager] Loaded existing v2 data for:", player.Name)
		playerData[player.UserId] = data
		return data
	else
		print("[DataManager] Creating NEW v2 data for:", player.Name, "(old version or new player)")
		local newData = {}
		for key, value in pairs(defaultPlayerData) do
			if type(value) == "table" then
				newData[key] = {}
				for k, v in pairs(value) do
					newData[key][k] = v
				end
			else
				newData[key] = value
			end
		end
		playerData[player.UserId] = newData
		-- Save immediately to update old data
		DataManager.SavePlayerData(player, newData)
		return newData
	end
end

-- Simple get (like your Lunar)
function DataManager.GetPlayerData(player)
	if not playerData[player.UserId] then
		return DataManager.LoadPlayerData(player)
	end
	return playerData[player.UserId]
end

-- Simple save (like your Lunar)
function DataManager.SavePlayerData(player, data)
	if not data then
		data = playerData[player.UserId]
	end

	if data then
		playerData[player.UserId] = data
		spawn(function()
			pcall(function()
				playerDataStore:SetAsync(player.UserId, data)
				print("[DataManager] Saved data for:", player.Name)
			end)
		end)
	end
end

-- Simple coin functions (like your Lunar)
function DataManager.AddCoins(player, amount)
	local data = DataManager.GetPlayerData(player)
	data.coins = data.coins + amount
	DataManager.SavePlayerData(player, data)
end

function DataManager.SpendCoins(player, amount)
	local data = DataManager.GetPlayerData(player)
	if data.coins >= amount then
		data.coins = data.coins - amount
		DataManager.SavePlayerData(player, data)
		return true
	end
	return false
end

-- Auto-save and cleanup (like your Lunar)
Players.PlayerRemoving:Connect(function(player)
	if playerData[player.UserId] then
		DataManager.SavePlayerData(player)
		playerData[player.UserId] = nil
		print("[DataManager] Cleaned up data for:", player.Name)
	end
end)

print("[DataManager] DataManager loaded!")
return DataManager
