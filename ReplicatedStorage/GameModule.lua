local module = {}
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local timerManager = require(replicatedStorage.Modules.TimerManager)
local mapLoader = require(replicatedStorage.Modules.MapLoader)
local characterLoader = require(replicatedStorage.Modules.CharacterLoader)

local currentGamemode = nil
local waiting = false
local lobbyTime = 20

-- Public API for other scripts
module.addTime = timerManager.addTime
module.setTime = timerManager.setTime
module.skipTime = timerManager.skipTime
module.pauseTime = timerManager.pauseTime
module.unpauseTime = timerManager.unpauseTime
module.findPlayers = require(replicatedStorage.Modules.LMSManager).findPlayers
module.highlightVictim = require(replicatedStorage.Modules.LMSManager).highlightVictim
module.loadMap = mapLoader.loadMap
module.loadAsCharacter = characterLoader.loadAsCharacter

function module.startGame(gamemodeName)
	-- If no gamemode specified, randomly select one
	if not gamemodeName then
		local plrs = players:GetPlayers()
		-- Need at least 3 players for Double Trouble
		if #plrs >= 3 then
			local random = math.random(1, 100)
			if random <= 30 then
				gamemodeName = "DoubleTrouble"
			else
				gamemodeName = "Standard"
			end
		else
			gamemodeName = "Standard"
		end
	end

	print("Starting Game with gamemode: " .. gamemodeName)
	workspace.LobbyMusic:Stop()

	-- Load the gamemode module
	local gamemodeModule = require(replicatedStorage.Gamemodes:FindFirstChild(gamemodeName))
	currentGamemode = gamemodeModule

	-- Start the gamemode
	gamemodeModule.start()
end

function module.endGame()
	local plrs = players:GetPlayers()

	-- Reset lighting
	mapLoader.resetLighting()

	if #plrs > 1 then
		waiting = false
		print("Ending Game")
		workspace.LobbyMusic:Play()

		-- Reset players
		for i = 1, #plrs do
			plrs[i]:SetAttribute("LastTeam", plrs[i].Team and plrs[i].Team.Name or "")
			plrs[i].Team = nil
			plrs[i]:LoadCharacter()
		end

		-- Clean up game debris
		local gameDebris = workspace.GameDebris:GetChildren()
		for i = 1, #gameDebris do
			gameDebris[i]:Destroy()
		end

		-- Stop all LMS sounds and cleanup gamemode (with error protection)
		pcall(function()
			if currentGamemode and currentGamemode.cleanup then
				if type(currentGamemode.cleanup) == "function" then
					currentGamemode.cleanup()
				end
			end
		end)

		-- Clear currentGamemode reference
		currentGamemode = nil

		-- Countdown to next game
		timerManager.countDown(lobbyTime)

		plrs = players:GetPlayers()
		if #plrs > 1 then
			module.startGame()
		else
			module.endGame()
		end
		task.wait()
	else
		if waiting == false then
			waiting = true
			workspace.LobbyMusic:Play()

			for i = 1, #plrs do
				plrs[i].Team = nil
				plrs[i]:LoadCharacter()
				plrs[i].PlayerGui:WaitForChild("TimeGui"):WaitForChild("TextLabel").Text = "Waiting for players"
			end

			local gameDebris = workspace.GameDebris:GetChildren()
			for i = 1, #gameDebris do
				gameDebris[i]:Destroy()
			end

			-- Clear currentGamemode reference in waiting state too
			currentGamemode = nil
		end

		task.wait(10)
		module.endGame()
	end
end

return module