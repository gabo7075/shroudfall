-- Client Script for displaying reward popups
-- Place in StarterPlayer > StarterPlayerScripts

local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local player = players.LocalPlayer

local remotes = replicatedStorage.Remotes
local rewardModule = require(replicatedStorage.RewardModule)

-- Listen for reward notifications
remotes.GiveReward.OnClientEvent:Connect(function(message, money, malice)
	rewardModule.showRewardPopup(player, message, money, malice)
end)