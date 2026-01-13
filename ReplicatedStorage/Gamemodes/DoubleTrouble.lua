local module = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local teams = game:GetService("Teams")

local remotes = replicatedStorage.Remotes
local mapLoader = require(replicatedStorage.Modules.MapLoader)
local characterLoader = require(replicatedStorage.Modules.CharacterLoader)
local timerManager = require(replicatedStorage.Modules.TimerManager)
local lmsManager = require(replicatedStorage.Modules.LMSManager)

local gameTime = 100 -- Double Trouble has 100 second timer

function module.start()
	print("Starting Double Trouble Gamemode")

	-- Select and announce map
	local mapName = mapLoader.selectRandomMap()
	local plrs = players:GetPlayers()

	for i = 1, #plrs do
		local plr = plrs[i]
		plr.PlayerGui:WaitForChild("TimeGui"):WaitForChild("TextLabel").Text = "Gamemode: Double Trouble | Selected Map: " .. mapName .. " | Loading Game..."

		-- Hide inventory GUI
		local inventoryGui = plr.PlayerGui:FindFirstChild("InventoryGui")
		if inventoryGui then
			inventoryGui.Enabled = false
		end
	end

	-- Load the map
	local spawns = mapLoader.loadMap(mapName)

	local currentPlayers = players:GetPlayers()
	if #currentPlayers > 2 then -- Need at least 3 players for Double Trouble
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

		-- Select TWO killers based on highest malice
		local killers = module.selectTwoKillers(currentPlayers)

		-- Load characters and spawn players
		for i = 1, #currentPlayers do
			if table.find(killers, currentPlayers[i]) then
				-- This player is a killer
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
				currentPlayers[i].leaderstats["Killer Chance"].Value = 3 -- Set to 3 instead of 1
			else
				-- This player is a survivor
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

		-- Show killer reveal GUI for BOTH killers
		module.showKillerReveal(killers)

		-- Check for LMS at start (2 killers vs 1 survivor)
		task.delay(1, function()
			module.checkForLMS()
		end)

		-- Start countdown
		timerManager.countDown(gameTime)
	end

	-- End game (cleanup will be handled by GameModule)
	local gameMod = require(replicatedStorage.GameModule)
	gameMod.endGame()
end

function module.selectTwoKillers(currentPlayers)
	-- Find the highest malice value
	local highestKillerChance = 0
	for i = 1, #currentPlayers do
		local plr = currentPlayers[i]
		if plr.leaderstats["Killer Chance"].Value > highestKillerChance then
			highestKillerChance = plr.leaderstats["Killer Chance"].Value
		end
	end

	-- Get all players with the highest malice
	local listOfPossibleKillers = {}
	for i = 1, #currentPlayers do
		local plr = currentPlayers[i]
		if plr.leaderstats["Killer Chance"].Value == highestKillerChance then
			table.insert(listOfPossibleKillers, plr)
		end
	end

	-- Select two killers
	local selectedKillers = {}

	if #listOfPossibleKillers >= 2 then
		-- Pick 2 random players from those with highest malice
		local firstIndex = math.random(1, #listOfPossibleKillers)
		table.insert(selectedKillers, listOfPossibleKillers[firstIndex])
		table.remove(listOfPossibleKillers, firstIndex)

		local secondIndex = math.random(1, #listOfPossibleKillers)
		table.insert(selectedKillers, listOfPossibleKillers[secondIndex])
	else
		-- Only one player with highest malice, pick them and then pick second highest
		table.insert(selectedKillers, listOfPossibleKillers[1])

		-- Find second highest malice
		local secondHighest = 0
		for i = 1, #currentPlayers do
			local plr = currentPlayers[i]
			if plr ~= selectedKillers[1] and plr.leaderstats["Killer Chance"].Value > secondHighest then
				secondHighest = plr.leaderstats["Killer Chance"].Value
			end
		end

		-- Get all players with second highest malice
		local secondList = {}
		for i = 1, #currentPlayers do
			local plr = currentPlayers[i]
			if plr ~= selectedKillers[1] and plr.leaderstats["Killer Chance"].Value == secondHighest then
				table.insert(secondList, plr)
			end
		end

		if #secondList > 0 then
			local randomIndex = math.random(1, #secondList)
			table.insert(selectedKillers, secondList[randomIndex])
		end
	end

	return selectedKillers
end

function module.showKillerReveal(killers)
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
		revealText.Position = UDim2.new(0,0,0.35,0)
		revealText.Text = ""
		revealText.TextColor3 = Color3.new(1,1,1)
		revealText.Font = Enum.Font.SourceSansBold
		revealText.TextScaled = true
		revealText.BackgroundTransparency = 1
		revealText.Parent = blackFrame

		-- First killer info
		local killer1Label = Instance.new("TextLabel")
		killer1Label.Size = UDim2.new(1,0,0.08,0)
		killer1Label.Position = UDim2.new(0,0,0.47,0)
		killer1Label.Text = ""
		killer1Label.TextColor3 = Color3.fromRGB(255,0,0)
		killer1Label.Font = Enum.Font.SourceSansBold
		killer1Label.TextScaled = true
		killer1Label.BackgroundTransparency = 1
		killer1Label.Parent = blackFrame

		local username1Label = Instance.new("TextLabel")
		username1Label.Size = UDim2.new(1,0,0.04,0)
		username1Label.Position = UDim2.new(0,0,0.55,0)
		username1Label.Text = ""
		username1Label.TextColor3 = Color3.fromRGB(255,255,255)
		username1Label.Font = Enum.Font.SourceSans
		username1Label.TextScaled = true
		username1Label.BackgroundTransparency = 1
		username1Label.Parent = blackFrame

		-- Second killer info
		local killer2Label = Instance.new("TextLabel")
		killer2Label.Size = UDim2.new(1,0,0.08,0)
		killer2Label.Position = UDim2.new(0,0,0.60,0)
		killer2Label.Text = ""
		killer2Label.TextColor3 = Color3.fromRGB(255,0,0)
		killer2Label.Font = Enum.Font.SourceSansBold
		killer2Label.TextScaled = true
		killer2Label.BackgroundTransparency = 1
		killer2Label.Parent = blackFrame

		local username2Label = Instance.new("TextLabel")
		username2Label.Size = UDim2.new(1,0,0.04,0)
		username2Label.Position = UDim2.new(0,0,0.68,0)
		username2Label.Text = ""
		username2Label.TextColor3 = Color3.fromRGB(255,255,255)
		username2Label.Font = Enum.Font.SourceSans
		username2Label.TextScaled = true
		username2Label.BackgroundTransparency = 1
		username2Label.Parent = blackFrame

		task.delay(0.5, function()
			revealText.Text = "This round's killers are..."
		end)
		task.delay(1.5, function()
			if killers[1] then
				killer1Label.Text = killers[1].EquippedKiller.Value
				username1Label.Text = killers[1].Name
			end
			if killers[2] then
				killer2Label.Text = killers[2].EquippedKiller.Value
				username2Label.Text = killers[2].Name
			end
		end)

		task.delay(4, function()
			gui:Destroy()
		end)
	end
end

function module.checkForLMS()
	local numOfSurvivors = teams.Survivors:GetPlayers()
	local numOfKillers = teams.Killers:GetPlayers()

	-- Double Trouble LMS: 2 killers vs 1 survivor OR any killers vs 1 survivor
	if #numOfSurvivors == 1 and #numOfKillers >= 1 then
		local survivor = numOfSurvivors[1]

		-- Fire remotes so all can see each other
		remotes.FindPlayers:FireClient(survivor, numOfKillers, 5)
		for i = 1, #numOfKillers do
			remotes.FindPlayers:FireClient(numOfKillers[i], numOfSurvivors, 5)
		end

		-- Double Trouble always plays its special LMS music, regardless of character matchups
		local lmsMusic = workspace.LMS:FindFirstChild("LMSDoubleTrouble")
		if lmsMusic then
			lmsMusic:Play()
		end

		-- Set timer to 44 seconds
		timerManager.setTime(44)

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
	-- Stop Double Trouble LMS music
	local lmsMusic = workspace.LMS:FindFirstChild("LMSDoubleTrouble")
	if lmsMusic and lmsMusic:IsA("Sound") then
		lmsMusic:Stop()
	end

	-- Also stop standard LMS tracks in case they were playing
	lmsManager.stopAllLMSMusic()
end

return module