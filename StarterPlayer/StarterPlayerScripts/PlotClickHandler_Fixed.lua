-- Fixed PlotClickHandler.lua for mythical-v0.5
-- Fixes plot detection and garden naming issues

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

print("[PlotClickHandler] Initializing FIXED plot click system...")

-- Player data matching server structure
local playerData = {
	coins = 0,
	gems = 0,
	level = 1,
	seeds = {
		basic_seed = 0,
		stellar_seed = 0,
		cosmic_seed = 0
	},
	harvested = {
		basic_crop = 0,
		stellar_crop = 0,
		cosmic_crop = 0
	}
}

-- Safe remote loading
local function waitForRemote(name, timeout)
	timeout = timeout or 10
	local startTime = tick()
	
	while tick() - startTime < timeout do
		local remote = ReplicatedStorage:FindFirstChild(name)
		if remote then
			print("[PlotClickHandler] ✓ Found remote:", name)
			return remote
		end
		wait(0.1)
	end
	
	warn("[PlotClickHandler] ❌ Failed to find remote:", name)
	return nil
end

-- Load RemoteEvents safely
local PlantSeedEvent = waitForRemote("PlantSeedEvent")
local HarvestPlantEvent = waitForRemote("HarvestPlantEvent")
local ShowPlotOptionsEvent = waitForRemote("ShowPlotOptionsEvent")
local GetPlayerStats = waitForRemote("GetPlayerStats")

if PlantSeedEvent and HarvestPlantEvent then
	print("[PlotClickHandler] ✅ Core RemoteEvents loaded successfully")
else
	warn("[PlotClickHandler] ⚠️ Some RemoteEvents failed to load - functionality may be limited")
end

-- Enhanced seed selection GUI
local function showSeedSelection(plotId)
	print("[PlotClickHandler] Showing seed selection for plot", plotId)

	-- Remove existing GUI
	local playerGui = player:WaitForChild("PlayerGui")
	local existingGui = playerGui:FindFirstChild("SeedSelectionGui")
	if existingGui then
		existingGui:Destroy()
	end

	-- Create new GUI with enhanced design
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SeedSelectionGui"
	screenGui.Parent = playerGui

	-- Main frame with better styling
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 350, 0, 280)
	frame.Position = UDim2.new(0.5, -175, 0.5, -140)
	frame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	-- Add drop shadow effect
	local shadow = Instance.new("ImageLabel")
	shadow.Size = UDim2.new(1, 6, 1, 6)
	shadow.Position = UDim2.new(0, -3, 0, -3)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxasset://textures/ui/dropshadow.png"
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.5
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10, 10, 118, 118)
	shadow.ZIndex = 0
	shadow.Parent = frame

	-- Enhanced title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	title.Text = "🌱 Select Seed - Plot " .. plotId
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	-- Title corner rounding (top only)
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = title

	-- Add a separator line
	local separator = Instance.new("Frame")
	separator.Size = UDim2.new(1, 0, 0, 2)
	separator.Position = UDim2.new(0, 0, 0, 50)
	separator.BackgroundColor3 = Color3.fromRGB(100, 150, 100)
	separator.BorderSizePixel = 0
	separator.Parent = frame

	-- Enhanced seed configuration
	local seeds = {
		{name = "basic_seed", price = 25, color = Color3.fromRGB(76, 175, 80), emoji = "🌱", desc = "Basic crop seed"},
		{name = "stellar_seed", price = 50, color = Color3.fromRGB(255, 193, 7), emoji = "⭐", desc = "Stellar magic seed"},
		{name = "cosmic_seed", price = 100, color = Color3.fromRGB(156, 39, 176), emoji = "🌌", desc = "Cosmic energy seed"}
	}

	-- Create seed buttons with enhanced design
	for i, seed in ipairs(seeds) do
		local buttonFrame = Instance.new("Frame")
		buttonFrame.Size = UDim2.new(0.9, 0, 0, 50)
		buttonFrame.Position = UDim2.new(0.05, 0, 0, 60 + (i * 55))
		buttonFrame.BackgroundColor3 = seed.color
		buttonFrame.BorderSizePixel = 0
		buttonFrame.Parent = frame

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 8)
		buttonCorner.Parent = buttonFrame

		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 1, 0)
		button.Position = UDim2.new(0, 0, 0, 0)
		button.BackgroundTransparency = 1
		button.Text = seed.emoji .. " " .. seed.name:gsub("_", " "):upper() .. " - " .. seed.price .. " coins"
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextScaled = true
		button.Font = Enum.Font.GothamBold
		button.Parent = buttonFrame

		-- Add hover effects
		button.MouseEnter:Connect(function()
			buttonFrame.BackgroundColor3 = Color3.new(
				math.min(seed.color.R + 0.1, 1),
				math.min(seed.color.G + 0.1, 1),
				math.min(seed.color.B + 0.1, 1)
			)
		end)

		button.MouseLeave:Connect(function()
			buttonFrame.BackgroundColor3 = seed.color
		end)

		-- Click handler
		button.MouseButton1Click:Connect(function()
			print("[PlotClickHandler] ✓ Selected seed:", seed.name, "for plot", plotId)
			if PlantSeedEvent then
				PlantSeedEvent:FireServer(plotId, seed.name)
				print("[PlotClickHandler] ✓ Sent plant request to server")
			else
				warn("[PlotClickHandler] ❌ PlantSeedEvent not available")
			end
			screenGui:Destroy()
		end)
	end

	-- Enhanced close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -50, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
	closeButton.Text = "❌"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = frame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0.5, 0)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	-- Add fade-in animation
	frame.BackgroundTransparency = 1
	for _, child in pairs(frame:GetChildren()) do
		if child:IsA("GuiObject") then
			child.BackgroundTransparency = 1
			if child:IsA("TextLabel") or child:IsA("TextButton") then
				child.TextTransparency = 1
			end
		end
	end

	-- Animate in
	local fadeIn = function(obj, targetTransparency)
		if obj:IsA("GuiObject") then
			for i = 1, 10 do
				obj.BackgroundTransparency = 1 - (i/10) * (1-targetTransparency)
				if obj:IsA("TextLabel") or obj:IsA("TextButton") then
					obj.TextTransparency = 1 - (i/10)
				end
				RunService.Heartbeat:Wait()
			end
		end
	end

	spawn(function()
		fadeIn(frame, 0)
		for _, child in pairs(frame:GetChildren()) do
			fadeIn(child, 0)
		end
	end)
end

-- FIXED: Dynamic garden detection
local function findPlayerGarden()
	local possibleNames = {
		-- Try different garden naming patterns
		player.Name .. "_Garden",
		"Garden" .. player.UserId,
		"Garden1",
		"PlayerGarden_" .. player.Name,
		player.Name .. "Garden"
	}

	print("[PlotClickHandler] 🔍 Searching for player garden...")

	-- Search in workspace for garden
	for _, name in ipairs(possibleNames) do
		local garden = workspace:FindFirstChild(name)
		if garden then
			print("[PlotClickHandler] ✅ Found garden:", name)
			return garden
		end
	end

	-- If not found, search all children of workspace for gardens containing player name
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model") and (obj.Name:find("Garden") or obj.Name:find(player.Name)) then
			print("[PlotClickHandler] ✅ Found potential garden:", obj.Name)
			return obj
		end
	end

	warn("[PlotClickHandler] ❌ No garden found for player:", player.Name)
	return nil
end

-- FIXED: Enhanced plot connection with multiple naming patterns
local function connectToPlots()
	local character = player.Character or player.CharacterAdded:Wait()
	print("[PlotClickHandler] 🚀 Starting plot connection process...")

	-- Wait a bit for garden to be created
	wait(3)

	local garden = findPlayerGarden()
	if not garden then
		-- Retry after longer wait
		print("[PlotClickHandler] 🔄 Retrying garden search...")
		wait(5)
		garden = findPlayerGarden()
	end

	if not garden then
		warn("[PlotClickHandler] ⚠️ Could not find player garden - plot interactions won't work")
		return
	end

	print("[PlotClickHandler] ✅ Using garden:", garden.Name)

	-- Try multiple plot naming patterns
	local plotPatterns = {
		"Plot_%d",
		"Plot%d",
		player.Name .. "_Plot_%d",
		"plot_%d",
		"plot%d"
	}

	local connectedPlots = 0

	-- Connect to plots using different patterns
	for i = 1, 9 do
		local plot = nil
		
		-- Try different naming patterns
		for _, pattern in ipairs(plotPatterns) do
			local plotName = string.format(pattern, i)
			plot = garden:FindFirstChild(plotName)
			if plot then
				print("[PlotClickHandler] ✓ Found plot with pattern '" .. pattern .. "':", plotName)
				break
			end
		end

		-- If not found, search recursively in garden
		if not plot then
			for _, obj in pairs(garden:GetDescendants()) do
				if obj:IsA("BasePart") and (obj.Name:find("Plot") or obj.Name:find("plot")) then
					local plotNum = obj.Name:match("%d+")
					if plotNum and tonumber(plotNum) == i then
						plot = obj
						print("[PlotClickHandler] ✓ Found plot by search:", obj.Name)
						break
					end
				end
			end
		end

		if plot then
			-- Look for existing ClickDetector
			local clickDetector = plot:FindFirstChild("ClickDetector")
			if not clickDetector then
				-- Create one if it doesn't exist
				clickDetector = Instance.new("ClickDetector")
				clickDetector.MaxActivationDistance = 50
				clickDetector.Parent = plot
				print("[PlotClickHandler] ➕ Created ClickDetector for:", plot.Name)
			end

			-- Connect the click handler
			clickDetector.MouseClick:Connect(function(clickingPlayer)
				if clickingPlayer == player then
					print("[PlotClickHandler] 📍 Plot", i, "clicked! (", plot.Name, ")")
					showSeedSelection(i)
				end
			end)

			connectedPlots = connectedPlots + 1
			print("[PlotClickHandler] ✅ Connected to plot", i, "(", plot.Name, ")")
		else
			warn("[PlotClickHandler] ❌ Plot", i, "not found in garden")
		end
	end

	if connectedPlots > 0 then
		print("[PlotClickHandler] 🎉 Successfully connected to", connectedPlots, "/9 plots")
	else
		warn("[PlotClickHandler] ⚠️ No plots connected - check garden structure")
	end
end

-- Connect when character spawns
player.CharacterAdded:Connect(function()
	print("[PlotClickHandler] 🚶 Character spawned, connecting to plots...")
	connectToPlots()
end)

-- Connect immediately if character already exists
if player.Character then
	print("[PlotClickHandler] 🚶 Character already exists, connecting to plots...")
	connectToPlots()
end

-- Optional: Listen for garden creation events
workspace.ChildAdded:Connect(function(child)
	if child:IsA("Model") and (child.Name:find(player.Name) and child.Name:find("Garden")) then
		print("[PlotClickHandler] 🌱 New garden detected:", child.Name)
		wait(2) -- Let it fully load
		connectToPlots()
	end
end)

print("[PlotClickHandler] ✅ FIXED Plot click handler loaded successfully!")