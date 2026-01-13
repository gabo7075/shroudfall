local module = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local teams = game:GetService("Teams")
local serverStorage = game:GetService("ServerStorage")

local remotes = replicatedStorage.Remotes
local gameMod = require(replicatedStorage.GameModule)
local mapLoader = require(replicatedStorage.Modules.MapLoader)
local characterLoader = require(replicatedStorage.Modules.CharacterLoader)
local timerManager = require(replicatedStorage.Modules.TimerManager)
local lmsManager = require(replicatedStorage.Modules.LMSManager)

local gameTime = 240

function module.start()
	print("Starting Standard Gamemode")

	-- Select and announce map
	local mapName = mapLoader.selectRandomMap()
	local plrs = players:GetPlayers()

	for i = 1, #plrs do
		local plr = plrs[i]
		plr.PlayerGui:WaitForChild("TimeGui"):WaitForChild("TextLabel").Text = "Gamemode: Standard | Selected Map: " .. mapName .. " | Loading Game..."

		-- Hide inventory GUI
		local inventoryGui = plr.PlayerGui:FindFirstChild("InventoryGui")
		if inventoryGui then
			inventoryGui.Enabled = false
		end
	end

	-- Load the map
	local spawns = mapLoader.loadMap(mapName)

	local currentPlayers = players:GetPlayers()
	if #currentPlayers > 1 then
		-- Separate spawns
		local killerSpawns = {}
		local survivorSpawns = {}
		for i = 1, #spawns do
			if spawns[i].Name == "Survivor" then
				table.insert(survivorSpawns, spawns[i])
			elseif spawns[i].Name == "Killer" then
				table.insert(killerSpawns, spawns[i])
			end
		end

		-- Select killer based on highest malice (Killer Chance)
		local killer = module.selectKiller(currentPlayers)

		-- Load characters and spawn players
		for i = 1, #currentPlayers do
			if currentPlayers[i] == killer then
				characterLoader.loadAsCharacter(
					currentPlayers[i], 
					currentPlayers[i].EquippedKiller.Value, 
					currentPlayers[i].EquippedKillerSkin.Value, 
					teams.Killers
				)
				local char = currentPlayers[i].Character
				local hum = char:FindFirstChildWhichIsA("Humanoid")
				local randomSpawn = math.random(1, #killerSpawns)
				hum.RootPart.CFrame = killerSpawns[randomSpawn].CFrame
				currentPlayers[i].leaderstats["Killer Chance"].Value = 1
			else
				characterLoader.loadAsCharacter(
					currentPlayers[i], 
					currentPlayers[i].EquippedSurvivor.Value, 
					currentPlayers[i].EquippedSurvivorSkin.Value, 
					teams.Survivors
				)
				local char = currentPlayers[i].Character
				local hum = char:FindFirstChildWhichIsA("Humanoid")
				local randomSpawn = math.random(1, #survivorSpawns)
				hum.RootPart.CFrame = survivorSpawns[randomSpawn].CFrame
				currentPlayers[i].leaderstats["Killer Chance"].Value += 1
			end
		end

		-- Show killer reveal GUI
		module.showKillerReveal(killer)

		-- Check for LMS at start
		task.delay(1, function()
			module.checkForLMS()
		end)

		-- Start countdown
		timerManager.countDown(gameTime)
	end

	-- End game (cleanup will be handled by GameModule)
	gameMod.endGame()
end

function module.selectKiller(currentPlayers)
	local highestKillerChance = 0
	for i = 1, #currentPlayers do
		local plr = currentPlayers[i]
		if plr.leaderstats["Killer Chance"].Value > highestKillerChance then
			highestKillerChance = plr.leaderstats["Killer Chance"].Value
		end
	end

	local listOfPossibleKillers = {}
	for i = 1, #currentPlayers do
		local plr = currentPlayers[i]
		if plr.leaderstats["Killer Chance"].Value == highestKillerChance then
			table.insert(listOfPossibleKillers, plr)
		end
	end

	local killerNum = math.random(1, #listOfPossibleKillers)
	return listOfPossibleKillers[killerNum]
end

function module.showKillerReveal(killer)
	for i, plr in ipairs(players:GetPlayers()) do
		local gui = Instance.new("ScreenGui")
		gui.Name = "KillerRevealGui"
		gui.ResetOnSpawn = false
		gui.Parent = plr.PlayerGui
		gui.DisplayOrder = 999

		local blackFrame = Instance.new("Frame")
		blackFrame.Size = UDim2.new(1,0,1,0)
		blackFrame.Position = UDim2.new(0,0,0,0)
		blackFrame.BackgroundColor3 = Color3.new(0,0,0)
		blackFrame.BackgroundTransparency = 0
		blackFrame.Parent = gui

		local revealText = Instance.new("TextLabel")
		revealText.Size = UDim2.new(1,0,0.1,0)
		revealText.Position = UDim2.new(0,0,0.4,0)
		revealText.Text = ""
		revealText.TextColor3 = Color3.new(1,1,1)
		revealText.Font = Enum.Font.SourceSansBold
		revealText.TextScaled = true
		revealText.BackgroundTransparency = 1
		revealText.Parent = blackFrame

		local killerLabel = Instance.new("TextLabel")
		killerLabel.Size = UDim2.new(1,0,0.1,0)
		killerLabel.Position = UDim2.new(0,0,0.5,0)
		killerLabel.Text = ""
		killerLabel.TextColor3 = Color3.fromRGB(255,0,0)
		killerLabel.Font = Enum.Font.SourceSansBold
		killerLabel.TextScaled = true
		killerLabel.BackgroundTransparency = 1
		killerLabel.Parent = blackFrame

		local usernameLabel = Instance.new("TextLabel")
		usernameLabel.Size = UDim2.new(1,0,0.05,0)
		usernameLabel.Position = UDim2.new(0,0,0.6,0)
		usernameLabel.Text = ""
		usernameLabel.TextColor3 = Color3.fromRGB(255,255,255)
		usernameLabel.Font = Enum.Font.SourceSans
		usernameLabel.TextScaled = true
		usernameLabel.BackgroundTransparency = 1
		usernameLabel.Parent = blackFrame

		task.delay(0.5, function()
			revealText.Text = "This round's killer is..."
		end)
		task.delay(1.5, function()
			killerLabel.Text = killer.EquippedKiller.Value
			usernameLabel.Text = killer.Name
		end)

		task.delay(4, function()
			gui:Destroy()
		end)
	end
end

function module.checkForLMS()
	local numOfSurvivors = teams.Survivors:GetPlayers()
	local numOfKillers = teams.Killers:GetPlayers()

	if #numOfSurvivors == 1 and #numOfKillers == 1 then
		local survivor = numOfSurvivors[1]
		local killer = numOfKillers[1]

		-- Fire remotes so both can see each other
		remotes.FindPlayers:FireClient(survivor, numOfKillers, 5)
		remotes.FindPlayers:FireClient(killer, numOfSurvivors, 5)

		-- Get LMS music and time based on conditions
		local musicName, newTime = lmsManager.checkLMSConditions(killer, survivor)

		-- Play the appropriate music
		local lmsMusic = workspace.LMS:FindFirstChild(musicName)
		if lmsMusic then
			lmsMusic:Play()
		end

		-- Set the new time
		timerManager.setTime(newTime)

		-- Remove terror sounds and map music
		if killer.Character then
			local terrorSounds = killer.Character:FindFirstChild("TerrorSounds")
			if terrorSounds then
				terrorSounds:Destroy()
			end
		end

		local currentMap = workspace.GameDebris:FindFirstChild("CurrentMap")
		if currentMap then
			local mapMusic = currentMap:FindFirstChild("Music")
			if mapMusic then
				mapMusic:Destroy()
			end
		end
	end
end

function module.cleanup()
	lmsManager.stopAllLMSMusic()
end

return module