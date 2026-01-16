-- Script: ServerScriptService > DataStoreManager
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataStore = DataStoreService:GetDataStore("PlayerInventoryV1")
local InventoryData = require(ReplicatedStorage:WaitForChild("InventoryData"))

local DataStoreManager = {}

-- ===============================================
-- PLAYER SAVE QUEUE
-- ===============================================

local saveQueue = {}
local HttpService = game:GetService("HttpService")

local function queueSave(player, data)
	local userId = player.UserId
	saveQueue[userId] = data
end

local function processQueue()
	for userId, data in pairs(saveQueue) do
		local success
		for attempt = 1, 5 do
			success = pcall(function()
				PlayerDataStore:SetAsync(userId, data)
			end)
			if success then
				print("✓ Data saved for userId", userId)
				break
			else
				warn("Failed to save data for userId", userId, "- Attempt", attempt)
				task.wait(3)
			end
		end
		if not success then
			warn("❌ Could not save data for userId", userId)
		end
		saveQueue[userId] = nil
	end
end

task.spawn(function()
	while true do
		if next(saveQueue) then
			processQueue()
		end
		task.wait(2)
	end
end)

-- Cooldown tracking to prevent spam
local lastSaveTime = {}
local SAVE_COOLDOWN = 5 -- Minimum seconds between saves per player

-- ===============================================
-- DEFAULT DATA FOR NEW PLAYERS
-- ===============================================

local function getDefaultData()
	return {
		Money = 500,
		KillerChance = 1,
		OwnedKillers = {
			Zombie = {
				Owned = true,
				Skins = {
					Default = true
				}
			},
			Alien = {
				Owned = true,
				Skins = {
					Default = true
				}
			}
		},
		OwnedSurvivors = {
			Dummy = {
				Owned = true,
				Skins = {
					Default = true
				}
			},
			Burras = {
				Owned = true,
				Skins = {
					Default = true
				}
			},
			Rae = {
				Owned = true,
				Skins = {
					Default = true
				}
			}
		},
		EquippedKiller = "Zombie",
		EquippedKillerSkin = "Default",
		EquippedSurvivor = "Dummy",
		EquippedSurvivorSkin = "Default"
	}
end

-- ===============================================
-- LOAD PLAYER DATA
-- ===============================================

function DataStoreManager:LoadPlayerData(player)
	local userId = player.UserId
	local success, data

	-- Try to load data with retries
	for i = 1, 3 do
		success, data = pcall(function()
			return PlayerDataStore:GetAsync(userId)
		end)

		if success then
			break
		else
			warn("Failed to load data for", player.Name, "- Attempt", i)
			task.wait(1)
		end
	end

	-- If no data exists or failed, use defaults
	if not success or not data then
		warn("Using default data for", player.Name)
		data = getDefaultData()
	end

	-- Ensure all default fields exist (for updates)
	local defaults = getDefaultData()
	for key, value in pairs(defaults) do
		if data[key] == nil then
			data[key] = value
		end
	end

	return data
end

-- ===============================================
-- SAVE PLAYER DATA
-- ===============================================

function DataStoreManager:SavePlayerData(player, data)
	local userId = player.UserId
	local now = os.time()

	if lastSaveTime[userId] and now - lastSaveTime[userId] < SAVE_COOLDOWN then
		return -- ignora spam
	end

	lastSaveTime[userId] = now
	queueSave(player, data)
end

-- Force save (ignores cooldown) - use for shutdown/player leaving
function DataStoreManager:ForceSavePlayerData(player, data)
	local userId = player.UserId
	local success
	for attempt = 1, 5 do
		success = pcall(function()
			PlayerDataStore:UpdateAsync(userId, function()
				return data
			end)
		end)
		if success then
			print("✓ Force saved data for", player.Name)
			break
		else
			warn("Failed to force save data for", player.Name, "- Attempt", attempt)
			task.wait(3)
		end
	end
	if not success then
		warn("❌ Could not force save data for", player.Name)
	end
	saveQueue[userId] = nil
end

-- ===============================================
-- APPLY DATA TO PLAYER
-- ===============================================

function DataStoreManager:ApplyDataToPlayer(player, data)
	-- Create Money value
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local money = leaderstats:FindFirstChild("Money")
	if not money then
		money = Instance.new("NumberValue")
		money.Name = "Money"
		money.Parent = leaderstats
	end
	money.Value = data.Money or 500
	
	local killerChance = leaderstats:FindFirstChild("Killer Chance")
	if not killerChance then
		killerChance = Instance.new("NumberValue")
		killerChance.Name = "Killer Chance"
		killerChance.Parent = leaderstats
	end
	killerChance.Value = data.KillerChance or 1

	-- Apply equipped items
	if player:FindFirstChild("EquippedKiller") then
		player.EquippedKiller.Value = data.EquippedKiller or "Zombie"
	end
	if player:FindFirstChild("EquippedKillerSkin") then
		player.EquippedKillerSkin.Value = data.EquippedKillerSkin or "Default"
	end
	if player:FindFirstChild("EquippedSurvivor") then
		player.EquippedSurvivor.Value = data.EquippedSurvivor or "Dummy"
	end
	if player:FindFirstChild("EquippedSurvivorSkin") then
		player.EquippedSurvivorSkin.Value = data.EquippedSurvivorSkin or "Default"
	end

	print("✓ Data applied for", player.Name)
end

-- ===============================================
-- GET CURRENT PLAYER DATA
-- ===============================================

function DataStoreManager:GetCurrentData(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats:FindFirstChild("Money")

	-- Get owned items from attributes (set by shop system)
	local ownedKillers = player:GetAttribute("OwnedKillers")
	local ownedSurvivors = player:GetAttribute("OwnedSurvivors")

	-- Decode if stored as JSON
	if type(ownedKillers) == "string" then
		ownedKillers = game:GetService("HttpService"):JSONDecode(ownedKillers)
	end
	if type(ownedSurvivors) == "string" then
		ownedSurvivors = game:GetService("HttpService"):JSONDecode(ownedSurvivors)
	end

	return {
		Money = money and money.Value or 500,
		KillerChance = leaderstats:FindFirstChild("Killer Chance") and leaderstats["Killer Chance"].Value or 1,
		OwnedKillers = ownedKillers or getDefaultData().OwnedKillers,
		OwnedSurvivors = ownedSurvivors or getDefaultData().OwnedSurvivors,
		EquippedKiller = player:FindFirstChild("EquippedKiller") and player.EquippedKiller.Value or "Zombie",
		EquippedKillerSkin = player:FindFirstChild("EquippedKillerSkin") and player.EquippedKillerSkin.Value or "Default",
		EquippedSurvivor = player:FindFirstChild("EquippedSurvivor") and player.EquippedSurvivor.Value or "Dummy",
		EquippedSurvivorSkin = player:FindFirstChild("EquippedSurvivorSkin") and player.EquippedSurvivorSkin.Value or "Default"
	}
end

-- ===============================================
-- STORE IN ATTRIBUTES FOR CLIENT ACCESS
-- ===============================================

function DataStoreManager:StoreInAttributes(player, data)
	local HttpService = game:GetService("HttpService")

	-- Store owned items as JSON in attributes
	player:SetAttribute("OwnedKillers", HttpService:JSONEncode(data.OwnedKillers or {}))
	player:SetAttribute("OwnedSurvivors", HttpService:JSONEncode(data.OwnedSurvivors or {}))
end

return DataStoreManager