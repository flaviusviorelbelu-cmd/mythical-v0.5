print("?? GAMEMANAGER STARTING NOW!")

-- GameManager.lua - Creates all RemoteEvents FIRST (like your Lunar)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[GameManager] Starting Mythical Game Manager...")

-- Create ALL RemoteEvents at startup (FIXED NAMES to match your clients)
local remoteEventNames = {
	"PlantSeedEvent",        -- Client expects this
	"BuySeedEvent",         -- Client expects this
	"HarvestPlantEvent",    -- Client expects this
	"SellPlantEvent",       -- Client expects this
	"UpdatePlayerData",
	"ShowFeedback",
	"RequestInventoryUpdate", -- Client expects this
	"PlotDataChanged",      -- Client expects this
	"ShowPlotOptionsEvent", -- Client expects this
	"BuyEgg",
	"EquipPet",
	"UnequipPet",           -- Client expects this
	"SellPet",              -- Client expects this
	"FusePets"              -- Client expects this
}

-- Create RemoteEvents (your working Lunar pattern)
for _, name in ipairs(remoteEventNames) do
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end

	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = ReplicatedStorage
	print("[GameManager] Created RemoteEvent:", name)
end

-- Create RemoteFunctions (FIXED NAMES to match your clients)
local remoteFunctionNames = {
	"GetPlayerStats",       -- Client expects this
	"GetGardenPlots",       -- Client expects this
	"GetPetData",           -- Client expects this
	"GetShopData"           -- Client expects this
}

for _, name in ipairs(remoteFunctionNames) do
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end

	local func = Instance.new("RemoteFunction")
	func.Name = name
	func.Parent = ReplicatedStorage
	print("[GameManager] Created RemoteFunction:", name)
end

print("[GameManager] All RemoteEvents created successfully!")

-- Simple player connection (like your Lunar)
local function onPlayerAdded(player)
	print("[GameManager] Player joined:", player.Name)

	-- Wait for character
	player.CharacterAdded:Connect(function(character)
		print("[GameManager] Character loaded for:", player.Name)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle existing players
for _, player in pairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

print("[GameManager] Game Manager initialized!")