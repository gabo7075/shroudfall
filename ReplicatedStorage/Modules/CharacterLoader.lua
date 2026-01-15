-- ModuleScript: ReplicatedStorage > Modules > CharacterLoader
local module = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local starterPlayer = game:GetService("StarterPlayer")
local teams = game:GetService("Teams")

-- Store active behavior instances
local activeBehaviors = {}

-- Helper to safely get config data
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

	-- Fallback to default if custom skin is missing
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

	-- 4. Get Config
	local configData = getConfigData(charFolder:FindFirstChild("Config"))

	-- 5. Setup Humanoid with Config Health
	local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		local health = configData.Health or 100
		humanoid.MaxHealth = health
		humanoid.Health = health
	end

	-- 6. Setup Ragdoll
	local ragdollScript = replicatedStorage:FindFirstChild("RagdollR6")
	if ragdollScript then
		ragdollScript:Clone().Parent = player.Character
	end

	-- 7. Audio (Standard setup)
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

	-- 8. Mark attributes
	if team == teams.Killers then
		player.Character:SetAttribute("TerrorRig", true)
		-- Set the character name for terror radius script to find Config
		player.Character:SetAttribute("CharacterName", characterName)
	end

	-- 9. Initialize Server-Side Behavior
	local behaviorModule = charFolder:FindFirstChild("Behavior")
	if behaviorModule and behaviorModule:IsA("ModuleScript") then
		-- Clean up any existing behavior for this player
		if activeBehaviors[player.UserId] then
			activeBehaviors[player.UserId]:Destroy()
			activeBehaviors[player.UserId] = nil
		end

		-- Create new behavior instance
		local success, behaviorClass = pcall(require, behaviorModule)
		if success and behaviorClass and behaviorClass.new then
			local behavior = behaviorClass.new(player, player.Character, configData)
			activeBehaviors[player.UserId] = behavior
			
			if team == teams.Killers then
				local TerrorSoundManager = require(game.ServerScriptService.TerrorSoundManager)
				TerrorSoundManager:CreateTerrorSounds(player.Character)
			end

			print("✓ Initialized behavior for", player.Name, "as", characterName)

			-- Cleanup on death
			humanoid.Died:Connect(function()
				if activeBehaviors[player.UserId] then
					activeBehaviors[player.UserId]:Destroy()
					activeBehaviors[player.UserId] = nil
				end
			end)
		else
			warn("Failed to initialize Behavior module:", behaviorClass)
		end
	else
		warn("No Behavior module found for", characterName, "- character may not function properly")
	end
end

-- Cleanup function for when player leaves
function module.cleanup(player)
	if activeBehaviors[player.UserId] then
		activeBehaviors[player.UserId]:Destroy()
		activeBehaviors[player.UserId] = nil
	end
end

return module