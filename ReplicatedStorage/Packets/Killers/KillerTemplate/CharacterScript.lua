--Variables
local players = game:GetService("Players")
local uis = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local debris = game:GetService("Debris")
local teams = game:GetService("Teams")

local remotes = replicatedStorage.Remotes
local clones = replicatedStorage.Clones

local plr = players.LocalPlayer
local char = plr.Character
local hum = char:FindFirstChildWhichIsA("Humanoid")
local mouse = plr:GetMouse()
local camera = workspace.CurrentCamera

local playerGui = plr.PlayerGui
local gameGui = playerGui.GameGui
local barsGui = gameGui.Bars

local gameMod = require(replicatedStorage.GameModule)
local hitboxMod = require(replicatedStorage.HitBox)
local hitIndicator = require(replicatedStorage.HitIndicator)
local guiMod = require(gameGui.GuiModule)
local statusMod = require(gameGui.StatusEffectsModule)
local rewardModule = require(replicatedStorage.RewardModule)

char:SetAttribute("CanMove", true)
char:SetAttribute("ActiveTool", false)
char:SetAttribute("CanRun", true)
char:SetAttribute("IntendedWalkSpeed", script:GetAttribute("WalkSpeed"))
hum.JumpPower = 0
hum.WalkSpeed = script:GetAttribute("WalkSpeed")

running = false
wantsToRun = false
canGainStamina = true
stamina = tonumber(script:GetAttribute("Stamina"))
canUseAbilities = true

CanBeStunned = true
Stunned = false
nearSurvivor = false

ability1CoolDown = false
ability2CoolDown = false
ability3CoolDown = false
ability4CoolDown = false

local defaultIds = {
	Idle = "rbxassetid://134755063723435",
	Walk = "rbxassetid://131769059732662",
	Run = "rbxassetid://124573520877102",
	StunStart = "rbxassetid://120826985941169",
	StunLoop = "rbxassetid://74533868293322",
	StunEnd = "rbxassetid://81361634197851",
	Punch = "rbxassetid://136672494666856",
}

local animIds = defaultIds

local function createAndLoadAnim(id, priority)
	local animObj = Instance.new("Animation")
	animObj.AnimationId = id
	local track = hum:LoadAnimation(animObj)
	track.Priority = priority or Enum.AnimationPriority.Idle
	return track
end

local idleAnim = createAndLoadAnim(animIds.Idle)
local walkAnim = createAndLoadAnim(animIds.Walk)
local runAnim = createAndLoadAnim(animIds.Run)

local stunStart = createAndLoadAnim(animIds.StunStart, Enum.AnimationPriority.Action4)
local stunLoop = createAndLoadAnim(animIds.StunLoop, Enum.AnimationPriority.Action3)
local stunEnd = createAndLoadAnim(animIds.StunEnd, Enum.AnimationPriority.Action4)

local punch = createAndLoadAnim(animIds.Punch, Enum.AnimationPriority.Action)

--Creating Abilities
local ability1Name = "Punch"
local ability2Name = "Effect"
local ability3Name = "Punch 2"
local ability4Name = "Locate"

local ability1KeyCode = "M1"
local ability2KeyCode = Enum.KeyCode.Q
local ability3KeyCode = Enum.KeyCode.E
local ability4KeyCode = Enum.KeyCode.R

local ability1CooldownTime = 1.6
local ability2CooldownTime = 4
local ability3CooldownTime = 1.6
local ability4CooldownTime = 7

local ability1Damage = 25 --m1
local ability3Damage = 30

local ability1Knockback = 15
local ability3Knockback = 30

-- Custom reward configuration for this character
local CUSTOM_REWARDS = {
	Ability3Hit = {
		money = 60,
		malice = 0,
		messageTemplate = "Attacked survivor with special ability as %s."
	}
}

local function giveCustomReward(rewardType)
	local reward = CUSTOM_REWARDS[rewardType]
	if not reward then return end

	-- Get killer name from equipped killer
	local killerName = plr.EquippedKiller.Value or "Killer"
	local message = string.format(reward.messageTemplate, killerName)

	-- Request reward from server
	remotes.GiveReward:FireServer(message, reward.money, reward.malice)
end

if uis.GamepadEnabled then
	ability1KeyCode = Enum.KeyCode.ButtonY
	ability2KeyCode = Enum.KeyCode.ButtonB
	ability3KeyCode = Enum.KeyCode.ButtonA
	ability4KeyCode = Enum.KeyCode.ButtonX
end

local ability1 = guiMod.createAbilityGui(ability1Name, "rbxassetid://123352469952776", ability1KeyCode)
local ability2 = guiMod.createAbilityGui(ability2Name, "rbxassetid://82229308135638", ability2KeyCode)
local ability3 = guiMod.createAbilityGui(ability3Name, "rbxassetid://106226036311010", ability3KeyCode)
local ability4 = guiMod.createAbilityGui(ability4Name, "rbxassetid://77080976212074", ability4KeyCode)

--Functions
remotes.Damage.OnClientEvent:Connect(function(killer, damage, stunTime)
	if gameGui.Stats.Weakness.Value > 0 then
		damage = math.round(damage * ((gameGui.Stats.Weakness.Value / 5) + 1))
	end
	if gameGui.Stats.Resistance.Value > 0 then
		damage = math.round(damage / ((gameGui.Stats.Resistance.Value / 5) + 1))
	end
	remotes.Damage:FireServer(killer, false, char, damage, stunTime)

	if stunTime and CanBeStunned then
		Stunned = true
		CanBeStunned = false
		stunStart:Play()
		stunLoop:Play()
		task.wait(stunTime)
		stunEnd:Play()
		stunStart:Stop()
		stunLoop:Stop()
		Stunned = false
		task.wait(5)
		CanBeStunned = true
	end
end)

function footStep(frame)
	if frame == "footstep" then
		if hum.FloorMaterial == Enum.Material.Grass or hum.FloorMaterial == Enum.Material.LeafyGrass or hum.FloorMaterial == Enum.Material.Snow or hum.FloorMaterial == Enum.Material.Sand or hum.FloorMaterial == Enum.Material.Mud then
			remotes.PlaySound:FireServer(char:WaitForChild("HumanoidRootPart"):WaitForChild("GrassStep"))
		elseif hum.FloorMaterial ~= Enum.Material.Air then
			remotes.PlaySound:FireServer(char:WaitForChild("HumanoidRootPart"):WaitForChild("GroundStep"))
		end
	end
end

function startRun()
	if wantsToRun == false then
		wantsToRun = true
		tweenService:Create(camera, TweenInfo.new(1, Enum.EasingStyle.Sine), {FieldOfView = 80}):Play()
	end
	if char:GetAttribute("CanRun") and char:GetAttribute("CanMove") and stamina > 0 and not running and not Stunned then
		running = true
		char:SetAttribute("IntendedWalkSpeed", (char:GetAttribute("IntendedWalkSpeed") + (script:GetAttribute("RunSpeed") - script:GetAttribute("WalkSpeed"))))
	end
end

function endRun()
	if running then
		running = false
		canGainStamina = false
		char:SetAttribute("IntendedWalkSpeed", (char:GetAttribute("IntendedWalkSpeed") - (script:GetAttribute("RunSpeed") - script:GetAttribute("WalkSpeed"))))
		task.spawn(function()
			if stamina <= 0 then
				task.wait(2)
			else
				task.wait(0.5)
			end
			canGainStamina = true
		end)
	end
end

gameGui.RunButton.MouseButton1Click:Connect(function()
	if wantsToRun then
		wantsToRun = false
	else
		wantsToRun = true
	end
end)

local function isTeammate(victim)
	if not victim or not victim:FindFirstChildWhichIsA("Humanoid") then 
		return false 
	end

	local victimPlayer = players:GetPlayerFromCharacter(victim)

	-- If it's a player and they're on the same team (both killers)
	if victimPlayer and victimPlayer.Team == teams.Killers and plr.Team == teams.Killers then
		return true
	end

	return false
end

--M1
function ability1func()
	if canUseAbilities and hum.Health > 0 and ability1CoolDown == false and gameGui.Stats.Helpless.Value <= 0 and char:GetAttribute("ActiveTool") == false and Stunned == false then
		canUseAbilities = false
		ability1CoolDown = true

		--Tools
		hum:UnequipTools()

		--Animation
		punch:Play()

		--Cooldown
		task.spawn(function()
			guiMod.activateAbilityGui(ability1Name, ability1CooldownTime)
			ability1CoolDown = false
		end)

		task.delay(0.15,function()
			--Sound
			remotes.PlaySound:FireServer(char.Torso.Swing)
		end)

		task.delay(0.22, function()
			--HitBox
			local atch = Instance.new("Attachment")
			atch.Parent = char.HumanoidRootPart
			atch.Position = Vector3.new(0, 0, -1.5)

			local hitTble = {}
			task.spawn(function()
				for i = 1, 7 do
					local hitbox = hitboxMod.create(atch.WorldCFrame, Vector3.new(4.3, 5.2, 5.2), 0.125)
					hitbox.Touched:Connect(function(hit)
						local victim = hit.Parent

						if victim:FindFirstChildWhichIsA("Humanoid") and not table.find(hitTble, victim) and victim ~= char and not isTeammate(victim) then
							hitbox.BrickColor = BrickColor.new("Lime green")

							table.insert(hitTble, victim)
							print(victim)

							remotes.Damage:FireServer(plr, true, victim, ability1Damage)
							remotes.PlaySound:FireServer(char.Torso.Hit)

							local direction = (victim.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Unit
							remotes.DamageKnockback:FireServer(victim, direction, ability1Knockback)
							remotes.GiveReward:FireServer("SurvivorHit")
						end
					end)
					task.wait()
				end
				atch:Destroy()
			end)
		end)

		task.wait(punch.Length)

		--Return To Normal
		canUseAbilities = true
	end
end

--Ability 1 Code
function ability2func()
	if canUseAbilities and hum.Health > 0 and ability2CoolDown == false and gameGui.Stats.Helpless.Value <= 0 and char:GetAttribute("ActiveTool") == false and Stunned == false then
		canUseAbilities = false
		ability2CoolDown = true

		task.spawn(function()
			statusMod.speed(5, 2, true)
		end)

		--Cooldown
		task.spawn(function()
			guiMod.activateAbilityGui(ability2Name, ability2CooldownTime)
			ability2CoolDown = false
		end)

		task.wait(1)

		--Return To Normal
		canUseAbilities = true
	end
end

--Ability 2 Code
function ability3func()
	if canUseAbilities and hum.Health > 0 and ability3CoolDown == false and gameGui.Stats.Helpless.Value <= 0 and char:GetAttribute("ActiveTool") == false and Stunned == false then
		canUseAbilities = false
		ability3CoolDown = true

		--Tools
		hum:UnequipTools()

		--Animation
		punch:Play()

		task.delay(0.15,function()
			remotes.PlaySound:FireServer(char.Torso.Swing)
		end)

		task.delay(0.22, function()
			--HitBox
			local atch = Instance.new("Attachment")
			atch.Parent = char.HumanoidRootPart
			atch.Position = Vector3.new(0, 0, -1.45)

			local hitTble = {}
			task.spawn(function()
				for i = 1, 10 do
					local hitbox = hitboxMod.create(atch.WorldCFrame, Vector3.new(4.4, 5.2, 5.5), 0.125)
					hitbox.Touched:Connect(function(hit)
						local victim = hit.Parent

						if victim:FindFirstChildWhichIsA("Humanoid") and not table.find(hitTble, victim) and victim ~= char and not isTeammate(victim) then
							hitbox.BrickColor = BrickColor.new("Lime green")

							table.insert(hitTble, victim)
							print(victim)

							-- Damage
							remotes.Damage:FireServer(plr, true, victim, ability3Damage)
							-- Apply Slow status effect
							local targetPlayer = players:GetPlayerFromCharacter(victim)
							if targetPlayer then
								remotes.GiveEffect:FireServer(targetPlayer, "slow", 3, 1) -- adjust power and duration as needed
							end
							remotes.PlaySound:FireServer(char.Torso.Hit)

							local direction = (victim.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Unit
							remotes.DamageKnockback:FireServer(victim, direction, ability3Knockback)
							giveCustomReward("Ability3Hit")
						end
					end)
					task.wait()
				end
				atch:Destroy()
			end)
		end)

		task.wait(punch.Length)

		--Cooldown UI
		task.spawn(function()
			guiMod.activateAbilityGui(ability3Name, ability3CooldownTime)
			ability3CoolDown = false
		end)

		--Return To Normal
		canUseAbilities = true
	end
end

-- Ability 3 Code
function ability4func()
	if canUseAbilities and hum.Health > 0 and ability4CoolDown == false and gameGui.Stats.Helpless.Value <= 0 and char:GetAttribute("ActiveTool") == false and Stunned == false then
		canUseAbilities = false
		ability4CoolDown = true

		--Cooldown
		task.spawn(function()
			guiMod.activateAbilityGui(ability4Name, ability4CooldownTime)
			ability4CoolDown = false
		end)
		task.spawn(function()
			gameMod.findPlayers(teams.Survivors:GetPlayers(), 3)
		end)

		task.wait(3)

		--Return To Normal
		canUseAbilities = true
	end
end

--Inputs
ability1.AbilityIcon.MouseButton1Click:Connect(ability1func)
ability2.AbilityIcon.MouseButton1Click:Connect(ability2func)
ability3.AbilityIcon.MouseButton1Click:Connect(ability3func)
ability4.AbilityIcon.MouseButton1Click:Connect(ability4func)

mouse.Button1Down:Connect(ability1func)

uis.InputBegan:Connect(function(input, istyping)
	if istyping then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
		startRun()
	elseif input.KeyCode == ability1KeyCode then
		ability1func()
	elseif input.KeyCode == ability2KeyCode then
		ability2func()
	elseif input.KeyCode == ability3KeyCode then
		ability3func()
	elseif input.KeyCode == ability4KeyCode then
		ability4func()
	end
end)

uis.InputEnded:Connect(function(input, istyping)
	if istyping then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
		if wantsToRun then
			wantsToRun = false
			tweenService:Create(camera, TweenInfo.new(1, Enum.EasingStyle.Sine), {FieldOfView = 70}):Play()
		end
		endRun()
	end
end)

task.spawn(function()
	while task.wait() do
		if wantsToRun then
			startRun()
		else
			endRun()
		end
	end
end)

--Speed / Slowness / Can Run
local WalkingBackwards = false
task.spawn(function()
	while task.wait() do
		local DirectionOfMovement = char:WaitForChild("HumanoidRootPart").CFrame:VectorToObjectSpace(hum.RootPart.AssemblyLinearVelocity)

		if DirectionOfMovement.Z/hum.WalkSpeed >= 0.1 then
			if not WalkingBackwards then
				WalkingBackwards = true
				char:SetAttribute("IntendedWalkSpeed", char:GetAttribute("IntendedWalkSpeed") - 5)
			end
		else
			if WalkingBackwards then
				WalkingBackwards = false
				char:SetAttribute("IntendedWalkSpeed", char:GetAttribute("IntendedWalkSpeed") + 5)
			end
		end
	end
end)

char.AttributeChanged:Connect(function(att)
	if att == "IntendedWalkSpeed" then
		tweenService:Create(hum, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {WalkSpeed = char:GetAttribute("IntendedWalkSpeed")}):Play()
	elseif att == "CanRun" and char:GetAttribute("CanRun") == false then
		endRun()
	end
end)

--Stamina
task.spawn(function()
	while task.wait() do
		if running and hum.MoveDirection ~= Vector3.zero and nearSurvivor then	
			if stamina <= 0 then
				endRun()
			else
				stamina -= 1
				task.wait(1 / script:GetAttribute("StaminaLoss"))
			end
		elseif canGainStamina and stamina < tonumber(script:GetAttribute("Stamina")) then
			stamina += 1
			task.wait(1 / script:GetAttribute("StaminaGain"))
		end
	end
end)

task.spawn(function()
	while task.wait() do
		tweenService:Create(barsGui.Health.Bar, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {Size = UDim2.new(hum.Health / hum.MaxHealth, 0, 1, 0)}):Play()
		tweenService:Create(barsGui.Stamina.Bar, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {Size = UDim2.new(stamina / tonumber(script:GetAttribute("Stamina")), 0, 1, 0)}):Play()
		barsGui.Health.Number.Text = hum.Health
		barsGui.Stamina.Number.Text = stamina
	end
end)

--Near Survivor
task.spawn(function()
	while task.wait() do
		local survivors = teams.Survivors:GetPlayers()
		local closeSurvivorCount = 0
		local closestDistance = math.huge
		for i = 1, #survivors do
			local Schar = survivors[i].Character
			if Schar:FindFirstChildWhichIsA("Humanoid").Health > 0 and (char:WaitForChild("HumanoidRootPart").Position - Schar:WaitForChild("HumanoidRootPart").Position).Magnitude <= 100 then
				local distance = (char:WaitForChild("HumanoidRootPart").Position - Schar:WaitForChild("HumanoidRootPart").Position).Magnitude
				closeSurvivorCount += 1
				if distance < closestDistance then
					closestDistance = distance
				end
			end
		end
		if closeSurvivorCount == 0 then
			nearSurvivor = false
		else
			nearSurvivor = true
		end
	end
end)

--Can Move
task.spawn(function()
	while task.wait() do
		if char:GetAttribute("CanMove") == false or Stunned then
			if running then
				endRun()
			end
			tweenService:Create(hum, TweenInfo.new(0, Enum.EasingStyle.Linear), {WalkSpeed = 0}):Play()
		else
			if hum.WalkSpeed == 0 then
				tweenService:Create(hum, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {WalkSpeed = char:GetAttribute("IntendedWalkSpeed")}):Play()
			end
		end
	end
end)

--Animation Code
task.spawn(function()
	while task.wait() do
		if hum.MoveDirection == Vector3.zero then
			if not idleAnim.IsPlaying then
				idleAnim:Play()
				walkAnim:Stop()
				runAnim:Stop()
			end
		else
			idleAnim:Stop(0.5)
			if running then
				if not runAnim.IsPlaying then
					runAnim:Play(0.5)
					walkAnim:Stop(0.5)
				end
				runAnim:AdjustSpeed(hum.WalkSpeed / script:GetAttribute("RunSpeed"))
			else
				if not walkAnim.IsPlaying then
					walkAnim:Play(0.5)
					runAnim:Stop(0.5)
				end
				walkAnim:AdjustSpeed(hum.WalkSpeed / script:GetAttribute("WalkSpeed"))
			end
		end
	end
end)

--Footstep Animations
runAnim.KeyframeReached:Connect(footStep)
walkAnim.KeyframeReached:Connect(footStep)

--Game Gui
barsGui.Visible = true