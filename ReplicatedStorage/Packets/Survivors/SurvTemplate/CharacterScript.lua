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

ability1CoolDown = false
ability2CoolDown = false

local defaultIds = {
	Idle = "rbxassetid://139187437656429",
	Walk = "rbxassetid://98546993310870",
	Run = "rbxassetid://101089497691524",
	InjuredIdle = "rbxassetid://96243184323491",
	InjuredWalk = "rbxassetid://119088829288250",
	InjuredRun = "rbxassetid://136315598224264",
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
local InjuredIdleAnim = createAndLoadAnim(animIds.InjuredIdle)
local InjuredWalkAnim = createAndLoadAnim(animIds.InjuredWalk)
local InjuredRunAnim = createAndLoadAnim(animIds.InjuredRun)

-- local example = createAndLoadAnim(animIds.Example, Enum.AnimationPriority.Action)

--Creating Abilities
local ability1Name = "Speed"
local ability2Name = "Resistance"

local ability1KeyCode = Enum.KeyCode.Q
local ability2KeyCode = Enum.KeyCode.E

local ability1CooldownTime = 10
local ability2CooldownTime = 15

local CUSTOM_REWARDS = {
	Ab1Speed = {
		money = 10,
		malice = 0.25,
		messageTemplate = "Speed buffed as %s."
	}
}

local function giveCustomReward(rewardType)
	local reward = CUSTOM_REWARDS[rewardType]
	if not reward then return end

	local survivorName = plr.EquippedSurvivor.Value or "Survivor"
	local message = string.format(reward.messageTemplate, survivorName)

	-- Request reward from server
	remotes.GiveReward:FireServer(message, reward.money, reward.malice)
end

if uis.GamepadEnabled then
	ability1KeyCode = Enum.KeyCode.ButtonY
	ability2KeyCode = Enum.KeyCode.ButtonB
end

local ability1 = guiMod.createAbilityGui(ability1Name, "rbxassetid://126902881718435", ability1KeyCode)
local ability2 = guiMod.createAbilityGui(ability2Name, "rbxassetid://97165310608563", ability2KeyCode)

--Functions
remotes.Damage.OnClientEvent:Connect(function(killer, damage, stunTime)
	if gameGui.Stats.Weakness.Value > 0 then
		damage = math.round(damage * ((gameGui.Stats.Weakness.Value / 5) + 1))
	end
	if gameGui.Stats.Resistance.Value > 0 then
		damage = math.round(damage / ((gameGui.Stats.Resistance.Value / 5) + 1))
	end
	remotes.Damage:FireServer(killer, false, char, damage, stunTime)
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
	if char:GetAttribute("CanRun") and char:GetAttribute("CanMove") and stamina > 0 and not running then
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

--Ability 1 Code
function ability1func()
	if canUseAbilities and hum.Health > 0 and ability1CoolDown == false and gameGui.Stats.Helpless.Value <= 0 and char:GetAttribute("ActiveTool") == false then
		canUseAbilities = false
		ability1CoolDown = true

		--Status
		task.spawn(function()
			statusMod.speed(5, 1, true)
		end)
		giveCustomReward("Ab1Speed")

		--Cooldown
		task.spawn(function()
			guiMod.activateAbilityGui(ability1Name, ability1CooldownTime)
			ability1CoolDown = false
		end)

		task.wait(5)

		canUseAbilities = true
	end
end

--Ability 2 Code
function ability2func()
	if canUseAbilities and hum.Health > 0 and ability2CoolDown == false and gameGui.Stats.Helpless.Value <= 0 and char:GetAttribute("ActiveTool") == false then
		canUseAbilities = false
		ability2CoolDown = true

		--Status
		task.spawn(function()
			statusMod.resist(1, 3, true)
		end)

		task.spawn(function()
			statusMod.slow(1, 2, true)
		end)

		--Cooldown
		task.spawn(function()
			guiMod.activateAbilityGui(ability2Name, ability2CooldownTime)
			ability2CoolDown = false
		end)

		task.wait(1)

		canUseAbilities = true
	end
end

--Inputs
ability1.AbilityIcon.MouseButton1Click:Connect(ability1func)
ability2.AbilityIcon.MouseButton1Click:Connect(ability2func)

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

hum.StateChanged:Connect(function(state)
	if state == Enum.HumanoidStateType.Landed then
		char:SetAttribute("IntendedWalkSpeed", char:GetAttribute("IntendedWalkSpeed") - 10)
		task.wait(0.5)
		char:SetAttribute("IntendedWalkSpeed", char:GetAttribute("IntendedWalkSpeed") + 10)
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
		if running and hum.MoveDirection ~= Vector3.zero then	
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

--Can Move
task.spawn(function()
	while task.wait() do
		if char:GetAttribute("CanMove") == false then
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
		if hum.Health > (hum.MaxHealth / 2) then
			InjuredIdleAnim:Stop(0.5)
			InjuredRunAnim:Stop(0.5)
			InjuredWalkAnim:Stop(0.5)
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
		else
			idleAnim:Stop(0.5)
			runAnim:Stop(0.5)
			walkAnim:Stop(0.5)
			if hum.MoveDirection == Vector3.zero then
				if not InjuredIdleAnim.IsPlaying then
					InjuredIdleAnim:Play()
					InjuredWalkAnim:Stop()
					InjuredRunAnim:Stop()
				end
			else
				InjuredIdleAnim:Stop(0.5)
				if running then
					if not InjuredRunAnim.IsPlaying then
						InjuredRunAnim:Play(0.5)
						InjuredWalkAnim:Stop(0.5)
					end
					InjuredRunAnim:AdjustSpeed(hum.WalkSpeed / script:GetAttribute("RunSpeed"))
				else
					if not InjuredWalkAnim.IsPlaying then
						InjuredWalkAnim:Play(0.5)
						InjuredRunAnim:Stop(0.5)
					end
					InjuredWalkAnim:AdjustSpeed(hum.WalkSpeed / script:GetAttribute("WalkSpeed"))
				end
			end
		end
	end
end)

--Footstep Animations
runAnim.KeyframeReached:Connect(footStep)
walkAnim.KeyframeReached:Connect(footStep)
InjuredRunAnim.KeyframeReached:Connect(footStep)
InjuredWalkAnim.KeyframeReached:Connect(footStep)

--Game Gui
barsGui.Visible = true