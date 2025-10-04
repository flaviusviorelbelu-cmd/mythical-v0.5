-- PlayerGardenManager.lua - Simple garden logic (like your Lunar)
local Players = game:GetService("Players")
local DataManager = require(script.Parent.DataManager)

local PlayerGardenManager = {}

-- Simple seed configs (like your Lunar)
local seedConfigs = {
	basic_seed = {
		growTime = 30,
		harvestValue = 15,
		cropType = "basic_crop"
	},
	stellar_seed = {
		growTime = 60,
		harvestValue = 35,
		cropType = "stellar_crop"
	},
	cosmic_seed = {
		growTime = 120,
		harvestValue = 75,
		cropType = "cosmic_crop"
	}
}

-- Create garden for player (simple)
function PlayerGardenManager.CreateGarden(player)
	local garden = workspace:FindFirstChild(player.Name .. "_Garden")
	if garden then
		garden:Destroy()
	end

	garden = Instance.new("Model")
	garden.Name = player.Name .. "_Garden"
	garden.Parent = workspace

	-- Create 9 plots (3x3)
	for i = 1, 9 do
		local plot = Instance.new("Part")
		plot.Name = "Plot_" .. i
		plot.Size = Vector3.new(6, 1, 6)
		plot.Material = Enum.Material.Grass
		plot.Color = Color3.fromRGB(101, 67, 33)
		plot.Anchored = true
		plot.CanCollide = true

		-- Position in grid
		local row = math.floor((i - 1) / 3)
		local col = (i - 1) % 3
		plot.Position = Vector3.new(col * 8, 0.5, row * 8)
		plot.Parent = garden

		-- Click detector
		local clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 20
		clickDetector.Parent = plot

		print("[PlayerGardenManager] Created plot", i, "for", player.Name)
	end

	print("[PlayerGardenManager] Garden created for:", player.Name)
	return garden
end

-- Simple plant function (like your Lunar)
function PlayerGardenManager.PlantSeed(player, plotId, seedType)
	local data = DataManager.GetPlayerData(player)

	-- Check if player has seed
	if not data.seeds[seedType] or data.seeds[seedType] <= 0 then
		return false, "You don't have any " .. seedType
	end

	-- Check if plot is available
	if data.plots[plotId] and data.plots[plotId].planted then
		return false, "Plot already has something planted"
	end

	-- Get seed config
	local config = seedConfigs[seedType]
	if not config then
		return false, "Invalid seed type"
	end

	-- Plant the seed
	data.seeds[seedType] = data.seeds[seedType] - 1
	data.plots[plotId] = {
		planted = true,
		seedType = seedType,
		plantTime = tick(),
		readyTime = tick() + config.growTime
	}

	-- Save data
	DataManager.SavePlayerData(player, data)

	-- Create visual plant
	PlayerGardenManager.CreatePlantVisual(player, plotId, seedType)

	print("[PlayerGardenManager] Planted", seedType, "in plot", plotId, "for", player.Name)
	return true, "Successfully planted " .. seedType
end

-- Simple visual creation (like your Lunar)
function PlayerGardenManager.CreatePlantVisual(player, plotId, seedType)
	local garden = workspace:FindFirstChild(player.Name .. "_Garden")
	if not garden then return end

	local plot = garden:FindFirstChild("Plot_" .. plotId)
	if not plot then return end

	-- Remove existing plant
	local existingPlant = plot:FindFirstChild("Plant")
	if existingPlant then
		existingPlant:Destroy()
	end

	-- Create new plant
	local plant = Instance.new("Part")
	plant.Name = "Plant"
	plant.Size = Vector3.new(2, 3, 2)
	plant.Shape = Enum.PartType.Cylinder
	plant.Material = Enum.Material.Leaf
	plant.Anchored = true
	plant.CanCollide = false
	plant.Position = plot.Position + Vector3.new(0, 2, 0)
	plant.Parent = plot

	-- Color by seed type
	if seedType == "basic_seed" then
		plant.Color = Color3.fromRGB(0, 255, 0)
	elseif seedType == "stellar_seed" then
		plant.Color = Color3.fromRGB(255, 255, 0)
	elseif seedType == "cosmic_seed" then
		plant.Color = Color3.fromRGB(128, 0, 255)
	end
end

-- Simple harvest (like your Lunar)
function PlayerGardenManager.HarvestPlant(player, plotId)
	local data = DataManager.GetPlayerData(player)
	local plotData = data.plots[plotId]

	if not plotData or not plotData.planted then
		return false, "Nothing planted in this plot"
	end

	if tick() < plotData.readyTime then
		return false, "Plant is not ready yet"
	end

	-- Get harvest value
	local config = seedConfigs[plotData.seedType]
	if not config then
		return false, "Invalid plant type"
	end

	-- Harvest
	data.harvested[config.cropType] = (data.harvested[config.cropType] or 0) + 1
	data.plots[plotId] = nil

	-- Remove visual
	local garden = workspace:FindFirstChild(player.Name .. "_Garden")
	if garden then
		local plot = garden:FindFirstChild("Plot_" .. plotId)
		if plot then
			local plant = plot:FindFirstChild("Plant")
			if plant then
				plant:Destroy()
			end
		end
	end

	DataManager.SavePlayerData(player, data)

	print("[PlayerGardenManager] Harvested from plot", plotId, "for", player.Name)
	return true, "Harvested " .. config.cropType
end

print("[PlayerGardenManager] PlayerGardenManager loaded!")
return PlayerGardenManager
