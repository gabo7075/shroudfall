-- Script: ServerScriptService > EquipmentHandler
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Crear carpeta de Remotes si no existe
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
end

-- Crear RemoteEvent para equipar personajes
local EquipCharacterRemote = Remotes:FindFirstChild("EquipCharacter")
if not EquipCharacterRemote then
	EquipCharacterRemote = Instance.new("RemoteEvent")
	EquipCharacterRemote.Name = "EquipCharacter"
	EquipCharacterRemote.Parent = Remotes
end

-- Crear RemoteFunction para comprar items
local PurchaseItemRemote = Remotes:FindFirstChild("PurchaseItem")
if not PurchaseItemRemote then
	PurchaseItemRemote = Instance.new("RemoteFunction")
	PurchaseItemRemote.Name = "PurchaseItem"
	PurchaseItemRemote.Parent = Remotes
end

-- ===============================================
-- MÓDULOS
-- ===============================================

local InventoryData = require(ReplicatedStorage:WaitForChild("InventoryData"))
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))

-- ===============================================
-- VALIDACIÓN DE EQUIPAMIENTO
-- ===============================================

local function isValidEquipment(categoryName, characterName, skinName, userId)
	for _, category in ipairs(InventoryData.Categories) do
		if category.Name == categoryName then
			for _, character in ipairs(category.Items) do
				if character.Name == characterName then
					if character.Exclusive then
						if not InventoryData:HasExclusiveAccess(userId) then
							warn("Usuario", userId, "intentó equipar personaje exclusivo sin acceso:", characterName)
							return false
						end
					end

					for _, skin in ipairs(character.Skins) do
						if skin.Name == skinName then
							if skin.Exclusive then
								if not InventoryData:HasExclusiveAccess(userId) then
									warn("Usuario", userId, "intentó equipar skin exclusiva sin acceso:", skinName)
									return false
								end
							end
							return true
						end
					end
				end
			end
		end
	end
	return false
end

-- ===============================================
-- SISTEMA DE JUGADORES
-- ===============================================

local function createPlayerValues(player)
	local equippedKiller = Instance.new("StringValue")
	equippedKiller.Name = "EquippedKiller"
	equippedKiller.Value = "Zombie"
	equippedKiller.Parent = player

	local equippedKillerSkin = Instance.new("StringValue")
	equippedKillerSkin.Name = "EquippedKillerSkin"
	equippedKillerSkin.Value = "Default"
	equippedKillerSkin.Parent = player

	local equippedSurvivor = Instance.new("StringValue")
	equippedSurvivor.Name = "EquippedSurvivor"
	equippedSurvivor.Value = "Dummy"
	equippedSurvivor.Parent = player

	local equippedSurvivorSkin = Instance.new("StringValue")
	equippedSurvivorSkin.Name = "EquippedSurvivorSkin"
	equippedSurvivorSkin.Value = "Default"
	equippedSurvivorSkin.Parent = player

	print("Valores de equipamiento creados para:", player.Name)
end

local function equipCharacter(player, categoryName, characterName, skinName)
	if categoryName == "Killers" then
		local killerValue = player:FindFirstChild("EquippedKiller")
		local killerSkinValue = player:FindFirstChild("EquippedKillerSkin")

		if killerValue and killerSkinValue then
			killerValue.Value = characterName
			killerSkinValue.Value = skinName
			print(player.Name, "equipó Killer:", characterName, "con skin:", skinName)
		end

	elseif categoryName == "Survivors" then
		local survivorValue = player:FindFirstChild("EquippedSurvivor")
		local survivorSkinValue = player:FindFirstChild("EquippedSurvivorSkin")

		if survivorValue and survivorSkinValue then
			survivorValue.Value = characterName
			survivorSkinValue.Value = skinName
			print(player.Name, "equipó Survivor:", characterName, "con skin:", skinName)
		end
	end
end

-- ===============================================
-- SHOP SYSTEM - PURCHASE HANDLER
-- ===============================================

PurchaseItemRemote.OnServerInvoke = function(player, categoryName, characterName, skinName)
	local HttpService = game:GetService("HttpService")

	-- Get player's money
	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats:FindFirstChild("Money")

	if not money then
		return {success = false, message = "Error: No money value found"}
	end

	-- Find the item in InventoryData
	local itemData = nil
	local price = 0
	local isPurchasingSkin = (skinName ~= nil and skinName ~= "")

	for _, category in ipairs(InventoryData.Categories) do
		if category.Name == categoryName then
			for _, character in ipairs(category.Items) do
				if character.Name == characterName then
					if isPurchasingSkin then
						-- Purchasing a skin
						for _, skin in ipairs(character.Skins) do
							if skin.Name == skinName then
								itemData = skin
								price = skin.Price or 0
								break
							end
						end
					else
						-- Purchasing a character
						itemData = character
						price = character.Price or 0
					end
					break
				end
			end
			break
		end
	end

	if not itemData then
		return {success = false, message = "Item not found"}
	end

	-- Check if already owned
	local ownedAttr = player:GetAttribute(categoryName == "Killers" and "OwnedKillers" or "OwnedSurvivors")
	local ownedData = {}

	if ownedAttr and type(ownedAttr) == "string" then
		ownedData = HttpService:JSONDecode(ownedAttr)
	end

	if isPurchasingSkin then
		if ownedData[characterName] and ownedData[characterName].Skins and ownedData[characterName].Skins[skinName] then
			return {success = false, message = "You already own this skin"}
		end
	else
		if ownedData[characterName] and ownedData[characterName].Owned then
			return {success = false, message = "You already own this character"}
		end
	end

	-- Check if player has enough money
	if money.Value < price then
		return {success = false, message = "Not enough money"}
	end

	-- Deduct money
	money.Value = money.Value - price

	-- Add to owned items
	if isPurchasingSkin then
		if not ownedData[characterName] then
			ownedData[characterName] = {Owned = false, Skins = {}}
		end
		if not ownedData[characterName].Skins then
			ownedData[characterName].Skins = {}
		end
		ownedData[characterName].Skins[skinName] = true
	else
		if not ownedData[characterName] then
			ownedData[characterName] = {Owned = true, Skins = {Default = true}}
		else
			ownedData[characterName].Owned = true
			if not ownedData[characterName].Skins then
				ownedData[characterName].Skins = {Default = true}
			end
		end
	end

	-- Save back to attribute
	player:SetAttribute(categoryName == "Killers" and "OwnedKillers" or "OwnedSurvivors", HttpService:JSONEncode(ownedData))

	-- Save to DataStore (with cooldown)
	local currentData = DataStoreManager:GetCurrentData(player)
	DataStoreManager:SavePlayerData(player, currentData) -- Respects cooldown

	print("✓", player.Name, "purchased:", isPurchasingSkin and skinName or characterName, "for", price)

	return {success = true, message = "Purchase successful!"}
end

-- ===============================================
-- EVENTOS
-- ===============================================

Players.PlayerAdded:Connect(function(player)
	createPlayerValues(player)

	-- Load data from DataStore
	local data = DataStoreManager:LoadPlayerData(player)

	-- Store in attributes for client access
	DataStoreManager:StoreInAttributes(player, data)

	-- Apply loaded data
	DataStoreManager:ApplyDataToPlayer(player, data)
end)

Players.PlayerRemoving:Connect(function(player)
	-- Save data when player leaves
	local data = DataStoreManager:GetCurrentData(player)
	DataStoreManager:SavePlayerData(player, data)
end)

EquipCharacterRemote.OnServerEvent:Connect(function(player, categoryName, characterName, skinName)
	equipCharacter(player, categoryName, characterName, skinName)

	-- Save equipped items to DataStore (with cooldown)
	task.spawn(function()
		local data = DataStoreManager:GetCurrentData(player)
		DataStoreManager:SavePlayerData(player, data) -- This respects cooldown
	end)
end)

-- Auto-save every 5 minutes
game:GetService("RunService").Heartbeat:Connect(function()
	task.wait(300) -- 5 minutes

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			local data = DataStoreManager:GetCurrentData(player)
			DataStoreManager:SavePlayerData(player, data)
		end)
	end
end)

-- Save all data on shutdown
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local data = DataStoreManager:GetCurrentData(player)
		DataStoreManager:SavePlayerData(player, data)
	end
	task.wait(2) -- Give time to save
end)

print("Sistema de equipamiento y tienda inicializado")

-- ===============================================
-- FUNCIONES ÚTILES
-- ===============================================

local function getPlayerEquipment(player)
	return {
		Killer = player:FindFirstChild("EquippedKiller") and player.EquippedKiller.Value or nil,
		KillerSkin = player:FindFirstChild("EquippedKillerSkin") and player.EquippedKillerSkin.Value or nil,
		Survivor = player:FindFirstChild("EquippedSurvivor") and player.EquippedSurvivor.Value or nil,
		SurvivorSkin = player:FindFirstChild("EquippedSurvivorSkin") and player.EquippedSurvivorSkin.Value or nil
	}
end

_G.GetPlayerEquipment = getPlayerEquipment