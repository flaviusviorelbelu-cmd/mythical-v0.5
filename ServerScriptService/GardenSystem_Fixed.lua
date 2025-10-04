-- Fixed GardenSystem.lua for mythical-v0.5
-- Fixes plot interaction and garden naming issues

local GardenSystem = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local DEBUG_MODE = true

-- Debug logger
local function debugLog(msg, lvl)
	if DEBUG_MODE then
		print("[GardenSystem][" .. (lvl or "INFO") .. "] " .. msg)
	end
end

-- Plot configuration
local PLOT_SIZE = Vector3.new(3.5, 0.2, 3.5)
local PLOTS_PER_PLAYER = 9
local PLOT_SPACING = 5

-- Store player plots and gardens
local playerPlots = {}
local playerGardens = {}

-- Enhanced fence creation
function GardenSystem.AddFence(centerPos, parentModel)
	local length = PLOT_SPACING * 7
	local thickness = 0.4
	local height = 2
	local y = centerPos.Y + height / 2

	local fenceOffsets = {
		{Vector3.new(0, 0, length/2), Vector3.new(length, height, thickness)},
		{Vector3.new(0, 0, -length/2), Vector3.new(length, height, thickness)},
		{Vector3.new(length/2, 0, 0), Vector3.new(thickness, height, length)},
		{Vector3.new(-length/2, 0, 0), Vector3.new(thickness, height, length)},
	}
	
	for _, offset in ipairs(fenceOffsets) do
		local fence = Instance.new("Part")
		fence.Name = "Fence"
		fence.Size = offset[2]
		fence.Position = centerPos + offset[1] + Vector3.new(0, height/2, 0)
		fence.Anchored = true
		fence.Material = Enum.Material.Wood
		fence.BrickColor = BrickColor.new("Burgundy")
		fence.Parent = parentModel
	end
end

-- Enhanced chest creation with interaction
function GardenSystem.AddChest(centerPos, parentModel)
	local chest = Instance.new("Part")
	chest.Name = "Chest"
	chest.Size = Vector3.new(2.2, 1.6, 1.2)
	chest.Position = centerPos + Vector3.new(-(PLOT_SPACING * 2), 1, 0)
	chest.Anchored = true
	chest.Material = Enum.Material.Wood
	chest.BrickColor = BrickColor.new("Dark orange")
	chest.Shape = Enum.PartType.Block
	chest.Parent = parentModel

	-- Add metal reinforcements
	local function addMetalBand(offset, size)
		local band = Instance.new("Part")
		band.Name = "MetalBand"
		band.Size = size
		band.Position = chest.Position + offset
		band.Anchored = true
		band.Material = Enum.Material.Metal
		band.BrickColor = BrickColor.new("Really black")
		band.Parent = chest

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = chest
		weld.Part1 = band
		weld.Parent = chest
		return band
	end

	-- Add bands and decorative elements
	addMetalBand(Vector3.new(0, 0.6, 0), Vector3.new(2.4, 0.1, 1.4))
	addMetalBand(Vector3.new(0, -0.6, 0), Vector3.new(2.4, 0.1, 1.4))

	-- Create chest lid
	local lid = Instance.new("Part")
	lid.Name = "ChestLid"
	lid.Size = Vector3.new(2.2, 0.2, 1.2)
	lid.Position = chest.Position + Vector3.new(0, 0.9, 0)
	lid.Anchored = true
	lid.Material = Enum.Material.Wood
	lid.BrickColor = BrickColor.new("Dark orange")
	lid.Parent = chest

	-- Add magical glow effect
	local light = Instance.new("PointLight")
	light.Name = "ChestGlow"
	light.Brightness = 0.5
	light.Color = Color3.new(1, 0.8, 0.4)
	light.Range = 8
	light.Parent = chest

	-- Add click detector for future chest interaction
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.Name = "ChestInteraction"
	clickDetector.MaxActivationDistance = 10
	clickDetector.Parent = chest

	return chest
end

-- FIXED: Enhanced garden initialization with consistent naming
function GardenSystem.InitializePlayerGarden(player)
	local userId = player.UserId
	local playerName = player.Name
	
	playerPlots[userId] = {}

	-- FIXED: Consistent garden naming (matches client expectations)
	local gardenModel = Instance.new("Model")
	gardenModel.Name = playerName .. "_Garden" -- This matches the client search
	gardenModel.Parent = workspace

	-- Store garden reference
	playerGardens[userId] = gardenModel

	local gardenCenter = GardenSystem.GetPlayerGardenPosition(userId)
	debugLog("Creating garden for " .. playerName .. " at position " .. tostring(gardenCenter))

	-- Create 9 plots in 3x3 grid with FIXED naming
	for row = 1, 3 do
		for col = 1, 3 do
			local plotIndex = (row - 1) * 3 + col
			local plot = GardenSystem.CreatePlot(player, plotIndex, gardenCenter, row, col, gardenModel)
			playerPlots[userId][plotIndex] = plot
		end
	end

	-- Add chest and fence
	GardenSystem.AddChest(gardenCenter, gardenModel)
	GardenSystem.AddFence(gardenCenter, gardenModel)
	GardenSystem.CreatePlayerNameplate(player, gardenCenter, gardenModel)

	debugLog("Garden created successfully for " .. playerName, "SUCCESS")
	return gardenModel
end

-- Garden positioning system
function GardenSystem.GetPlayerGardenPosition(userId)
	local angle = math.rad((userId % 12) * 30)
	local radius = 120
	return Vector3.new(
		math.cos(angle) * radius,
		6,
		math.sin(angle) * radius
	)
end

-- FIXED: Enhanced plot creation with proper click handling
function GardenSystem.CreatePlot(player, plotIndex, centerPos, row, col, parentModel)
	local offsetX = (col - 2) * PLOT_SPACING
	local offsetZ = (row - 2) * PLOT_SPACING
	local plotPos = centerPos + Vector3.new(offsetX, 0, offsetZ)

	-- FIXED: Consistent plot naming (matches client expectations)
	local plotBase = Instance.new("Part")
	plotBase.Name = "Plot_" .. plotIndex -- This matches client search patterns
	plotBase.Size = PLOT_SIZE
	plotBase.Position = plotPos
	plotBase.Anchored = true
	plotBase.Material = Enum.Material.Ground
	plotBase.BrickColor = BrickColor.new("Brown")
	plotBase.Parent = parentModel

	-- Create visual border
	local border = Instance.new("Part")
	border.Name = "PlotBorder"
	border.Size = Vector3.new(PLOT_SIZE.X + 0.5, 0.5, PLOT_SIZE.Z + 0.5)
	border.Position = plotPos + Vector3.new(0, 0.5, 0)
	border.Anchored = true
	border.Material = Enum.Material.Wood
	border.BrickColor = BrickColor.new("Dark brown")
	border.CanCollide = false
	border.Transparency = 0.3
	border.Parent = plotBase

	-- Create status indicator
	local statusIndicator = Instance.new("Part")
	statusIndicator.Name = "StatusIndicator"
	statusIndicator.Size = Vector3.new(1, 0.2, 1)
	statusIndicator.Position = plotPos + Vector3.new(0.5, 0.5, 0.5)
	statusIndicator.Anchored = true
	statusIndicator.Material = Enum.Material.Neon
	statusIndicator.BrickColor = BrickColor.new("Lime green")
	statusIndicator.Shape = Enum.PartType.Cylinder
	statusIndicator.Parent = plotBase

	-- Add surface GUI for plot information
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "PlotInfo"
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.Parent = plotBase

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "PlotLabel"
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "Plot " .. plotIndex .. "\nEmpty\nClick to plant"
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.Parent = surfaceGui

	-- FIXED: Enhanced click detector setup
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.Name = "PlotClickDetector"
	clickDetector.MaxActivationDistance = 50
	clickDetector.Parent = plotBase

	-- Plot data structure
	local plotData = {
		part = plotBase,
		indicator = statusIndicator,
		clickDetector = clickDetector,
		surfaceGui = surfaceGui,
		textLabel = textLabel,
		owner = player,
		plotIndex = plotIndex,
		seedType = nil,
		plantTime = nil,
		growthStage = 0,
		isReady = false,
		cropModel = nil
	}

	-- FIXED: Connect click event with proper handling
	clickDetector.MouseClick:Connect(function(clickingPlayer)
		if clickingPlayer == player then
			debugLog("Plot " .. plotIndex .. " clicked by owner " .. player.Name)
			GardenSystem.HandlePlotClick(clickingPlayer, plotData)
		else
			debugLog("Plot " .. plotIndex .. " clicked by non-owner " .. clickingPlayer.Name)
		end
	end)

	debugLog("Created plot " .. plotIndex .. " for " .. player.Name .. " with click detector")
	return plotData
end

-- Enhanced nameplate with floating animation
function GardenSystem.CreatePlayerNameplate(player, centerPos, parentModel)
	local nameplate = Instance.new("Part")
	nameplate.Name = player.Name .. "_Nameplate"
	nameplate.Size = Vector3.new(10, 1, 3)
	nameplate.Position = centerPos + Vector3.new(0, 20, 0)
	nameplate.Anchored = true
	nameplate.CanCollide = false
	nameplate.Transparency = 1
	nameplate.Parent = parentModel

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = nameplate

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = player.Name .. "'s Magical Garden"
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.Fantasy
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.fromRGB(150, 255, 200)
	textLabel.Parent = gui

	-- Floating animation
	local floatTween = TweenService:Create(
		nameplate,
		TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Position = centerPos + Vector3.new(0, 25, 0)}
	)
	floatTween:Play()
end

-- FIXED: Enhanced plot click handling
function GardenSystem.HandlePlotClick(clickingPlayer, plotData)
	debugLog("Handling plot click for plot " .. plotData.plotIndex .. " by " .. clickingPlayer.Name)

	if clickingPlayer ~= plotData.owner then
		debugLog("Non-owner click ignored", "WARNING")
		return
	end

	-- For now, this will integrate with your RemoteEventHandler
	-- The client-side PlotClickHandler will show the seed selection GUI
	-- and fire PlantSeedEvent to the server
	
	debugLog("Plot " .. plotData.plotIndex .. " interaction ready for " .. clickingPlayer.Name)
end

-- FIXED: Visual update system for plots
function GardenSystem.UpdatePlotVisual(plotData, plotInfo)
	if not plotData or not plotData.textLabel then return end

	if plotInfo and plotInfo.seedType then
		-- Show planted crop
		local seedType = plotInfo.seedType
		local isReady = plotInfo.isReady or false
		
		if isReady then
			plotData.textLabel.Text = "Plot " .. plotData.plotIndex .. "\n🌾 " .. seedType:upper() .. "\n✅ READY TO HARVEST!"
			plotData.indicator.BrickColor = BrickColor.new("Bright green")
			plotData.indicator.Material = Enum.Material.Neon
		else
			plotData.textLabel.Text = "Plot " .. plotData.plotIndex .. "\n🌱 " .. seedType:upper() .. "\n⏳ Growing..."
			plotData.indicator.BrickColor = BrickColor.new("Yellow")
			plotData.indicator.Material = Enum.Material.Plastic
		end
		
		debugLog("Updated visual for plot " .. plotData.plotIndex .. " - " .. seedType .. (isReady and " (READY)" or " (GROWING)"))
	else
		-- Show empty plot
		plotData.textLabel.Text = "Plot " .. plotData.plotIndex .. "\nEmpty\n💭 Click to plant"
		plotData.indicator.BrickColor = BrickColor.new("Lime green")
		plotData.indicator.Material = Enum.Material.Plastic
	end
end

-- Get player's garden model
function GardenSystem.GetPlayerGarden(player)
	return playerGardens[player.UserId]
end

-- Get player's plots
function GardenSystem.GetPlayerPlots(player)
	return playerPlots[player.UserId] or {}
end

-- Update all plot visuals for a player (called by RemoteEventHandler)
function GardenSystem.UpdatePlayerGardenVisuals(player, plotsData)
	local plots = playerPlots[player.UserId]
	if not plots then 
		debugLog("No plots found for " .. player.Name, "WARNING")
		return 
	end

	for plotIndex, plotData in pairs(plots) do
		local plotInfo = plotsData and plotsData[tostring(plotIndex)]
		GardenSystem.UpdatePlotVisual(plotData, plotInfo)
	end
end

-- FIXED: Initialize pre-built gardens (for testing)
local function initializeTestGardens()
	local GARDEN_COUNT = 3 -- Reduced for testing
	
	for i = 1, GARDEN_COUNT do
		local mockPlayer = {
			UserId = i,
			Name = "TestGarden" .. i
		}
		
		GardenSystem.InitializePlayerGarden(mockPlayer)
		debugLog("Initialized test garden " .. i)
	end
end

-- Enhanced shop generation
local function generateShops()
	local TERRAIN_HEIGHT = 5
	local shopConfigs = {
		{name = "SeedShop", color = "Bright green", pos = Vector3.new(50, TERRAIN_HEIGHT + 6, 50), icon = "🌱"},
		{name = "AnimalShop", color = "Bright blue", pos = Vector3.new(-50, TERRAIN_HEIGHT + 6, 50), icon = "🐾"},
		{name = "GearShop", color = "Bright red", pos = Vector3.new(50, TERRAIN_HEIGHT + 6, -50), icon = "⚙️"},
		{name = "CraftingStation", color = "Bright yellow", pos = Vector3.new(-50, TERRAIN_HEIGHT + 6, -50), icon = "🔨"}
	}

	for _, cfg in ipairs(shopConfigs) do
		local shopModel = Instance.new("Model")
		shopModel.Name = cfg.name
		shopModel.Parent = workspace

		local building = Instance.new("Part")
		building.Name = "Building"
		building.Size = Vector3.new(16, 12, 16)
		building.Material = Enum.Material.Brick
		building.BrickColor = BrickColor.new(cfg.color)
		building.Anchored = true
		building.Position = cfg.pos
		building.Parent = shopModel

		local sign = Instance.new("Part")
		sign.Name = "Sign"
		sign.Size = Vector3.new(12, 4, 0.5)
		sign.Material = Enum.Material.Wood
		sign.BrickColor = BrickColor.new("Brown")
		sign.Anchored = true
		sign.Position = cfg.pos + Vector3.new(0, 8, 8)
		sign.Parent = shopModel

		local gui = Instance.new("SurfaceGui", sign)
		gui.Face = Enum.NormalId.Front

		local textLabel = Instance.new("TextLabel", gui)
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = cfg.icon .. " " .. cfg.name
		textLabel.TextColor3 = Color3.new(1, 1, 1)
		textLabel.TextScaled = true
		textLabel.Font = Enum.Font.GothamBold
		textLabel.TextStrokeTransparency = 0
		textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)

		debugLog("Generated shop: " .. cfg.name)
	end
end

-- Initialize system
debugLog("Initializing GardenSystem...", "SYSTEM")
generateShops()
initializeTestGardens()

debugLog("GardenSystem initialized successfully!", "SUCCESS")

return GardenSystem