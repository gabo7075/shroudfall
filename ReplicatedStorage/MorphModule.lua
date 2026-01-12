-- Independent Morph System
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local module = {}

-- Use the centralized CharacterLoader
local characterLoader = require(ReplicatedStorage.Modules.CharacterLoader)

local function getPlayerTeam(player)
	if player.Team == Teams.Killers then
		return "Killers"
	elseif player.Team == Teams.Survivors then
		return "Survivors"
	else
		return nil
	end
end

function module.morphPlayer(player, desiredTeam)
	if not player then return end

	local team
	local characterName
	local characterSkin

	if desiredTeam == "Killers" then
		if player:FindFirstChild("EquippedKiller") and player:FindFirstChild("EquippedKillerSkin") then
			team = Teams.Killers
			characterName = player.EquippedKiller.Value
			characterSkin = player.EquippedKillerSkin.Value
		else
			warn("Player has no equipped killer!")
			return
		end
	elseif desiredTeam == "Survivors" then
		if player:FindFirstChild("EquippedSurvivor") and player:FindFirstChild("EquippedSurvivorSkin") then
			team = Teams.Survivors
			characterName = player.EquippedSurvivor.Value
			characterSkin = player.EquippedSurvivorSkin.Value
		else
			warn("Player has no equipped survivor!")
			return
		end
	else
		warn("Invalid team!")
		return
	end

	-- Use the centralized character loader
	characterLoader.loadAsCharacter(player, characterName, characterSkin, team)

	print(player.Name.." has been morphed into "..characterName.." ("..characterSkin..")")
end

return module