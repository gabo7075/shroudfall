local module = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local starterPlayer = game:GetService("StarterPlayer")
local teams = game:GetService("Teams")

function module.loadAsCharacter(player, characterName, characterSkin, team)
	player:SetAttribute("LastTeam", player.Team and player.Team.Name or "")

	local packet = replicatedStorage.Packets:FindFirstChild(team.Name):FindFirstChild(characterName)
	local model = packet:FindFirstChild(characterSkin):Clone()
	model.Name = "StarterCharacter"
	model.Parent = starterPlayer

	player.Team = team
	player:LoadCharacter()
	model:Destroy()

	local characterScript = packet.CharacterScript:Clone()
	characterScript.Parent = player.Character

	local ragdollScript = replicatedStorage.RagdollR6:Clone()
	ragdollScript.Parent = player.Character

	-- Add footstep sounds
	local groundStep = Instance.new("Sound")
	local grassStep = Instance.new("Sound")
	groundStep.SoundId = "rbxassetid://78754179999047"
	grassStep.SoundId = "rbxassetid://80932364310315"
	groundStep.Volume = 0.75
	grassStep.Volume = 0.75
	groundStep.Name = "GroundStep"
	grassStep.Name = "GrassStep"
	groundStep.Parent = player.Character:WaitForChild("HumanoidRootPart")
	grassStep.Parent = player.Character:WaitForChild("HumanoidRootPart")

	-- Set health
	player.Character:FindFirstChildWhichIsA("Humanoid").MaxHealth = characterScript:GetAttribute("Health")
	player.Character:FindFirstChildWhichIsA("Humanoid").Health = characterScript:GetAttribute("Health")

	-- Mark as killer if on killer team
	if team == teams.Killers then
		player.Character:SetAttribute("TerrorRig", true)
	end
end

return module