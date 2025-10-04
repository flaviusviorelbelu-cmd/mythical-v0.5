-- RemoteEventHandler.lua - CRASH-PROOF VERSION
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("[RemoteEventHandler] Starting RemoteEventHandler...")

-- Simple requires (like your Lunar)
local DataManager = require(script.Parent.DataManager)
local PlayerGardenManager = require(script.Parent.PlayerGardenManager)

-- SAFE WAITING for RemoteEvents (prevents crash)
local function waitForRemoteEvent(name, timeout)
	local timeWaited = 0
	local event = ReplicatedStorage:FindFirstChild(name)

	while not event and timeWaited < (timeout or 10) do
		wait(0.1)
		timeWaited = timeWaited + 0.1
		event = ReplicatedStorage:FindFirstChild(name)
	end

	if event then
		print("[RemoteEventHandler] ? Found:", name)
		return event
	else
		warn("[RemoteEventHandler] ? Failed to find:", name)
		return nil
	end
end

-- Wait for ALL RemoteEvents safely
local BuySeedEvent = waitForRemoteEvent("BuySeedEvent")
local PlantSeedEvent = waitForRemoteEvent("PlantSeedEvent")
local HarvestPlantEvent = waitForRemoteEvent("HarvestPlantEvent")
local SellPlantEvent = waitForRemoteEvent("SellPlantEvent")
local UpdatePlayerData = waitForRemoteEvent("UpdatePlayerData")
local ShowFeedback = waitForRemoteEvent("ShowFeedback")
local RequestInventoryUpdate = waitForRemoteEvent("RequestInventoryUpdate")

-- Wait for RemoteFunctions safely
local GetPlayerStats = waitForRemoteEvent("GetPlayerStats")

-- Simple seed prices (like your Lunar)
local seedPrices = {
	basic_seed = 25,
	stellar_seed = 50,
	cosmic_seed = 100
}

local cropPrices = {
	basic_crop = 10,
	stellar_crop = 20,
	cosmic_crop = 40
}

-- ONLY connect if event exists (prevents crash)
if BuySeedEvent then
	BuySeedEvent.OnServerEvent:Connect(function(player, seedType, amount)
		print("[RemoteEventHandler] BuySeedEvent:", player.Name, seedType, amount or 1)

		-- Default amount to 1 if not provided
		amount = amount or 1

		local price = seedPrices[seedType]
		if not price then
			print("[RemoteEventHandler] Invalid seed type:", seedType)
			if ShowFeedback then
				ShowFeedback:FireClient(player, "Invalid seed type", "error")
			end
			return
		end

		local totalCost = price * amount
		local data = DataManager.GetPlayerData(player)

		print("[RemoteEventHandler] Player has", data.coins, "coins, needs", totalCost)

		if data.coins < totalCost then
			print("[RemoteEventHandler] Not enough coins")
			if ShowFeedback then
				ShowFeedback:FireClient(player, "Not enough coins! Need " .. totalCost .. " coins", "error")
			end
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

		print("[RemoteEventHandler] ? Purchase successful! Player now has", data.seeds[seedType], seedType)

		-- Send updates
		if ShowFeedback then
			ShowFeedback:FireClient(player, "Bought " .. amount .. " " .. seedType .. " for " .. totalCost .. " coins!", "success")
		end

		if UpdatePlayerData then
			UpdatePlayerData:FireClient(player, data)
		end

		if RequestInventoryUpdate then
			RequestInventoryUpdate:FireClient(player)
		end
	end)
else
	warn("[RemoteEventHandler] ? BuySeedEvent not available - shop won't work!")
end

-- Connect PlantSeedEvent if available
if PlantSeedEvent then
	PlantSeedEvent.OnServerEvent:Connect(function(player, plotId, seedType)
		print("[RemoteEventHandler] PlantSeedEvent:", player.Name, plotId, seedType)

		local success, message = PlayerGardenManager.PlantSeed(player, plotId, seedType)

		if success then
			if ShowFeedback then
				ShowFeedback:FireClient(player, message, "success")
			end
			if UpdatePlayerData then
				UpdatePlayerData:FireClient(player, DataManager.GetPlayerData(player))
			end
		else
			if ShowFeedback then
				ShowFeedback:FireClient(player, message, "error")
			end
		end
	end)
end

-- Connect other events safely...
if HarvestPlantEvent then
	HarvestPlantEvent.OnServerEvent:Connect(function(player, plotId)
		print("[RemoteEventHandler] HarvestPlantEvent:", player.Name, plotId)

		local success, message = PlayerGardenManager.HarvestPlant(player, plotId)

		if success then
			if ShowFeedback then
				ShowFeedback:FireClient(player, message, "success")
			end
			if UpdatePlayerData then
				UpdatePlayerData:FireClient(player, DataManager.GetPlayerData(player))
			end
		else
			if ShowFeedback then
				ShowFeedback:FireClient(player, message, "error")
			end
		end
	end)
end

-- Setup GetPlayerStats function
if GetPlayerStats then
	GetPlayerStats.OnServerInvoke = function(player)
		return DataManager.GetPlayerData(player)
	end
end

-- Player setup (like your Lunar)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		wait(2) -- Let character load
		PlayerGardenManager.CreateGarden(player)
		if UpdatePlayerData then
			UpdatePlayerData:FireClient(player, DataManager.GetPlayerData(player))
		end
	end)
end)

print("[RemoteEventHandler] RemoteEventHandler loaded!")
