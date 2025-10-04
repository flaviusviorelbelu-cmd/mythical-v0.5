-- PlotClickHandler.lua (StarterPlayerScripts)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer



-- Add this near the top of MainClient.lua and GardenClient.lua
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


print("[PlotClickHandler] Initializing plot click system...")

-- Wait for RemoteEvents
local PlantSeedEvent
local ShowPlotOptionsEvent

spawn(function()
	PlantSeedEvent = ReplicatedStorage:WaitForChild("PlantSeedEvent", 10)
	ShowPlotOptionsEvent = ReplicatedStorage:WaitForChild("ShowPlotOptionsEvent", 10)

	if PlantSeedEvent and ShowPlotOptionsEvent then
		print("[PlotClickHandler] ? RemoteEvents loaded successfully")
	else
		warn("[PlotClickHandler] ? Failed to load RemoteEvents")
	end
end)

-- Function to show seed selection GUI
local function showSeedSelection(plotId)
	print("[PlotClickHandler] Showing seed selection for plot", plotId)

	-- Remove existing GUI
	local playerGui = player:WaitForChild("PlayerGui")
	local existingGui = playerGui:FindFirstChild("SeedSelectionGui")
	if existingGui then
		existingGui:Destroy()
	end

	-- Create new GUI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SeedSelectionGui"
	screenGui.Parent = playerGui

	-- Main frame
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 300, 0, 200)
	frame.Position = UDim2.new(0.5, -150, 0.5, -100)
	frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	frame.BorderSizePixel = 2
	frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
	frame.Parent = screenGui

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	title.Text = "Select Seed to Plant - Plot " .. plotId
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.SourceSansBold
	title.Parent = frame

	-- Seed buttons
	local seeds = {
		{name = "basic_seed", price = 25, color = Color3.fromRGB(0, 255, 0)},
		{name = "stellar_seed", price = 50, color = Color3.fromRGB(255, 255, 0)},
		{name = "cosmic_seed", price = 100, color = Color3.fromRGB(128, 0, 255)}
	}

	for i, seed in ipairs(seeds) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0.9, 0, 0, 35)
		button.Position = UDim2.new(0.05, 0, 0, 35 + (i * 40))
		button.BackgroundColor3 = seed.color
		button.Text = seed.name:gsub("_", " "):upper()
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextScaled = true
		button.Font = Enum.Font.SourceSansBold
		button.Parent = frame

		button.MouseButton1Click:Connect(function()
			print("[PlotClickHandler] Selected seed:", seed.name, "for plot", plotId)
			if PlantSeedEvent then
				PlantSeedEvent:FireServer(plotId, seed.name)
			end
			screenGui:Destroy()
		end)
	end

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -35, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.Parent = frame

	closeButton.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)
end

-- Connect to existing plots
local function connectToPlots()
	local character = player.Character or player.CharacterAdded:Wait()
	wait(3) -- Wait for garden to be created

	local gardenName = "Garden1"
	local garden = workspace:FindFirstChild(gardenName)

	if not garden then
		warn("[PlotClickHandler] ? Garden not found:", gardenName)
		return
	end

	print("[PlotClickHandler] ? Found garden:", gardenName)

	-- Connect to all plots
	for i = 1, 9 do
		local plotName = "Plot_" .. i
		local plot = garden:FindFirstChild(plotName)

		if plot then
			local clickDetector = plot:FindFirstChild("ClickDetector")
			if clickDetector then
				clickDetector.MouseClick:Connect(function(clickingPlayer)
					if clickingPlayer == player then
						print("[PlotClickHandler] ?? Plot", i, "clicked!")
						showSeedSelection(i)
					end
				end)
				print("[PlotClickHandler] ? Connected to", plotName)
			else
				warn("[PlotClickHandler] ? No ClickDetector found on", plotName)
			end
		else
			warn("[PlotClickHandler] ? Plot not found:", plotName)
		end
	end
end

-- Connect when character spawns
player.CharacterAdded:Connect(connectToPlots)
if player.Character then
	connectToPlots()
end

print("[PlotClickHandler] Plot click handler loaded!")
