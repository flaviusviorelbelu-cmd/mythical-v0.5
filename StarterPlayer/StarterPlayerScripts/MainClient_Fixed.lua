-- Fixed MainClient.lua for mythical-v0.5
-- Fixes inventory display and plot interaction issues

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("[MainClient] Initializing FIXED version for player:", player.Name)

-- Enhanced player data structure
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
	},
	inventory = {
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
}

-- Connection state tracking
local connectionState = {
	remotesLoaded = false,
	dataLoaded = false,
	uiCreated = false
}

-- Remote event containers
local remoteEvents = {}
local remoteFunctions = {}
local CONNECTION_TIMEOUT = 30
local RETRY_DELAY = 1

-- All remote names (consistent with your server)
local REMOTE_EVENTS = {
	"BuyEgg", "EquipPet", "UnequipPet", "SellPet", "FusePets", "ShowFeedback",
	"BuySeedEvent", "PlantSeedEvent", "HarvestPlantEvent", "SellPlantEvent", 
	"RequestInventoryUpdate", "PlotDataChanged", "ShowPlotOptionsEvent",
	"UpdatePlayerData"
}

local REMOTE_FUNCTIONS = {
	"GetPlayerStats"
}

-- Enhanced remote loading with retry mechanism
local function loadRemoteObjects()
	local startTime = tick()
	local loadedEvents = {}
	local loadedFunctions = {}

	print("[MainClient] Starting remote object loading...")

	-- Load RemoteEvents
	spawn(function()
		for _, eventName in ipairs(REMOTE_EVENTS) do
			spawn(function()
				local attempts = 0
				local maxAttempts = CONNECTION_TIMEOUT / RETRY_DELAY

				while attempts < maxAttempts and not loadedEvents[eventName] do
					local success, remote = pcall(function()
						return ReplicatedStorage:WaitForChild(eventName, RETRY_DELAY)
					end)

					if success and remote then
						remoteEvents[eventName] = remote
						loadedEvents[eventName] = true
						print("[MainClient] ✓ Loaded RemoteEvent:", eventName)
					else
						attempts = attempts + 1
						if attempts % 5 == 0 then
							print("[MainClient] ⏳ Still waiting for RemoteEvent:", eventName, "(attempt", attempts, "/", maxAttempts, ")")
						end
					end
				end

				if not loadedEvents[eventName] then
					warn("[MainClient] ❌ Failed to load RemoteEvent:", eventName)
				end
			end)
		end
	end)

	-- Load RemoteFunctions
	spawn(function()
		for _, funcName in ipairs(REMOTE_FUNCTIONS) do
			spawn(function()
				local attempts = 0
				local maxAttempts = CONNECTION_TIMEOUT / RETRY_DELAY

				while attempts < maxAttempts and not loadedFunctions[funcName] do
					local success, remote = pcall(function()
						return ReplicatedStorage:WaitForChild(funcName, RETRY_DELAY)
					end)

					if success and remote then
						remoteFunctions[funcName] = remote
						loadedFunctions[funcName] = true
						print("[MainClient] ✓ Loaded RemoteFunction:", funcName)
					else
						attempts = attempts + 1
						if attempts % 5 == 0 then
							print("[MainClient] ⏳ Still waiting for RemoteFunction:", funcName)
						end
					end
				end

				if not loadedFunctions[funcName] then
					warn("[MainClient] ❌ Failed to load RemoteFunction:", funcName)
				end
			end)
		end
	end)

	-- Wait for loading completion
	spawn(function()
		while tick() - startTime < CONNECTION_TIMEOUT do
			local eventsLoaded = 0
			local functionsLoaded = 0

			for _, eventName in ipairs(REMOTE_EVENTS) do
				if loadedEvents[eventName] then
					eventsLoaded = eventsLoaded + 1
				end
			end

			for _, funcName in ipairs(REMOTE_FUNCTIONS) do
				if loadedFunctions[funcName] then
					functionsLoaded = functionsLoaded + 1
				end
			end

			if eventsLoaded >= 4 and functionsLoaded >= 1 then -- At least core events
				connectionState.remotesLoaded = true
				print("[MainClient] ✅ Core remote objects loaded successfully!")
				break
			end

			wait(0.5)
		end

		if not connectionState.remotesLoaded then
			warn("[MainClient] ⚠️ Remote loading timeout - continuing with available remotes")
			connectionState.remotesLoaded = true
		end
	end)
end

-- Enhanced feedback system
local function showFeedback(message, messageType, duration)
	messageType = messageType or "info"
	duration = duration or 3

	local existing = playerGui:FindFirstChild("FeedbackMessage")
	if existing then
		existing:Destroy()
	end

	local feedbackGui = Instance.new("ScreenGui")
	feedbackGui.Name = "FeedbackMessage"
	feedbackGui.ResetOnSpawn = false
	feedbackGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 400, 0, 80)
	frame.Position = UDim2.new(0.5, -200, 0, -100)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = feedbackGui

	local colors = {
		success = Color3.fromRGB(46, 204, 113),
		error = Color3.fromRGB(231, 76, 60),
		warning = Color3.fromRGB(241, 196, 15),
		info = Color3.fromRGB(52, 152, 219)
	}
	frame.BackgroundColor3 = colors[messageType] or colors.info

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -20, 1, 0)
	textLabel.Position = UDim2.new(0, 10, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = message
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Parent = frame

	local tweenIn = TweenService:Create(
		frame,
		TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -200, 0, 50)}
	)
	tweenIn:Play()

	spawn(function()
		wait(duration)
		if feedbackGui and feedbackGui.Parent then
			local tweenOut = TweenService:Create(
				frame,
				TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
				{Position = UDim2.new(0.5, -200, 0, -100), BackgroundTransparency = 1}
			)
			tweenOut:Play()
			tweenOut.Completed:Connect(function()
				if feedbackGui and feedbackGui.Parent then
					feedbackGui:Destroy()
				end
			end)
		end
	end)
end

-- FIXED: Create inventory frame directly in MainClient
local function createInventoryFrame(mainUI)
	local inventoryFrame = Instance.new("ScrollingFrame")
	inventoryFrame.Name = "InventoryFrame"
	inventoryFrame.Size = UDim2.new(0.8, 0, 0.7, 0)
	inventoryFrame.Position = UDim2.new(0.1, 0, 0.15, 0)
	inventoryFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	inventoryFrame.BorderSizePixel = 2
	inventoryFrame.BorderColor3 = Color3.new(0.3, 0.6, 0.3)
	inventoryFrame.ScrollBarThickness = 10
	inventoryFrame.Visible = false
	inventoryFrame.Parent = mainUI

	-- Add title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 5)
	title.BackgroundColor3 = Color3.new(0.2, 0.4, 0.2)
	title.Text = "🎒 Inventory"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = inventoryFrame

	-- Create close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -35, 0, 5)
	closeButton.BackgroundColor3 = Color3.new(0.8, 0.3, 0.3)
	closeButton.Text = "❌"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = inventoryFrame

	closeButton.MouseButton1Click:Connect(function()
		inventoryFrame.Visible = false
		print("[MainClient] Inventory closed via X button")
	end)

	return inventoryFrame
end

-- FIXED: Update inventory display function
local function updateInventoryDisplay()
	print("[MainClient] 🔄 Updating inventory display...")

	-- FIXED: Use consistent remote function reference
	if not remoteFunctions.GetPlayerStats then
		print("[MainClient] ❌ GetPlayerStats not available - cannot update inventory")
		return
	end

	-- Get fresh data from server
	local success, serverData = pcall(function()
		return remoteFunctions.GetPlayerStats:InvokeServer()
	end)

	if not success or not serverData then
		warn("[MainClient] ❌ Failed to get player data for inventory:", serverData)
		return
	end

	print("[MainClient] ✅ Got data - Coins:", serverData.coins)

	-- Update local playerData
	playerData.coins = serverData.coins or 0
	playerData.gems = serverData.gems or 0

	-- Initialize and update seeds
	if not serverData.seeds then
		serverData.seeds = {}
	end

	if not serverData.harvested then
		serverData.harvested = {}
	end

	print("[MainClient] 🌱 Seeds in inventory:")
	for seedType, amount in pairs(serverData.seeds) do
		print("   ", seedType, ":", amount)
	end

	-- Update inventory UI if it's open
	local mainUI = playerGui:FindFirstChild("MainGameUI")
	if mainUI then
		local inventoryFrame = mainUI:FindFirstChild("InventoryFrame")
		if inventoryFrame and inventoryFrame.Visible then
			-- Clear existing items
			for _, child in pairs(inventoryFrame:GetChildren()) do
				if child.Name:find("Item") then
					child:Destroy()
				end
			end

			-- Create inventory display
			local yOffset = 50
			
			-- Seeds section
			for seedType, count in pairs(serverData.seeds) do
				if count > 0 then
					local itemFrame = Instance.new("Frame")
					itemFrame.Name = "SeedItem_" .. seedType
					itemFrame.Size = UDim2.new(0.9, 0, 0, 40)
					itemFrame.Position = UDim2.new(0.05, 0, 0, yOffset)
					itemFrame.BackgroundColor3 = Color3.new(0.2, 0.3, 0.2)
					itemFrame.BorderSizePixel = 1
					itemFrame.BorderColor3 = Color3.new(0.4, 0.5, 0.4)
					itemFrame.Parent = inventoryFrame

					local nameLabel = Instance.new("TextLabel")
					nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
					nameLabel.Position = UDim2.new(0.05, 0, 0, 0)
					nameLabel.BackgroundTransparency = 1
					nameLabel.Text = "🌱 " .. seedType:gsub("_", " "):upper()
					nameLabel.TextColor3 = Color3.new(1, 1, 1)
					nameLabel.TextScaled = true
					nameLabel.Font = Enum.Font.Gotham
					nameLabel.TextXAlignment = Enum.TextXAlignment.Left
					nameLabel.Parent = itemFrame

					local countLabel = Instance.new("TextLabel")
					countLabel.Size = UDim2.new(0.25, 0, 1, 0)
					countLabel.Position = UDim2.new(0.75, 0, 0, 0)
					countLabel.BackgroundTransparency = 1
					countLabel.Text = "x" .. count
					countLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
					countLabel.TextScaled = true
					countLabel.Font = Enum.Font.GothamBold
					countLabel.TextXAlignment = Enum.TextXAlignment.Right
					countLabel.Parent = itemFrame

					yOffset = yOffset + 45
				end
			end

			-- Harvested section
			if serverData.harvested then
				yOffset = yOffset + 20
				
				local harvestTitle = Instance.new("TextLabel")
				harvestTitle.Size = UDim2.new(0.9, 0, 0, 30)
				harvestTitle.Position = UDim2.new(0.05, 0, 0, yOffset)
				harvestTitle.BackgroundColor3 = Color3.new(0.4, 0.3, 0.1)
				harvestTitle.Text = "🌾 Harvested"
				harvestTitle.TextColor3 = Color3.new(1, 1, 1)
				harvestTitle.TextScaled = true
				harvestTitle.Font = Enum.Font.GothamBold
				harvestTitle.Parent = inventoryFrame
				yOffset = yOffset + 35

				for cropType, count in pairs(serverData.harvested) do
					if count > 0 then
						local itemFrame = Instance.new("Frame")
						itemFrame.Name = "HarvestItem_" .. cropType
						itemFrame.Size = UDim2.new(0.9, 0, 0, 40)
						itemFrame.Position = UDim2.new(0.05, 0, 0, yOffset)
						itemFrame.BackgroundColor3 = Color3.new(0.3, 0.2, 0.1)
						itemFrame.BorderSizePixel = 1
						itemFrame.BorderColor3 = Color3.new(0.6, 0.4, 0.2)
						itemFrame.Parent = inventoryFrame

						local nameLabel = Instance.new("TextLabel")
						nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
						nameLabel.Position = UDim2.new(0.05, 0, 0, 0)
						nameLabel.BackgroundTransparency = 1
						nameLabel.Text = "🌾 " .. cropType:gsub("_", " "):upper()
						nameLabel.TextColor3 = Color3.new(1, 1, 1)
						nameLabel.TextScaled = true
						nameLabel.Font = Enum.Font.Gotham
						nameLabel.TextXAlignment = Enum.TextXAlignment.Left
						nameLabel.Parent = itemFrame

						local countLabel = Instance.new("TextLabel")
						countLabel.Size = UDim2.new(0.2, 0, 1, 0)
						countLabel.Position = UDim2.new(0.5, 0, 0, 0)
						countLabel.BackgroundTransparency = 1
						countLabel.Text = "x" .. count
						countLabel.TextColor3 = Color3.new(1, 1, 0.5)
						countLabel.TextScaled = true
						countLabel.Font = Enum.Font.GothamBold
						countLabel.TextXAlignment = Enum.TextXAlignment.Center
						countLabel.Parent = itemFrame

						local sellButton = Instance.new("TextButton")
						sellButton.Size = UDim2.new(0.25, -5, 0.8, 0)
						sellButton.Position = UDim2.new(0.75, 0, 0.1, 0)
						sellButton.BackgroundColor3 = Color3.new(0.8, 0.6, 0.2)
						sellButton.Text = "Sell"
						sellButton.TextColor3 = Color3.new(1, 1, 1)
						sellButton.TextScaled = true
						sellButton.Font = Enum.Font.GothamBold
						sellButton.Parent = itemFrame

						-- Sell functionality
						sellButton.MouseButton1Click:Connect(function()
							if remoteEvents.SellPlantEvent and count > 0 then
								print("[MainClient] Selling " .. count .. "x " .. cropType)
								remoteEvents.SellPlantEvent:FireServer(cropType, count)
								
								-- Refresh after selling
								wait(0.5)
								updateInventoryDisplay()
							end
						end)

						yOffset = yOffset + 45
					end
				end
			end

			-- Update canvas size
			inventoryFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
		end
	end
end

-- Enhanced data management
local function updatePlayerData()
	if not connectionState.remotesLoaded or not remoteFunctions.GetPlayerStats then
		print("[MainClient] ⏸️ Skipping data update - remotes not ready")
		return false
	end

	spawn(function()
		local success, stats = pcall(function()
			return remoteFunctions.GetPlayerStats:InvokeServer()
		end)

		if success and stats then
			-- Update local data
			playerData.coins = stats.coins or playerData.coins
			playerData.gems = stats.gems or playerData.gems
			playerData.level = stats.level or playerData.level

			-- Update inventory data
			if stats.seeds then
				playerData.seeds = stats.seeds
				if playerData.inventory then
					playerData.inventory.seeds = stats.seeds
				end
			end

			if stats.harvested then
				playerData.harvested = stats.harvested
				if playerData.inventory then
					playerData.inventory.harvested = stats.harvested
				end
			end

			connectionState.dataLoaded = true
			print("[MainClient] ✅ Data updated - Coins:", playerData.coins, "Level:", playerData.level)

			-- Update UI
			if _G.MainClient then
				_G.MainClient.UpdateStatsDisplay()
			end
		else
			warn("[MainClient] ❌ Data update failed:", stats)
		end
	end)
end

-- COMPLETE UI creation function
local function createMainUI()
	if connectionState.uiCreated then
		print("[MainClient] UI already exists, skipping...")
		return
	end

	print("[MainClient] Creating complete main UI...")

	local existingUI = playerGui:FindFirstChild("MainGameUI")
	if existingUI then
		existingUI:Destroy()
	end

	-- Main UI Container
	local mainUI = Instance.new("ScreenGui")
	mainUI.Name = "MainGameUI"
	mainUI.ResetOnSpawn = false
	mainUI.Parent = playerGui

	-- Connection status indicator
	local statusFrame = Instance.new("Frame")
	statusFrame.Name = "ConnectionStatus"
	statusFrame.Size = UDim2.new(0, 200, 0, 30)
	statusFrame.Position = UDim2.new(1, -210, 0, 10)
	statusFrame.BackgroundColor3 = connectionState.remotesLoaded and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(241, 196, 15)
	statusFrame.BorderSizePixel = 0
	statusFrame.Parent = mainUI

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0, 15)
	statusCorner.Parent = statusFrame

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, -10, 1, 0)
	statusLabel.Position = UDim2.new(0, 5, 0, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = connectionState.remotesLoaded and "🟢 Connected" or "🟡 Connecting..."
	statusLabel.TextColor3 = Color3.new(1, 1, 1)
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.Parent = statusFrame

	-- Top Stats Bar
	local statsFrame = Instance.new("Frame")
	statsFrame.Name = "StatsFrame"
	statsFrame.Size = UDim2.new(1, 0, 0, 60)
	statsFrame.Position = UDim2.new(0, 0, 0, 45)
	statsFrame.BackgroundColor3 = Color3.fromRGB(44, 62, 80)
	statsFrame.BorderSizePixel = 0
	statsFrame.Parent = mainUI

	-- Coins Display
	local coinsFrame = Instance.new("Frame")
	coinsFrame.Name = "CoinsFrame"
	coinsFrame.Size = UDim2.new(0, 150, 1, -10)
	coinsFrame.Position = UDim2.new(0, 10, 0, 5)
	coinsFrame.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
	coinsFrame.BorderSizePixel = 0
	coinsFrame.Parent = statsFrame

	local coinsCorner = Instance.new("UICorner")
	coinsCorner.CornerRadius = UDim.new(0, 8)
	coinsCorner.Parent = coinsFrame

	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "CoinsLabel"
	coinsLabel.Size = UDim2.new(1, -20, 1, 0)
	coinsLabel.Position = UDim2.new(0, 10, 0, 0)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "🪙 " .. tostring(playerData.coins)
	coinsLabel.TextColor3 = Color3.new(1, 1, 1)
	coinsLabel.TextScaled = true
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.Parent = coinsFrame

	-- Gems Display
	local gemsFrame = Instance.new("Frame")
	gemsFrame.Name = "GemsFrame"
	gemsFrame.Size = UDim2.new(0, 150, 1, -10)
	gemsFrame.Position = UDim2.new(0, 170, 0, 5)
	gemsFrame.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
	gemsFrame.BorderSizePixel = 0
	gemsFrame.Parent = statsFrame

	local gemsCorner = Instance.new("UICorner")
	gemsCorner.CornerRadius = UDim.new(0, 8)
	gemsCorner.Parent = gemsFrame

	local gemsLabel = Instance.new("TextLabel")
	gemsLabel.Name = "GemsLabel"
	gemsLabel.Size = UDim2.new(1, -20, 1, 0)
	gemsLabel.Position = UDim2.new(0, 10, 0, 0)
	gemsLabel.BackgroundTransparency = 1
	gemsLabel.Text = "💎 " .. tostring(playerData.gems)
	gemsLabel.TextColor3 = Color3.new(1, 1, 1)
	gemsLabel.TextScaled = true
	gemsLabel.Font = Enum.Font.GothamBold
	gemsLabel.Parent = gemsFrame

	-- Level Display
	local levelFrame = Instance.new("Frame")
	levelFrame.Name = "LevelFrame"
	levelFrame.Size = UDim2.new(0, 120, 1, -10)
	levelFrame.Position = UDim2.new(0, 330, 0, 5)
	levelFrame.BackgroundColor3 = Color3.fromRGB(26, 188, 156)
	levelFrame.BorderSizePixel = 0
	levelFrame.Parent = statsFrame

	local levelCorner = Instance.new("UICorner")
	levelCorner.CornerRadius = UDim.new(0, 8)
	levelCorner.Parent = levelFrame

	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(1, -20, 1, 0)
	levelLabel.Position = UDim2.new(0, 10, 0, 0)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "⭐ Level " .. tostring(playerData.level)
	levelLabel.TextColor3 = Color3.new(1, 1, 1)
	levelLabel.TextScaled = true
	levelLabel.Font = Enum.Font.GothamBold
	levelLabel.Parent = levelFrame

	-- Bottom Menu Buttons
	local menuFrame = Instance.new("Frame")
	menuFrame.Name = "MenuFrame"
	menuFrame.Size = UDim2.new(1, 0, 0, 80)
	menuFrame.Position = UDim2.new(0, 0, 1, -80)
	menuFrame.BackgroundColor3 = Color3.fromRGB(44, 62, 80)
	menuFrame.BorderSizePixel = 0
	menuFrame.Parent = mainUI

	-- Menu buttons
	local buttons = {
		{name = "Shop", color = Color3.fromRGB(46, 204, 113), icon = "🏪"},
		{name = "Inventory", color = Color3.fromRGB(52, 152, 219), icon = "🎒"},
		{name = "Pets", color = Color3.fromRGB(155, 89, 182), icon = "🐾"},
		{name = "Garden", color = Color3.fromRGB(230, 126, 34), icon = "🌱"}
	}

	for i, buttonData in ipairs(buttons) do
		local button = Instance.new("TextButton")
		button.Name = buttonData.name .. "Button"
		button.Size = UDim2.new(0.25, -10, 1, -10)
		button.Position = UDim2.new((i-1) * 0.25, 5, 0, 5)
		button.BackgroundColor3 = buttonData.color
		button.BorderSizePixel = 0
		button.Text = buttonData.icon .. " " .. buttonData.name
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextScaled = true
		button.Font = Enum.Font.GothamBold
		button.Parent = menuFrame

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 8)
		buttonCorner.Parent = button

		button.MouseButton1Click:Connect(function()
			print("[MainClient] " .. buttonData.name .. " button clicked!")
			showFeedback(buttonData.name .. " menu clicked! 🎮", "info")
			if _G.MainClient then
				_G.MainClient.ToggleMenu(buttonData.name)
			end
		end)

		button.MouseEnter:Connect(function()
			local hoverTween = TweenService:Create(
				button,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad),
				{Size = UDim2.new(0.25, -5, 1, -5)}
			)
			hoverTween:Play()
		end)

		button.MouseLeave:Connect(function()
			local unhoverTween = TweenService:Create(
				button,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad),
				{Size = UDim2.new(0.25, -10, 1, -10)}
			)
			unhoverTween:Play()
		end)
	end

	connectionState.uiCreated = true
	print("[MainClient] ✅ Complete UI created successfully!")
	return mainUI
end

-- Global client interface
_G.MainClient = {
	UpdateStatsDisplay = function()
		local mainUI = playerGui:FindFirstChild("MainGameUI")
		if not mainUI then
			print("[MainClient] MainGameUI not found for stats update")
			return
		end

		local statsFrame = mainUI:FindFirstChild("StatsFrame")
		if statsFrame then
			local coinsFrame = statsFrame:FindFirstChild("CoinsFrame")
			if coinsFrame and coinsFrame:FindFirstChild("CoinsLabel") then
				coinsFrame.CoinsLabel.Text = "🪙 " .. tostring(playerData.coins)
			end

			local gemsFrame = statsFrame:FindFirstChild("GemsFrame")
			if gemsFrame and gemsFrame:FindFirstChild("GemsLabel") then
				gemsFrame.GemsLabel.Text = "💎 " .. tostring(playerData.gems)
			end

			local levelFrame = statsFrame:FindFirstChild("LevelFrame")
			if levelFrame and levelFrame:FindFirstChild("LevelLabel") then
				levelFrame.LevelLabel.Text = "⭐ Level " .. tostring(playerData.level)
			end

			print("[MainClient] ✅ UI stats updated")
		end

		local statusFrame = mainUI:FindFirstChild("ConnectionStatus")
		if statusFrame and statusFrame:FindFirstChild("StatusLabel") then
			if connectionState.dataLoaded then
				statusFrame.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
				statusFrame.StatusLabel.Text = "🟢 Connected"
			else
				statusFrame.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
				statusFrame.StatusLabel.Text = "🟡 Syncing..."
			end
		end
	end,

	ToggleMenu = function(menuName)
		print("[MainClient] Toggling", menuName, "menu")

		if menuName == "Inventory" then
			local mainUI = playerGui:FindFirstChild("MainGameUI")
			if mainUI then
				local inventoryFrame = mainUI:FindFirstChild("InventoryFrame")
				if not inventoryFrame then
					inventoryFrame = createInventoryFrame(mainUI)
				end

				if inventoryFrame.Visible then
					inventoryFrame.Visible = false
					print("[MainClient] Inventory closed")
				else
					updateInventoryDisplay()
					inventoryFrame.Visible = true
					print("[MainClient] Inventory opened")
				end
			else
				showFeedback("UI not ready", "warning")
			end
		else
			showFeedback(menuName .. " system not yet implemented", "warning")
		end
	end,

	GetPlayerData = function()
		return playerData
	end,

	ShowFeedback = showFeedback,
	RefreshData = updatePlayerData,

	GetConnectionStatus = function()
		return connectionState
	end,

	RecreateUI = function()
		connectionState.uiCreated = false
		createMainUI()
		updatePlayerData()
	end
}

-- Enhanced initialization sequence
spawn(function()
	print("[MainClient] 🚀 Starting FIXED initialization...")

	if not player.Character then
		player.CharacterAdded:Wait()
	end
	print("[MainClient] ✅ Character loaded")

	loadRemoteObjects()

	while not connectionState.remotesLoaded do
		wait(0.5)
	end

	createMainUI()
	updatePlayerData()

	-- Set up feedback handler
	if remoteEvents.ShowFeedback then
		remoteEvents.ShowFeedback.OnClientEvent:Connect(function(message, messageType)
			showFeedback(message, messageType)
		end)
		print("[MainClient] ✅ Feedback handler connected")
	end

	-- Set up periodic data refresh
	spawn(function()
		while player.Parent do
			wait(15)
			updatePlayerData()
		end
	end)

	print("[MainClient] 🎉 FIXED initialization complete!")
	showFeedback("Welcome to Mythical Realm! 🌟", "success", 4)
end)

-- Debug commands (replace with your username)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.F1 then
		_G.MainClient.RecreateUI()
		showFeedback("UI Recreated! 🔄", "info")
	elseif input.KeyCode == Enum.KeyCode.F2 then
		_G.MainClient.RefreshData()
		showFeedback("Data Refreshed! 📊", "info")
	elseif input.KeyCode == Enum.KeyCode.F3 then
		print("[MainClient] Debug Info:")
		print("  Connection State:", connectionState)
		print("  Player Data:", playerData)
		showFeedback("Debug info printed! 🔍", "info")
	elseif input.KeyCode == Enum.KeyCode.F4 then
		updateInventoryDisplay()
		showFeedback("Inventory refreshed! 🎒", "info")
	end
end)

print("[MainClient] ✅ FIXED MainClient loaded successfully!")