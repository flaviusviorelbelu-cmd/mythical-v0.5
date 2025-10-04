-- Fixed RemoteEventHandler.lua for mythical-v0.5
-- Fixes garden integration and data synchronization issues

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

print("[RemoteEventHandler] Starting FIXED RemoteEventHandler...")

-- Safe requires (prevent crashes)
local DataManager = require(script.Parent.DataManager)
local PlayerGardenManager = require(script.Parent.PlayerGardenManager)
local GardenSystem = require(script.Parent.GardenSystem)

-- SAFE remote event loading (prevents crashes)
local function waitForRemoteEvent(name, timeout)
	local timeWaited = 0
	local event = ReplicatedStorage:FindFirstChild(name)

	while not event and timeWaited < (timeout or 15) do
		wait(0.1)
		timeWaited = timeWaited + 0.1
		event = ReplicatedStorage:FindFirstChild(name)
	end

	if event then
		print("[RemoteEventHandler] ✓ Found:", name)
		return event
	else
		warn("[RemoteEventHandler] ❌ Failed to find:", name)
		return nil
	end
end

-- SAFE creation of missing remote events
local function createRemoteEvent(name)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then
		return existing
	end

	local newEvent = Instance.new("RemoteEvent")
	newEvent.Name = name
	newEvent.Parent = ReplicatedStorage
	print("[RemoteEventHandler] ➕ Created missing RemoteEvent:", name)
	return newEvent
end

local function createRemoteFunction(name)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then
		return existing
	end

	local newFunc = Instance.new("RemoteFunction")
	newFunc.Name = name
	newFunc.Parent = ReplicatedStorage
	print("[RemoteEventHandler] ➕ Created missing RemoteFunction:", name)
	return newFunc
end

-- Load or create all required remote objects
local BuySeedEvent = waitForRemoteEvent("BuySeedEvent") or createRemoteEvent("BuySeedEvent")
local PlantSeedEvent = waitForRemoteEvent("PlantSeedEvent") or createRemoteEvent("PlantSeedEvent")
local HarvestPlantEvent = waitForRemoteEvent("HarvestPlantEvent") or createRemoteEvent("HarvestPlantEvent")
local SellPlantEvent = waitForRemoteEvent("SellPlantEvent") or createRemoteEvent("SellPlantEvent")
local UpdatePlayerData = waitForRemoteEvent("UpdatePlayerData") or createRemoteEvent("UpdatePlayerData")
local ShowFeedback = waitForRemoteEvent("ShowFeedback") or createRemoteEvent("ShowFeedback")
local RequestInventoryUpdate = waitForRemoteEvent("RequestInventoryUpdate") or createRemoteEvent("RequestInventoryUpdate")

local GetPlayerStats = waitForRemoteEvent("GetPlayerStats") or createRemoteFunction("GetPlayerStats")

-- Enhanced seed and crop configurations (matching your game design)
local seedPrices = {
	basic_seed = 25,
	stellar_seed = 50,
	cosmic_seed = 100
}

local cropPrices = {
	basic_crop = 15,
	stellar_crop = 30,
	cosmic_crop = 60
}

local seedToCropMap = {
	basic_seed = "basic_crop",
	stellar_seed = "stellar_crop",
	cosmic_seed = "cosmic_crop"
}

local growthTimes = {
	basic_seed = 30,   -- 30 seconds
	stellar_seed = 45, -- 45 seconds
	cosmic_seed = 60   -- 60 seconds
}

-- Helper function to send feedback to client
local function sendFeedback(player, message, messageType)
	if ShowFeedback then
		ShowFeedback:FireClient(player, message, messageType or "info")
	end
end

-- Helper function to update client data
local function updateClientData(player)
	if UpdatePlayerData then
		local data = DataManager.GetPlayerData(player)
		UpdatePlayerData:FireClient(player, data)
	end
	if RequestInventoryUpdate then
		RequestInventoryUpdate:FireClient(player)
	end
end

-- FIXED: BuySeedEvent handler
if BuySeedEvent then
	BuySeedEvent.OnServerEvent:Connect(function(player, seedType, amount)
		print("[RemoteEventHandler] 🛍️ BuySeedEvent:", player.Name, seedType, amount or 1)

		amount = amount or 1
		local price = seedPrices[seedType]

		if not price then
			print("[RemoteEventHandler] ❌ Invalid seed type:", seedType)
			sendFeedback(player, "Invalid seed type", "error")
			return
		end

		local totalCost = price * amount
		local data = DataManager.GetPlayerData(player)

		if not data then
			warn("[RemoteEventHandler] ❌ No data found for player:", player.Name)
			return
		end

		print("[RemoteEventHandler] 🪙 Player has", data.coins, "coins, needs", totalCost)

		if data.coins < totalCost then
			print("[RemoteEventHandler] 🚫 Not enough coins")
			sendFeedback(player, "Not enough coins! Need " .. totalCost .. " coins", "error")
			return
		end

		-- Deduct coins and add seeds
		data.coins = data.coins - totalCost

		-- Ensure seeds table exists
		if not data.seeds then
			data.seeds = {}
		end

		data.seeds[seedType] = (data.seeds[seedType] or 0) + amount

		-- Save data
		DataManager.SavePlayerData(player, data)

		print("[RemoteEventHandler] ✅ Purchase successful! Player now has", data.seeds[seedType], seedType)

		-- Send updates
		sendFeedback(player, "Bought " .. amount .. " " .. seedType:gsub("_", " ") .. " for " .. totalCost .. " coins! 🌱", "success")
		updateClientData(player)
	end)
else
	warn("[RemoteEventHandler] ⚠️ BuySeedEvent not available - shop won't work!")
end

-- FIXED: PlantSeedEvent handler with garden integration
if PlantSeedEvent then
	PlantSeedEvent.OnServerEvent:Connect(function(player, plotId, seedType)
		print("[RemoteEventHandler] 🌱 PlantSeedEvent:", player.Name, "plot", plotId, "seed", seedType)

		if not plotId or not seedType then
			warn("[RemoteEventHandler] ❌ Invalid planting parameters")
			sendFeedback(player, "Invalid planting parameters", "error")
			return
		end

		local data = DataManager.GetPlayerData(player)
		if not data then
			warn("[RemoteEventHandler] ❌ No data found for player:", player.Name)
			return
		end

		-- Check if player has the seed
		if not data.seeds or not data.seeds[seedType] or data.seeds[seedType] <= 0 then
			print("[RemoteEventHandler] 🚫 Player doesn't have", seedType)
			sendFeedback(player, "You don't have any " .. seedType:gsub("_", " ") .. "!", "error")
			return
		end

		-- Check if plot is empty
		if not data.plots then
			data.plots = {}
		end

		local plotKey = tostring(plotId)
		if data.plots[plotKey] then
			print("[RemoteEventHandler] 🚫 Plot already occupied")
			sendFeedback(player, "Plot " .. plotId .. " is already occupied!", "error")
			return
		end

		-- Plant the seed
		data.seeds[seedType] = data.seeds[seedType] - 1
		data.plots[plotKey] = {
			seedType = seedType,
			plantedAt = os.time(),
			growthTime = growthTimes[seedType] or 30,
			isReady = false
		}

		-- Save data
		DataManager.SavePlayerData(player, data)

		print("[RemoteEventHandler] ✅ Planted", seedType, "on plot", plotId)
		sendFeedback(player, "Planted " .. seedType:gsub("_", " ") .. " on plot " .. plotId .. "! 🌱", "success")

		-- Update client
		updateClientData(player)

		-- Start growth timer
		spawn(function()
			wait(data.plots[plotKey].growthTime)
			
			-- Check if plot still exists and has same plant
			local currentData = DataManager.GetPlayerData(player)
			if currentData and currentData.plots and currentData.plots[plotKey] and 
			   currentData.plots[plotKey].seedType == seedType then
				
				currentData.plots[plotKey].isReady = true
				DataManager.SavePlayerData(player, currentData)
				
				print("[RemoteEventHandler] 🌾 Plant ready on plot", plotId)
				sendFeedback(player, "Your " .. seedType:gsub("_", " ") .. " on plot " .. plotId .. " is ready to harvest! 🌾", "success")
				updateClientData(player)
			end
		end)
	end)
else
	warn("[RemoteEventHandler] ⚠️ PlantSeedEvent not available!")
end

-- FIXED: HarvestPlantEvent handler
if HarvestPlantEvent then
	HarvestPlantEvent.OnServerEvent:Connect(function(player, plotId)
		print("[RemoteEventHandler] 🌾 HarvestPlantEvent:", player.Name, "plot", plotId)

		local data = DataManager.GetPlayerData(player)
		if not data then
			warn("[RemoteEventHandler] ❌ No data found for player:", player.Name)
			return
		end

		local plotKey = tostring(plotId)
		if not data.plots or not data.plots[plotKey] then
			print("[RemoteEventHandler] 🚫 No plant on plot", plotId)
			sendFeedback(player, "No plant on plot " .. plotId .. "!", "error")
			return
		end

		local plot = data.plots[plotKey]
		if not plot.isReady then
			local timeLeft = (plot.plantedAt + plot.growthTime) - os.time()
			print("[RemoteEventHandler] ⏰ Plant not ready, time left:", math.max(0, timeLeft), "seconds")
			sendFeedback(player, "Plant needs " .. math.max(0, math.ceil(timeLeft)) .. " more seconds to grow!", "warning")
			return
		end

		-- Harvest the crop
		local cropType = seedToCropMap[plot.seedType] or "basic_crop"
		local harvestAmount = math.random(1, 3) -- Random harvest yield

		-- Add to harvested inventory
		if not data.harvested then
			data.harvested = {}
		end
		data.harvested[cropType] = (data.harvested[cropType] or 0) + harvestAmount

		-- Clear the plot
		data.plots[plotKey] = nil

		-- Save data
		DataManager.SavePlayerData(player, data)

		print("[RemoteEventHandler] ✅ Harvested", harvestAmount, cropType, "from plot", plotId)
		sendFeedback(player, "Harvested " .. harvestAmount .. " " .. cropType:gsub("_", " ") .. "! 🌾", "success")

		-- Update client
		updateClientData(player)
	end)
else
	warn("[RemoteEventHandler] ⚠️ HarvestPlantEvent not available!")
end

-- FIXED: SellPlantEvent handler
if SellPlantEvent then
	SellPlantEvent.OnServerEvent:Connect(function(player, cropType, amount)
		print("[RemoteEventHandler] 💰 SellPlantEvent:", player.Name, cropType, amount)

		local data = DataManager.GetPlayerData(player)
		if not data then
			warn("[RemoteEventHandler] ❌ No data found for player:", player.Name)
			return
		end

		local price = cropPrices[cropType]
		if not price then
			print("[RemoteEventHandler] ❌ Invalid crop type:", cropType)
			sendFeedback(player, "Invalid crop type", "error")
			return
		end

		if not data.harvested or not data.harvested[cropType] or data.harvested[cropType] < amount then
			print("[RemoteEventHandler] 🚫 Not enough", cropType, "to sell")
			sendFeedback(player, "You don't have enough " .. cropType:gsub("_", " ") .. " to sell!", "error")
			return
		end

		-- Sell the crops
		local totalValue = price * amount
		data.harvested[cropType] = data.harvested[cropType] - amount
		data.coins = (data.coins or 0) + totalValue

		-- Save data
		DataManager.SavePlayerData(player, data)

		print("[RemoteEventHandler] ✅ Sold", amount, cropType, "for", totalValue, "coins")
		sendFeedback(player, "Sold " .. amount .. " " .. cropType:gsub("_", " ") .. " for " .. totalValue .. " coins! 💰", "success")

		-- Update client
		updateClientData(player)
	end)
else
	warn("[RemoteEventHandler] ⚠️ SellPlantEvent not available!")
end

-- FIXED: GetPlayerStats function
if GetPlayerStats then
	GetPlayerStats.OnServerInvoke = function(player)
		print("[RemoteEventHandler] 📊 GetPlayerStats request from:", player.Name)
		local data = DataManager.GetPlayerData(player)
		if data then
			print("[RemoteEventHandler] ✅ Returning data - Coins:", data.coins, "Seeds:", data.seeds and #data.seeds or 0)
			return data
		else
			warn("[RemoteEventHandler] ❌ No data available for:", player.Name)
			return {coins = 0, gems = 0, level = 1, seeds = {}, harvested = {}}
		end
	end
else
	warn("[RemoteEventHandler] ⚠️ GetPlayerStats not available!")
end

-- FIXED: Player setup with proper garden integration
Players.PlayerAdded:Connect(function(player)
	print("[RemoteEventHandler] 🚀 Player joined:", player.Name)

	-- Initialize player data first
	DataManager.InitializePlayer(player)

	player.CharacterAdded:Connect(function()
		print("[RemoteEventHandler] 🚶 Character spawned for:", player.Name)
		wait(2) -- Let character load

		-- FIXED: Create garden using GardenSystem
		if GardenSystem and GardenSystem.InitializePlayerGarden then
			GardenSystem.InitializePlayerGarden(player)
			print("[RemoteEventHandler] 🌱 Garden created for:", player.Name)
		else
			-- Fallback to PlayerGardenManager
			if PlayerGardenManager and PlayerGardenManager.CreateGarden then
				PlayerGardenManager.CreateGarden(player)
				print("[RemoteEventHandler] 🌱 Fallback garden created for:", player.Name)
			end
		end

		-- Send initial data to client
		updateClientData(player)
		sendFeedback(player, "Welcome to Mythical Realm, " .. player.Name .. "! 🌟", "success")
	end)
end)

-- Handle player leaving (cleanup)
Players.PlayerRemoving:Connect(function(player)
	print("[RemoteEventHandler] 👋 Player leaving:", player.Name)
	-- DataManager handles final save automatically
end)

-- Periodic plot status checker (updates ready plants)
spawn(function()
	while true do
		wait(10) -- Check every 10 seconds
		
		for _, player in pairs(Players:GetPlayers()) do
			local data = DataManager.GetPlayerData(player)
			if data and data.plots then
				local updated = false
				
				for plotId, plot in pairs(data.plots) do
					if not plot.isReady then
						local timeElapsed = os.time() - plot.plantedAt
						if timeElapsed >= plot.growthTime then
							plot.isReady = true
							updated = true
							print("[RemoteEventHandler] 🌾 Plot", plotId, "ready for", player.Name)
						end
					end
				end
				
				if updated then
					DataManager.SavePlayerData(player, data)
					updateClientData(player)
				end
			end
		end
	end
end)

print("[RemoteEventHandler] ✅ FIXED RemoteEventHandler loaded successfully!")