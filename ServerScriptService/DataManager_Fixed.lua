-- Fixed DataManager.lua - Adds missing InitializePlayer function
local DataManager = {}

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- DataStore
local playerDataStore = DataStoreService:GetDataStore("PlayerData_Mythical_v3")

-- Player data cache
local playerDataCache = {}

-- FIXED: Consistent player data structure
local defaultPlayerData = {
	coins = 500,
	gems = 50,
	level = 1,
	experience = 0,
	seeds = {
		basic_seed = 10,
		stellar_seed = 0,
		cosmic_seed = 0
	},
	harvested = {
		basic_crop = 0,
		stellar_crop = 0,
		cosmic_crop = 0
	},
	plots = {}, -- For tracking planted crops
	lastLogin = 0
}

-- Deep copy function
local function deepCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

-- FIXED: Add the missing InitializePlayer function
function DataManager.InitializePlayer(player)
	print("[DataManager] Initializing player:", player.Name)
	
	local success, savedData = pcall(function()
		return playerDataStore:GetAsync(player.UserId)
	end)

	local playerData
	if success and savedData then
		-- Merge with defaults to ensure all fields exist
		playerData = deepCopy(defaultPlayerData)
		
		-- Copy saved data over defaults
		for key, value in pairs(savedData) do
			if type(value) == "table" and type(playerData[key]) == "table" then
				for subKey, subValue in pairs(value) do
					playerData[key][subKey] = subValue
				end
			else
				playerData[key] = value
			end
		end
		
		print("[DataManager] Loaded existing data for:", player.Name)
	else
		playerData = deepCopy(defaultPlayerData)
		print("[DataManager] Created new data for:", player.Name)
	end

	-- Ensure all required tables exist
	if not playerData.seeds then playerData.seeds = deepCopy(defaultPlayerData.seeds) end
	if not playerData.harvested then playerData.harvested = deepCopy(defaultPlayerData.harvested) end
	if not playerData.plots then playerData.plots = {} end

	playerData.lastLogin = os.time()
	
	-- Cache the data
	playerDataCache[player.UserId] = playerData
	
	-- Save initial data
	DataManager.SavePlayerData(player, playerData)
	
	return playerData
end

-- Get player data
function DataManager.GetPlayerData(player)
	local data = playerDataCache[player.UserId]
	if not data then
		print("[DataManager] No cached data found for", player.Name, "- initializing")
		return DataManager.InitializePlayer(player)
	end
	return data
end

-- Save player data
function DataManager.SavePlayerData(player, data)
	if not data then
		data = playerDataCache[player.UserId]
	end

	if not data then
		warn("[DataManager] No data to save for", player.Name)
		return false
	end

	-- Update cache
	playerDataCache[player.UserId] = data

	-- Save to DataStore
	local success, errorMessage = pcall(function()
		playerDataStore:SetAsync(player.UserId, data)
	end)

	if success then
		print("[DataManager] Saved data for", player.Name)
		return true
	else
		warn("[DataManager] Failed to save data for", player.Name, ":", errorMessage)
		return false
	end
end

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	local playerData = playerDataCache[player.UserId]
	if playerData then
		local success = pcall(function()
			playerDataStore:SetAsync(player.UserId, playerData)
		end)
		
		if success then
			print("[DataManager] Final save completed for", player.Name)
		else
			warn("[DataManager] Final save failed for", player.Name)
		end
		
		playerDataCache[player.UserId] = nil
	end
end)

-- Periodic autosave
spawn(function()
	while true do
		wait(300) -- 5 minutes
		for userId, data in pairs(playerDataCache) do
			local player = Players:GetPlayerByUserId(userId)
			if player then
				DataManager.SavePlayerData(player, data)
			end
		end
	end
end)

print("[DataManager] DataManager loaded!")

return DataManager