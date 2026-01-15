-- ServerScriptService > TerrorSoundManager
-- Creates terror radius sounds on the server in killer character models

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local TerrorSoundManager = {}

-- Helper: Get killer name from character
local function getKillerNameFromCharacter(character)
	if not character then return nil end
	local killerName = nil
	pcall(function()
		killerName = character:GetAttribute("CharacterName")
	end)
	return killerName
end

-- Helper: Load killer config
local function loadKillerConfig(killerName)
	if not killerName then return nil end

	local configPath = ReplicatedStorage:FindFirstChild("Packets")
	if not configPath then return nil end

	configPath = configPath:FindFirstChild("Killers")
	if not configPath then return nil end

	configPath = configPath:FindFirstChild(killerName)
	if not configPath then return nil end

	local configModule = configPath:FindFirstChild("Config")
	if not configModule or not configModule:IsA("ModuleScript") then return nil end

	local success, config = pcall(function()
		return require(configModule)
	end)

	return success and config or nil
end

-- Create terror sounds in killer's character model
function TerrorSoundManager:CreateTerrorSounds(character)
	if not character then return false end

	-- Check if already exists
	if character:FindFirstChild("TerrorSounds") then
		warn("[TerrorSoundManager] TerrorSounds already exists for", character.Name)
		return false
	end

	local killerName = getKillerNameFromCharacter(character)
	if not killerName then
		warn("[TerrorSoundManager] No killer name found for character")
		return false
	end

	local config = loadKillerConfig(killerName)
	if not config or not config.TerrorRadius or not config.TerrorRadius.Sounds then
		warn("[TerrorSoundManager] No terror radius config found for", killerName)
		return false
	end

	-- Create TerrorSounds folder in character
	local terrorFolder = Instance.new("Folder")
	terrorFolder.Name = "TerrorSounds"
	terrorFolder.Parent = character

	-- Create each sound
	for i, soundData in ipairs(config.TerrorRadius.Sounds) do
		local sound = Instance.new("Sound")
		sound.Name = soundData.Name or ("Layer" .. i)
		sound.SoundId = soundData.Id or ""
		sound.Volume = 0 -- Start at 0, client will control volume
		sound.Looped = true
		sound.Playing = false
		sound.RollOffMaxDistance = 100
		sound.RollOffMinDistance = 10
		sound.RollOffMode = Enum.RollOffMode.Linear
		sound.Parent = terrorFolder

		-- Store metadata as attributes
		sound:SetAttribute("MaxVolume", soundData.Volume or 0.6)
		sound:SetAttribute("IsChase", soundData.Chase == true)
		sound:SetAttribute("LayerIndex", i)
	end

	print("[TerrorSoundManager] Created terror sounds for", killerName, "in", character.Name)
	return true
end

-- Remove terror sounds from a character
function TerrorSoundManager:RemoveTerrorSounds(character)
	if not character then return end

	local terrorSounds = character:FindFirstChild("TerrorSounds")
	if terrorSounds then
		terrorSounds:Destroy()
		print("[TerrorSoundManager] Removed terror sounds from", character.Name)
	end
end

-- Remove terror sounds from a player
function TerrorSoundManager:RemoveTerrorSoundsFromPlayer(player)
	if not player or not player.Character then return end
	self:RemoveTerrorSounds(player.Character)
end

-- Remove terror sounds from all killers
function TerrorSoundManager:RemoveAllKillerTerrorSounds()
	local Teams = game:GetService("Teams")
	local killers = Teams.Killers:GetPlayers()

	for _, killer in ipairs(killers) do
		self:RemoveTerrorSoundsFromPlayer(killer)
	end

	print("[TerrorSoundManager] Removed all killer terror sounds")
end

return TerrorSoundManager