-- ModuleScript: ReplicatedStorage > Modules > CharacterLoader
local module = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local starterPlayer = game:GetService("StarterPlayer")
local teams = game:GetService("Teams")

-- Helper to safely get config data without requiring the whole module if not needed
local function getConfigData(configModule)
	if configModule and configModule:IsA("ModuleScript") then
		local s, d = pcall(require, configModule)
		if s then return d end
	end
	return {}
end

function module.loadAsCharacter(player, characterName, characterSkin, team)
	if not player or not team then return end

	player:SetAttribute("LastTeam", player.Team and player.Team.Name or "")

	-- 1. Find the Character Folder
	local teamFolder = replicatedStorage.Packets:FindFirstChild(team.Name)
	if not teamFolder then warn("Team folder not found in Packets") return end

	local charFolder = teamFolder:FindFirstChild(characterName)
	if not charFolder then warn("Character folder not found: " .. characterName) return end

	-- 2. Determine which Model to Clone
	local sourceModel = nil

	if characterSkin == "Default" or characterSkin == nil then
		sourceModel = charFolder:FindFirstChild("Default")
	else
		local skinsFolder = charFolder:FindFirstChild("Skins")
		if skinsFolder then
			local specificSkinFolder = skinsFolder:FindFirstChild(characterSkin)
			if specificSkinFolder then
				sourceModel = specificSkinFolder:FindFirstChild("Rig")
			end
		end
	end

	-- Fallback to default if custom skin is missing (prevents invisible players)
	if not sourceModel then
		warn("Skin model not found ("..tostring(characterSkin).."), reverting to Default.")
		sourceModel = charFolder:FindFirstChild("Default")
	end

	if not sourceModel then warn("CRITICAL: No character model found for " .. characterName) return end

	-- 3. Clone and Setup
	local model = sourceModel:Clone()
	model.Name = "StarterCharacter"
	model.Parent = starterPlayer

	player.Team = team
	player:LoadCharacter() -- This loads the 'StarterCharacter' we just put in StarterPlayer
	model:Destroy() -- Clean up from StarterPlayer immediately

	-- 4. Handle Scripts and Logic
	local characterScript = charFolder:FindFirstChild("CharacterScript")
	if characterScript then
		local newScript = characterScript:Clone()
		newScript.Parent = player.Character

		-- Optional: Read health from Config instead of Attribute
		local configData = getConfigData(charFolder:FindFirstChild("Config"))
		local health = configData.Health or characterScript:GetAttribute("Health") or 100

		local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			humanoid.MaxHealth = health
			humanoid.Health = health
		end
	end

	local ragdollScript = replicatedStorage:FindFirstChild("RagdollR6")
	if ragdollScript then
		ragdollScript:Clone().Parent = player.Character
	end

	-- 5. Audio (Standard setup)
	local hrp = player.Character:WaitForChild("HumanoidRootPart", 5)
	if hrp then
		local groundStep = Instance.new("Sound")
		local grassStep = Instance.new("Sound")
		groundStep.SoundId = "rbxassetid://78754179999047"
		grassStep.SoundId = "rbxassetid://80932364310315"
		groundStep.Volume = 0.75
		grassStep.Volume = 0.75
		groundStep.Name = "GroundStep"
		grassStep.Name = "GrassStep"
		groundStep.Parent = hrp
		grassStep.Parent = hrp
	end

	-- 6. Mark attributes
	if team == teams.Killers then
		player.Character:SetAttribute("TerrorRig", true)
	end
end

return module