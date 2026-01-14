-- Server Script for handling default rewards
-- Place in ServerScriptService
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local teams = game:GetService("Teams")
local remotes = replicatedStorage.Remotes
local rewardModule = require(replicatedStorage.RewardModule)

-- Create reward remote if it doesn't exist
local rewardRemote = remotes:FindFirstChild("GiveReward")
if not rewardRemote then
	rewardRemote = Instance.new("RemoteEvent")
	rewardRemote.Name = "GiveReward"
	rewardRemote.Parent = remotes
end

-- Function to give reward to player
local function giveReward(player, rewardType)
	if not player or not player.Parent then return end
	local reward = rewardModule.DefaultRewards[rewardType]
	if not reward then return end

	-- Ensure leaderstats folder exists
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	-- Add or create Money IntValue
	local moneyVal = leaderstats:FindFirstChild("Money")
	if not moneyVal then
		moneyVal = Instance.new("IntValue")
		moneyVal.Name = "Money"
		moneyVal.Value = 0
		moneyVal.Parent = leaderstats
	end
	moneyVal.Value = moneyVal.Value + (reward.money or 0)

	-- Add or create Killer Chance (malice) value if applicable
	local maliceVal = leaderstats:FindFirstChild("Killer Chance")
	if not maliceVal then
		maliceVal = Instance.new("NumberValue")
		maliceVal.Name = "Killer Chance"
		maliceVal.Value = 0
		maliceVal.Parent = leaderstats
	end
	maliceVal.Value = maliceVal.Value + (reward.malice or 0)

	-- Show popup to player
	rewardRemote:FireClient(player, reward.message, reward.money, reward.malice)
end

-- Track last attacker for each character
local lastAttacker = {}

-- Handle survivor deaths
players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		local hum = char:FindFirstChildWhichIsA("Humanoid")
		if hum then
			hum.Died:Connect(function()
				-- Check if a survivor died
				local lastTeamName = plr:GetAttribute("LastTeam")
				local lastTeam = lastTeamName and teams:FindFirstChild(lastTeamName)
				if lastTeam == teams.Survivors then
					local killer = lastAttacker[char]
					if killer and killer.Parent and killer.Team == teams.Killers then
						giveReward(killer, "KilledSurvivor")
					end
				end
			end)
		end
	end)
end)

-- Handle survivor disconnections
players.PlayerRemoving:Connect(function(plr)
	-- Check if survivor disconnected during game
	if plr.Team == teams.Survivors and plr.Character then
		local killer = lastAttacker[plr.Character]
		if killer and killer.Parent and killer.Team == teams.Killers then
			giveReward(killer, "SurvivorDisconnected")
		end
		-- Clean up
		if plr.Character then
			lastAttacker[plr.Character] = nil
		end
	end
end)

-- ✅ FIXED: Handle custom AND default rewards from client
remotes.GiveReward.OnServerEvent:Connect(function(player, messageOrType, money, malice)
	-- Check if this is a default reward request (just a string)
	if type(messageOrType) == "string" and not money and not malice then
		-- It's a default reward type like "SurvivorHit"
		giveReward(player, messageOrType)
		return
	end

	-- Otherwise, it's a custom reward with explicit values
	if type(messageOrType) ~= "string" or type(money) ~= "number" or type(malice) ~= "number" then
		return
	end

	-- Clamp values to prevent exploits
	money = math.clamp(money, 0, 1000)
	malice = math.clamp(malice, 0, 10)

	-- Ensure leaderstats exists
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	-- Ensure Money exists
	local moneyValue = leaderstats:FindFirstChild("Money")
	if not moneyValue then
		moneyValue = Instance.new("IntValue")
		moneyValue.Name = "Money"
		moneyValue.Value = 0
		moneyValue.Parent = leaderstats
	end
	moneyValue.Value = moneyValue.Value + money

	-- Ensure Killer Chance exists and add malice
	local maliceValue = leaderstats:FindFirstChild("Killer Chance")
	if not maliceValue then
		maliceValue = Instance.new("NumberValue")
		maliceValue.Name = "Killer Chance"
		maliceValue.Value = 0
		maliceValue.Parent = leaderstats
	end
	maliceValue.Value = maliceValue.Value + malice

	-- Show popup
	rewardRemote:FireClient(player, messageOrType, money, malice)
end)