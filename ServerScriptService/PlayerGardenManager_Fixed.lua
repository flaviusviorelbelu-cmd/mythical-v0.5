-- Fixed PlayerGardenManager.lua - Creates individual gardens for each player
local PlayerGardenManager = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Store player gardens
local playerGardens = {}

-- Garden configuration
local PLOT_SIZE = Vector3.new(4, 0.2, 4)
local PLOTS_PER_PLAYER = 9
local PLOT_SPACING = 6

-- FIXED: Create individual garden for each player
function PlayerGardenManager.CreateGarden(player)
	local userId = player.UserId
	local playerName = player.Name
	
	print("[PlayerGardenManager] Creating garden for:", playerName)

	-- FIXED: Use consistent naming that matches client expectations
	local gardenModel = Instance.new("Model")
	gardenModel.Name = playerName .. "_Garden"  -- This matches PlotClickHandler search
	gardenModel.Parent = Workspace

	-- Position gardens in a circle around spawn
	local angle = math.rad((userId % 12) * 30)
	local radius = 100
	local gardenCenter = Vector3.new(
		math.cos(angle) * radius,
		5, -- Above ground
		math.sin(angle) * radius
	)

	-- Create 9 plots in 3x3 grid
	local plots = {}
	for row = 1, 3 do
		for col = 1, 3 do
			local plotIndex = (row - 1) * 3 + col
			local plot = PlayerGardenManager.CreatePlot(player, plotIndex, gardenCenter, row, col, gardenModel)
			plots[plotIndex] = plot
		end
	end

	-- Create garden nameplate
	PlayerGardenManager.CreateNameplate(player, gardenCenter, gardenModel)

	-- Store garden reference
	playerGardens[userId] = {
		model = gardenModel,
		center = gardenCenter,
		plots = plots
	}

	print("[PlayerGardenManager] ✅ Garden created for:", playerName, "at", gardenCenter)
	return gardenModel
end

-- Create individual plot
function PlayerGardenManager.CreatePlot(player, plotIndex, centerPos, row, col, parentModel)
	local offsetX = (col - 2) * PLOT_SPACING  -- -6, 0, 6
	local offsetZ = (row - 2) * PLOT_SPACING  -- -6, 0, 6
	local plotPos = centerPos + Vector3.new(offsetX, 0, offsetZ)

	-- FIXED: Consistent plot naming that matches client search patterns
	local plotBase = Instance.new("Part")
	plotBase.Name = "Plot_" .. plotIndex  -- This matches PlotClickHandler search
	plotBase.Size = PLOT_SIZE
	plotBase.Position = plotPos
	plotBase.Anchored = true
	plotBase.Material = Enum.Material.Ground
	plotBase.Color = Color3.fromRGB(101, 67, 33)  -- Brown soil
	plotBase.Parent = parentModel

	-- Create plot border
	local border = Instance.new("Part")
	border.Name = "PlotBorder"
	border.Size = Vector3.new(PLOT_SIZE.X + 0.5, 0.5, PLOT_SIZE.Z + 0.5)
	border.Position = plotPos + Vector3.new(0, 0.5, 0)
	border.Anchored = true
	border.Material = Enum.Material.Wood
	border.Color = Color3.fromRGB(139, 69, 19)  -- Dark wood
	border.CanCollide = false
	border.Transparency = 0.3
	border.Parent = plotBase

	-- Create status indicator
	local indicator = Instance.new("Part")
	indicator.Name = "StatusIndicator"
	indicator.Size = Vector3.new(0.8, 0.1, 0.8)
	indicator.Position = plotPos + Vector3.new(0, 0.6, 0)
	indicator.Anchored = true
	indicator.Material = Enum.Material.Neon
	indicator.Color = Color3.fromRGB(0, 255, 0)  -- Green = ready to plant
	indicator.Shape = Enum.PartType.Cylinder
	indicator.Parent = plotBase

	-- Add surface GUI for plot info
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "PlotInfo"
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.Parent = plotBase

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "PlotLabel"
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "Plot " .. plotIndex .. "\nEmpty\n🖱️ Click to plant"
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.Parent = surfaceGui

	-- FIXED: Create click detector for plot interaction
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.Name = "PlotClickDetector"
	clickDetector.MaxActivationDistance = 50
	clickDetector.Parent = plotBase

	-- Store plot data
	local plotData = {
		part = plotBase,
		indicator = indicator,
		clickDetector = clickDetector,
		surfaceGui = surfaceGui,
		textLabel = textLabel,
		owner = player,
		plotIndex = plotIndex,
		seedType = nil,
		plantTime = nil,
		isReady = false
	}

	print("[PlayerGardenManager] ✅ Created plot", plotIndex, "for", player.Name)
	return plotData
end

-- Create floating nameplate
function PlayerGardenManager.CreateNameplate(player, centerPos, parentModel)
	local nameplate = Instance.new("Part")
	nameplate.Name = player.Name .. "_Nameplate"
	nameplate.Size = Vector3.new(12, 1, 4)
	nameplate.Position = centerPos + Vector3.new(0, 15, 0)
	nameplate.Anchored = true
	nameplate.CanCollide = false
	nameplate.Transparency = 1
	nameplate.Parent = parentModel

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Parent = nameplate

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = player.Name .. "'s Mythical Garden 🌟"
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.Fantasy
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.fromRGB(100, 200, 255)
	textLabel.Parent = surfaceGui

end

-- Get player's garden
function PlayerGardenManager.GetPlayerGarden(player)
	return playerGardens[player.UserId]
end

-- FIXED: Plant seed function with proper data handling
function PlayerGardenManager.PlantSeed(player, plotId, seedType)
	local garden = playerGardens[player.UserId]
	if not garden or not garden.plots[plotId] then
		return false, "Plot not found"
	end

	local plot = garden.plots[plotId]
	if plot.seedType then
		return false, "Plot already occupied"
	end

	-- Update plot data
	plot.seedType = seedType
	plot.plantTime = os.time()
	plot.isReady = false

	-- Update visual
	plot.textLabel.Text = "Plot " .. plotId .. "\n🌱 " .. seedType:upper():gsub("_", " ") .. "\n⏳ Growing..."
	plot.indicator.Color = Color3.fromRGB(255, 255, 0)  -- Yellow = growing

	print("[PlayerGardenManager] ✅ Planted", seedType, "on plot", plotId, "for", player.Name)
	return true, "Seed planted successfully!"
end

-- FIXED: Harvest plant function
function PlayerGardenManager.HarvestPlant(player, plotId)
	local garden = playerGardens[player.UserId]
	if not garden or not garden.plots[plotId] then
		return false, "Plot not found"
	end

	local plot = garden.plots[plotId]
	if not plot.seedType then
		return false, "No plant on this plot"
	end

	if not plot.isReady then
		return false, "Plant is still growing"
	end

	local cropType = plot.seedType:gsub("seed", "crop")  -- Convert seed to crop
	local harvestAmount = math.random(1, 3)

	-- Clear plot
	plot.seedType = nil
	plot.plantTime = nil
	plot.isReady = false

	-- Reset visual
	plot.textLabel.Text = "Plot " .. plotId .. "\nEmpty\n🖱️ Click to plant"
	plot.indicator.Color = Color3.fromRGB(0, 255, 0)  -- Green = ready to plant

	print("[PlayerGardenManager] ✅ Harvested", harvestAmount, cropType, "from plot", plotId, "for", player.Name)
	return true, "Harvested " .. harvestAmount .. " " .. cropType:gsub("_", " ") .. "!", cropType, harvestAmount
end

-- Update plot status (called periodically)
function PlayerGardenManager.UpdatePlotStatus(player, plotId, isReady)
	local garden = playerGardens[player.UserId]
	if not garden or not garden.plots[plotId] then
		return
	end

	local plot = garden.plots[plotId]
	if not plot.seedType then
		return
	end

	plot.isReady = isReady

	if isReady then
		-- Update visual to show ready
		plot.textLabel.Text = "Plot " .. plotId .. "\n🌾 " .. plot.seedType:upper():gsub("_", " ") .. "\n✅ READY TO HARVEST!"
		plot.indicator.Color = Color3.fromRGB(0, 255, 0)  -- Bright green = ready
		plot.indicator.Material = Enum.Material.ForceField  -- Glowing effect
	else
		-- Still growing
		plot.textLabel.Text = "Plot " .. plotId .. "\n🌱 " .. plot.seedType:upper():gsub("_", " ") .. "\n⏳ Growing..."
		plot.indicator.Color = Color3.fromRGB(255, 255, 0)  -- Yellow = growing
		plot.indicator.Material = Enum.Material.Neon
	end
end

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	local garden = playerGardens[player.UserId]
	if garden and garden.model then
		garden.model:Destroy()
		playerGardens[player.UserId] = nil
		print("[PlayerGardenManager] 🗑️ Cleaned up garden for:", player.Name)
	end
end)

print("[PlayerGardenManager] PlayerGardenManager loaded!")

return PlayerGardenManager