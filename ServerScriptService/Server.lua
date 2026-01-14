local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local debris = game:GetService("Debris")
local teams = game:GetService("Teams")
local starterPlayer = game:GetService("StarterPlayer")

local remotes = replicatedStorage.Remotes
local packets = replicatedStorage.Packets

local gameMod = require(replicatedStorage.GameModule)
local lmsManager = require(replicatedStorage.Modules.LMSManager)
local timerManager = require(replicatedStorage.Modules.TimerManager)

starterPlayer.CameraMaxZoomDistance = 30
starterPlayer.EnableMouseLockOption = false

players.PlayerAdded:Connect(function(plr)
	-- Create leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = plr

	local malice = Instance.new("NumberValue")
	malice.Value = 1
	malice.Parent = leaderstats
	malice.Name = "Killer Chance"

	plr.CharacterAdded:Connect(function(char)
		-- Handle death
		char:FindFirstChildWhichIsA("Humanoid").Died:Connect(function()
			if plr.Team == teams.Survivors then
				plr.Team = nil
				local numOfSurvivors = teams.Survivors:GetPlayers()
				local numOfKillers = teams.Killers:GetPlayers()

				if #numOfSurvivors > 1 then
					gameMod.addTime(30)
				elseif #numOfSurvivors == 1 and #numOfKillers >= 1 then
					local survivor = numOfSurvivors[1]

					-- Fire remotes
					remotes.FindPlayers:FireClient(survivor, numOfKillers, 5)
					for i = 1, #numOfKillers do
						remotes.FindPlayers:FireClient(numOfKillers[i], numOfSurvivors, 5)
					end

					-- Check if it's Double Trouble (2+ killers) or Standard (1 killer)
					if #numOfKillers >= 2 then
						-- Double Trouble LMS
						local lmsMusic = workspace.LMS:FindFirstChild("LMSDoubleTrouble")
						if lmsMusic then
							lmsMusic:Play()
						end
						if remotes:FindFirstChild("StopTerrorSounds") then
							remotes.StopTerrorSounds:FireAllClients(true)
						end
						timerManager.setTime(44)
					else
						-- Standard LMS with 1 killer
						local killer = numOfKillers[1]
						local musicName, newTime = lmsManager.checkLMSConditions(killer, survivor)
						local lmsMusic = workspace.LMS:FindFirstChild(musicName)
						if lmsMusic then
							lmsMusic:Play()
						end
						if remotes:FindFirstChild("StopTerrorSounds") then
							remotes.StopTerrorSounds:FireAllClients(true)
						end
						timerManager.setTime(newTime)
					end

					local currentMap = workspace.GameDebris:FindFirstChild("CurrentMap")
					if currentMap then
						local mapMusic = currentMap:FindFirstChild("Music")
						if mapMusic then
							mapMusic:Destroy()
						end
					end
				elseif #numOfSurvivors == 0 then
					gameMod.setTime(0)
				end

			elseif plr.Team == teams.Killers then
				plr.Team = nil
				local numOfKillers = teams.Killers:GetPlayers()
				if #numOfKillers == 0 then
					gameMod.setTime(0)
				end
			else
				plr.Team = nil
			end
		end)
	end)
end)

players.PlayerRemoving:Connect(function(plr)
	local numOfSurvivors = teams.Survivors:GetPlayers()
	local numOfKillers = teams.Killers:GetPlayers()
	local totalPlayers = (#numOfSurvivors + #numOfKillers)

	if totalPlayers <= 1 then
		gameMod.setTime(0)
	else
		if #numOfSurvivors > 1 then
			gameMod.addTime(30)
		elseif #numOfSurvivors == 1 and #numOfKillers >= 1 then
			-- Show players to each other
			remotes.FindPlayers:FireClient(numOfSurvivors[1], numOfKillers, 5)
			for i = 1, #numOfKillers do
				remotes.FindPlayers:FireClient(numOfKillers[i], numOfSurvivors, 5)
			end

			-- Check if Double Trouble or Standard
			if #numOfKillers >= 2 then
				-- Double Trouble LMS
				gameMod.setTime(44)
				local lmsMusic = workspace.LMS:FindFirstChild("LMSDoubleTrouble")
				if lmsMusic then
					lmsMusic:Play()
				end
				if remotes:FindFirstChild("StopTerrorSounds") then
					remotes.StopTerrorSounds:FireAllClients(true)
				end
			else
				-- Standard LMS
				gameMod.setTime(75)
			end

			local currentMap = workspace.GameDebris:FindFirstChild("CurrentMap")
			if currentMap then
				local mapMusic = currentMap:FindFirstChild("Music")
				if mapMusic then
					mapMusic:Destroy()
				end
			end
		elseif #numOfSurvivors == 0 then
			gameMod.setTime(0)
		end
	end
end)

-- Damage handling
remotes.Damage.OnServerEvent:Connect(function(plr, killer, checking, victim, damage, stunTime, source)
	if checking then
		if players:GetPlayerFromCharacter(victim) then
			remotes.Damage:FireClient(players:GetPlayerFromCharacter(victim), killer, damage, stunTime, source)
		else
			-- Check if NPC is immune to attacker's team
			local immuneTeam = victim:GetAttribute("ImmuneToTeam")
			if immuneTeam and plr.Team and plr.Team.Name == immuneTeam then
				return
			end
			victim:FindFirstChildWhichIsA("Humanoid").Health -= damage
			remotes.HitIndicator:FireClient(killer, victim.HumanoidRootPart.Position, damage)
		end
	else
		if victim then
			remotes.Connect:FireClient(killer, victim, source)
			if victim:FindFirstChildWhichIsA("Humanoid").Health > 0 then
				remotes.HitIndicator:FireClient(killer, victim.HumanoidRootPart.Position, damage)
			end
			victim:FindFirstChildWhichIsA("Humanoid").Health -= damage
		else
			remotes.Connect:FireClient(killer, plr.Character, source)
			plr.Character:FindFirstChildWhichIsA("Humanoid").Health -= damage
		end
	end
end)

-- Heal handling
remotes.Heal.OnServerEvent:Connect(function(plr, amount)
	local char = plr.Character
	if not char then return end
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if not hum then return end
	if typeof(amount) ~= "number" or amount <= 0 or amount > 100 then
		return
	end
	hum.Health = math.clamp(hum.Health + amount, 0, hum.MaxHealth)
end)

remotes.SoftDamage.OnServerEvent:Connect(function(plr, char, damage)
	char:FindFirstChildWhichIsA("Humanoid").Health -= damage
end)

remotes.PlaySound.OnServerEvent:Connect(function(plr, sound, bool)
	if bool == true or bool == nil then
		sound:Play()
	else
		sound:Stop()
	end
end)

remotes.ShowObj.OnServerEvent:Connect(function(plr, obj, bool)
	obj.Transparency = (bool == true or bool == nil) and 0 or 1
end)

-- Status effects
remotes.StatusEffects.Invisible.OnServerEvent:Connect(function(plr, parts, amount, bool)
	if bool or bool == nil then
		for i = 1, #parts do
			if parts[i] and parts[i].Parent then
				parts[i].Transparency += amount / 5
			end
		end
	else
		for i = 1, #parts do
			if parts[i] and parts[i].Parent then
				parts[i].Transparency -= amount / 5
			end
		end
	end
end)

remotes.StatusEffects.Poison.OnServerEvent:Connect(function(plr, char, bool)
	if bool or bool == nil then
		local highlight = Instance.new("Highlight")
		highlight.OutlineTransparency = 1
		highlight.FillTransparency = 0.9
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.FillColor = Color3.new(0, 1, 0)
		highlight.Name = "PoisonHighlight"
		highlight.Parent = char
	else
		local poisonHighlight = char:FindFirstChild("PoisonHighlight")
		if poisonHighlight then
			poisonHighlight:Destroy()
		end
	end
end)

remotes.StatusEffects.Burn.OnServerEvent:Connect(function(plr, char, length)
	local fire = Instance.new("Fire")
	fire.Parent = char:WaitForChild("HumanoidRootPart")
	task.wait(length)
	fire.Enabled = false
	debris:AddItem(fire, 2)
end)

remotes.StatusEffects.Infected.OnServerEvent:Connect(function(plr, char, bool)
	if bool or bool == nil then
		local highlight = Instance.new("Highlight")
		highlight.OutlineTransparency = 1
		highlight.FillTransparency = 0.9
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.FillColor = Color3.new(1, 0, 0)
		highlight.Name = "InfectedHighlight"
		highlight.Parent = char
	else
		local infectedHighlight = char:FindFirstChild("InfectedHighlight")
		if infectedHighlight then
			infectedHighlight:Destroy()
		end
	end
end)

remotes.StatusEffects.Undetectable.OnServerEvent:Connect(function(plr, targetChar, deltaAmount)
	if plr.Character ~= targetChar then return end
	local current = targetChar:GetAttribute("Undetectable") or 0
	targetChar:SetAttribute("Undetectable", math.max(0, current + deltaAmount))
end)

-- Speed/Slow: Clients request server to modify IntendedWalkSpeed on THEIR character
remotes.StatusEffects.Speed.OnServerEvent:Connect(function(plr, targetChar, deltaAmount)
	if not targetChar or not targetChar.Parent then return end
	if plr.Character ~= targetChar then return end
	local delta = tonumber(deltaAmount) or 0
	local current = targetChar:GetAttribute("IntendedWalkSpeed") or 16
	targetChar:SetAttribute("IntendedWalkSpeed", math.max(0, current + delta))
end)

remotes.StatusEffects.Slow.OnServerEvent:Connect(function(plr, targetChar, deltaAmount)
	if not targetChar or not targetChar.Parent then return end
	if plr.Character ~= targetChar then return end
	local delta = tonumber(deltaAmount) or 0
	local current = targetChar:GetAttribute("IntendedWalkSpeed") or 16
	targetChar:SetAttribute("IntendedWalkSpeed", math.max(0, current + delta))
end)

-- Generic attribute setter (validated): remotes.StatusEffects.SetAttribute
remotes.StatusEffects.SetAttribute.OnServerEvent:Connect(function(plr, targetChar, attrName, value)
	if not targetChar or not targetChar.Parent then return end
	if plr.Character ~= targetChar then return end
	if type(attrName) ~= "string" then return end
	-- Only allow primitive types for safety
	if type(value) ~= "number" and type(value) ~= "boolean" and type(value) ~= "string" then return end
	targetChar:SetAttribute(attrName, value)
end)

remotes.Delete.OnServerEvent:Connect(function(plr, obj)
	obj:Destroy()
end)

remotes.GiveEffect.OnServerEvent:Connect(function(plr, victim, name, length, amount, visible)
	if type(victim) == "userdata" then
		remotes.GiveEffect:FireClient(victim, name, length, amount, visible)
	end
end)

-- Knockback handling
remotes.DamageKnockback.OnServerEvent:Connect(function(plr, victim, direction, power)
	if power <= 0 then return end

	local attackerChar = plr.Character
	if not attackerChar or not attackerChar:FindFirstChild("HumanoidRootPart") then 
		return 
	end

	if not victim or not victim.Parent or not victim:FindFirstChild("HumanoidRootPart") or not victim:FindFirstChildWhichIsA("Humanoid") then 
		return 
	end

	local dist = (victim.HumanoidRootPart.Position - attackerChar.HumanoidRootPart.Position).Magnitude
	if dist > 15 then 
		return
	end

	local victimPlayer = players:GetPlayerFromCharacter(victim)
	local hrp = victim.HumanoidRootPart

	-- Clean previous knockback
	for _, force in ipairs(hrp:GetChildren()) do
		if force:IsA("LinearVelocity") or force:IsA("VectorForce") then
			force:Destroy()
		end
	end

	-- Remove ownership temporarily
	if victimPlayer then
		hrp:SetNetworkOwner(nil)
	end

	hrp.AssemblyAngularVelocity = Vector3.zero

	-- Create attachment and force
	local attachment = Instance.new("Attachment", hrp)
	local knockback = Instance.new("LinearVelocity")
	knockback.Attachment0 = attachment
	knockback.MaxForce = math.huge
	local flatDir = Vector3.new(direction.X, 0, direction.Z).Unit
	knockback.VectorVelocity = flatDir * power
	knockback.Parent = hrp

	-- Cleanup
	task.delay(0.25, function()
		if knockback then knockback:Destroy() end
		if attachment then attachment:Destroy() end

		if victimPlayer and hrp and hrp.Parent and hrp:IsDescendantOf(workspace) then
			pcall(function()
				hrp:SetNetworkOwner(victimPlayer)
			end)
		end
	end)
end)

-- Handle FindPlayers remote for highlighting
remotes.FindPlayers.OnServerEvent:Connect(function(plr, targets, duration)
	if type(targets) == "table" then
		lmsManager.findPlayers(targets, duration)
	end
end)

-- Start the game
gameMod.endGame()