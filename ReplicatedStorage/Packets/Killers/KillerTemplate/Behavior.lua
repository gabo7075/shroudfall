local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local Remotes = ReplicatedStorage.Remotes
local HitboxMod = require(ReplicatedStorage.HitBox)
local RewardModule = require(ReplicatedStorage.RewardModule)

local Behavior = {}
Behavior.__index = Behavior

-- ===============================================
-- CONSTRUCTOR
-- ===============================================

function Behavior.new(player, character, config)
	local self = setmetatable({}, Behavior)

	self.Player = player
	self.Character = character
	self.Humanoid = character:FindFirstChildWhichIsA("Humanoid")
	self.HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	self.Config = config

	local BehaviorRegistry = require(game.ServerScriptService.BehaviorRegistry)
	BehaviorRegistry.register(self.Player, self)

	self.CharacterType = "Killer"
	-- State variables
	self.Running = false
	self.WantsToRun = false
	self.CanGainStamina = true
	self.Stamina = config.Stamina or 110
	self.CanUseAbilities = true
	self.CanBeStunned = true
	self.Stunned = false
	self.NearSurvivor = false
	self.WalkingBackwards = false

	-- Initialize sounds from config
	self.Sounds = {}
	if self.Config.Sounds then
		for name, data in pairs(self.Config.Sounds) do
			local sound = Instance.new("Sound")
			sound.Name = name
			sound.SoundId = data.Id or ""
			sound.Volume = data.Volume or 1
			sound.PlaybackSpeed = data.PlaybackSpeed or 1
			sound.Parent = self.HumanoidRootPart
			self.Sounds[name] = sound
		end
	end

	-- Initialize animations from config (CLIENT-SIDE)
	self.Animations = {}
	self.AnimationsReady = false
	if self.Config.Animations then
		task.spawn(function()
			self:LoadAnimations()
		end)
	end

	-- Ability cooldowns
	self.AbilityCooldowns = {
		Ability1 = false,
		Ability2 = false,
		Ability3 = false,
		Ability4 = false
	}

	-- Connections
	self.Connections = {}

	-- Set initial attributes
	character:SetAttribute("CanMove", true)
	character:SetAttribute("ActiveTool", false)
	character:SetAttribute("CanRun", true)
	character:SetAttribute("IntendedWalkSpeed", config.WalkSpeed or 16)

	-- Set humanoid properties
	self.Humanoid.JumpPower = 0
	self.Humanoid.WalkSpeed = config.WalkSpeed or 16
	self.Humanoid.MaxHealth = config.Health or 100
	self.Humanoid.Health = config.Health or 100

	-- Initialize
	self:SetupRemotes()
	self:StartLoops()
	self:SetupAbilities()

	if self.Character:GetAttribute("Resistance") == nil then
		self.Character:SetAttribute("Resistance", 0)
	end
	if self.Character:GetAttribute("Weakness") == nil then
		self.Character:SetAttribute("Weakness", 0)
	end
	if self.Character:GetAttribute("Helpless") == nil then
		self.Character:SetAttribute("Helpless", 0)
	end

	return self
end

-- ===============================================
-- ANIMATION LOADING (CLIENT-SIDE)
-- ===============================================

function Behavior:LoadAnimations()
	if RunService:IsServer() then
		-- Send animation config to client and wait for client ack
		Remotes.LoadAnimations:FireClient(self.Player, self.Config.Animations)

		local loaded = false
		local conn
		conn = Remotes.AnimationsLoaded.OnServerEvent:Connect(function(plr)
			if plr == self.Player then
				loaded = true
				conn:Disconnect()
			end
		end)

		local timeout = 1 -- seconds
		local t0 = tick()
		while not loaded and tick() - t0 < timeout do
			task.wait(0.03)
		end
		if not loaded then
			warn("[Behavior] Client did not acknowledge animations load for", self.Player and self.Player.Name)
		else
			self.AnimationsReady = true
		end
		return
	end

	-- CLIENT-SIDE: Create and load animation tracks
	for animName, animId in pairs(self.Config.Animations) do
		local animObj = Instance.new("Animation")
		animObj.AnimationId = animId
		animObj.Name = animName

		local priority = Enum.AnimationPriority.Action
		if animName == "Idle" then
			priority = Enum.AnimationPriority.Idle
		elseif animName == "Walk" or animName == "Run" then
			priority = Enum.AnimationPriority.Core
		end

		local track = self.Humanoid:LoadAnimation(animObj)
		track.Priority = priority
		self.Animations[animName] = track

		print("[Behavior] Loaded animation:", animName)
	end
end

function Behavior:PlayAnimation(animName)
	if RunService:IsServer() then
		local t0 = tick()
		while not self.AnimationsReady and tick() - t0 < 0.6 do
			task.wait(0.03)
		end
		Remotes.PlayAnimation:FireClient(self.Player, animName)
		return
	end

	-- CLIENT-SIDE
	if self.Animations[animName] then
		self.Animations[animName]:Play()
	else
		warn("[Behavior] Animation not found:", animName)
	end
end

function Behavior:StopAnimation(animName)
	if RunService:IsServer() then
		local t0 = tick()
		while not self.AnimationsReady and tick() - t0 < 0.6 do
			task.wait(0.03)
		end
		Remotes.StopAnimation:FireClient(self.Player, animName)
		return
	end

	-- CLIENT-SIDE
	if self.Animations[animName] then
		self.Animations[animName]:Stop()
	end
end

-- ===============================================
-- REMOTE SETUP
-- ===============================================

function Behavior:SetupRemotes()
	-- Input handling
	table.insert(self.Connections, Remotes.CharacterInput.OnServerEvent:Connect(function(plr, inputType, ...)
		if plr ~= self.Player then return end

		if inputType == "StartRun" then
			self:StartRun()
		elseif inputType == "EndRun" then
			self:EndRun()
		elseif inputType == "Ability1" then
			self:Ability1()
		elseif inputType == "Ability2" then
			self:Ability2()
		elseif inputType == "Ability3" then
			self:Ability3()
		elseif inputType == "Ability4" then
			self:Ability4()
		end
	end))

	-- Allow client to request abilities if they missed the initial send
	if Remotes:FindFirstChild("RequestAbilities") then
		table.insert(self.Connections, Remotes.RequestAbilities.OnServerEvent:Connect(function(plr)
			if plr ~= self.Player then return end
			warn("[Behavior] RequestAbilities received from", plr.Name)
			self:SetupAbilities()
		end))
	end

	-- Sync client state
	task.spawn(function()
		while self.Character and self.Character.Parent do
			self:SyncToClient()
			task.wait(0.1)
		end
	end)
end

-- ===============================================
-- CLIENT SYNC
-- ===============================================

function Behavior:SyncToClient()
	if not self.Player or not self.Character then return end

	Remotes.SyncCharacterState:FireClient(self.Player, {
		Health = self.Humanoid.Health,
		MaxHealth = self.Humanoid.MaxHealth,
		Stamina = self.Stamina,
		MaxStamina = self.Config.Stamina,
		Running = self.Running,
		Stunned = self.Stunned,
		WalkSpeed = self.Humanoid.WalkSpeed,
		CharacterType = "Killer"
	})
end

-- ===============================================
-- MOVEMENT
-- ===============================================

function Behavior:StartRun()
	if not self.Character:GetAttribute("CanRun") or 
		not self.Character:GetAttribute("CanMove") or 
		self.Stamina <= 0 or 
		self.Running or 
		self.Stunned then
		return
	end

	self.Running = true
	local speedIncrease = (self.Config.RunSpeed or 22) - (self.Config.WalkSpeed or 16)
	self.Character:SetAttribute("IntendedWalkSpeed", 
		self.Character:GetAttribute("IntendedWalkSpeed") + speedIncrease)
end

function Behavior:EndRun()
	if not self.Running then return end

	self.Running = false
	self.CanGainStamina = false
	local speedDecrease = (self.Config.RunSpeed or 22) - (self.Config.WalkSpeed or 16)
	self.Character:SetAttribute("IntendedWalkSpeed", 
		self.Character:GetAttribute("IntendedWalkSpeed") - speedDecrease)

	task.delay(self.Stamina <= 0 and 2 or 0.5, function()
		self.CanGainStamina = true
	end)
end

-- ===============================================
-- DAMAGE & STUN
-- ===============================================

function Behavior:TakeDamage(damage, stunTime)
	if not self.Humanoid or self.Humanoid.Health <= 0 then return end

	local weakness = self.Character:GetAttribute("Weakness") or 0
	local resistance = self.Character:GetAttribute("Resistance") or 0

	if weakness > 0 then
		damage = math.round(damage * ((weakness / 5) + 1))
	end
	if resistance > 0 then
		damage = math.round(damage / ((resistance / 5) + 1))
	end

	self.Humanoid.Health = math.max(0, self.Humanoid.Health - damage)

	if stunTime and stunTime > 0 and self.CanBeStunned then
		self:Stun(stunTime)
	end
	return damage
end

function Behavior:CalculateDamageOutput(baseDamage)
	local strength = self.Character:GetAttribute("Strength") or 0

	if strength > 0 then
		baseDamage = math.round(baseDamage * ((strength / 5) + 1))
	end

	return baseDamage
end

function Behavior:Stun(duration)
	if self.Stunned or not self.CanBeStunned then return end

	self.Stunned = true
	self.CanBeStunned = false

	-- Play stun animations
	self:PlayAnimation("StunStart")
	self:PlayAnimation("StunLoop")

	task.wait(duration)

	self:PlayAnimation("StunEnd")
	self:StopAnimation("StunStart")
	self:StopAnimation("StunLoop")

	self.Stunned = false

	task.wait(5)
	self.CanBeStunned = true
end

-- ===============================================
-- ABILITIES
-- ===============================================

function Behavior:SetupAbilities()
	local abilities = {
		{
			Name = self.Config.Ability1Name or "Punch",
			Image = self.Config.Ability1Image or "rbxassetid://123352469952776",
			Key = "M1",
			Cooldown = self.Config.Ability1Cooldown or 1.6
		},
		{
			Name = self.Config.Ability2Name or "Effect",
			Image = self.Config.Ability2Image or "rbxassetid://82229308135638",
			Key = "Q",
			Cooldown = self.Config.Ability2Cooldown or 4
		},
		{
			Name = self.Config.Ability3Name or "Special",
			Image = self.Config.Ability3Image or "rbxassetid://106226036311010",
			Key = "E",
			Cooldown = self.Config.Ability3Cooldown or 1.6
		},
		{
			Name = self.Config.Ability4Name or "Locate",
			Image = self.Config.Ability4Image or "rbxassetid://77080976212074",
			Key = "R",
			Cooldown = self.Config.Ability4Cooldown or 7
		}
	}

	task.spawn(function()
		task.wait(0.3)
		Remotes.SetupAbilities:FireClient(self.Player, abilities)
	end)
end

function Behavior:Ability1()
	if not self:CanUseAbility("Ability1") then return end

	self.CanUseAbilities = false
	self.AbilityCooldowns.Ability1 = true

	self.Humanoid:UnequipTools()

	-- Play animation
	self:PlayAnimation("Punch")

	-- Start cooldown
	task.spawn(function()
		Remotes.ActivateAbilityCooldown:FireClient(self.Player, 
			self.Config.Ability1Name or "Punch", 
			self.Config.Ability1Cooldown or 1.6)
		task.wait((self.Config.Ability1Cooldown or 1.6) + 0.15) --finishes early server side
		self.AbilityCooldowns.Ability1 = false
	end)

	-- Sound
	task.delay(0.15, function()
		if self.Sounds.Swing then
			self.Sounds.Swing:Play()
		end
	end)

	-- Hitbox
	task.delay(0.22, function()
		local finalDamage = self:CalculateDamageOutput(self.Config.Ability1Damage or 25)
		self:CreateMeleeHitbox(
			finalDamage,
			self.Config.Ability1Knockback or 15,
			"SurvivorHit",
			nil,
			Vector3.new(4.3,5.2,5.2),
			CFrame.new(0,0,-1.5),
			7,
			0.03,
			0.125,
			"Hit"
		)
	end)

	task.wait(self.Config.Ability1AnimLength or 1)
	self.CanUseAbilities = true
end

function Behavior:Ability2()
	if not self:CanUseAbility("Ability2") then return end

	self.CanUseAbilities = false
	self.AbilityCooldowns.Ability2 = true

	Remotes.GiveEffect:FireClient(self.Player, "speed", 5, 2, true)
	Remotes.GiveEffect:FireClient(self.Player, "strength", 5, 1, true)

	task.spawn(function()
		Remotes.ActivateAbilityCooldown:FireClient(self.Player, 
			self.Config.Ability2Name or "Effect", 
			self.Config.Ability2Cooldown or 4)
		task.wait((self.Config.Ability2Cooldown or 4) + 0.15) --finishes early server side
		self.AbilityCooldowns.Ability2 = false
	end)

	task.wait(1)
	self.CanUseAbilities = true
end

function Behavior:Ability3()
	if not self:CanUseAbility("Ability3") then return end

	self.CanUseAbilities = false
	self.AbilityCooldowns.Ability3 = true

	self.Humanoid:UnequipTools()
	self:PlayAnimation("Punch")

	task.delay(0.15, function()
		if self.Sounds.Swing then
			self.Sounds.Swing:Play()
		end
	end)

	task.delay(0.22, function()
		local finalDamage = self:CalculateDamageOutput(self.Config.Ability3Damage or 30)
		self:CreateMeleeHitbox(
			finalDamage,
			self.Config.Ability3Knockback or 30,
			"Ability3Hit",
			function(victim)
				local victimPlayer = Players:GetPlayerFromCharacter(victim)
				if victimPlayer then
					Remotes.GiveEffect:FireClient(victimPlayer, "slow", 3, 1)
				end

				local LMSManager = require(ReplicatedStorage.Modules.LMSManager)
				LMSManager.highlightVictim(self.Player, victim, 3, Color3.fromRGB(0, 255, 0))
			end,
			Vector3.new(6.5,6.5,7),
			CFrame.new(0,0,-2),
			10,
			0.025,
			0.2,
			"Hit"
		)
	end)

	task.wait(self.Config.Ability3AnimLength or 1)

	task.spawn(function()
		Remotes.ActivateAbilityCooldown:FireClient(self.Player, 
			self.Config.Ability3Name or "Special", 
			self.Config.Ability3Cooldown or 1.6)
		task.wait((self.Config.Ability3Cooldown or 1.6) + 0.15) --finishes early server side
		self.AbilityCooldowns.Ability3 = false
	end)

	self.CanUseAbilities = true
end

function Behavior:Ability4()
	if not self:CanUseAbility("Ability4") then return end

	self.CanUseAbilities = false
	self.AbilityCooldowns.Ability4 = true

	local LMSManager = require(ReplicatedStorage.Modules.LMSManager)
	LMSManager.findPlayers(self.Player, Teams.Survivors:GetPlayers(), 3)

	task.spawn(function()
		Remotes.ActivateAbilityCooldown:FireClient(self.Player, 
			self.Config.Ability4Name or "Locate", 
			self.Config.Ability4Cooldown or 7)
		task.wait((self.Config.Ability4Cooldown or 7) + 0.15) --finishes early server side
		self.AbilityCooldowns.Ability4 = false
	end)

	task.wait(3)
	self.CanUseAbilities = true
end

-- ===============================================
-- HITBOX HELPER
-- ===============================================

function Behavior:CreateMeleeHitbox(damage, knockback, rewardType, onHitCallback, hitboxSize, hitboxOffset, hitboxCount, hitboxDelay, hitboxDuration, hitSoundName)
	hitboxSize = hitboxSize or Vector3.new(4.3, 5.2, 5.2)
	hitboxOffset = hitboxOffset or CFrame.new(0, 0, -1.5)
	hitboxCount = hitboxCount or 7
	hitboxDelay = hitboxDelay or 0.03
	hitboxDuration = hitboxDuration or 0.125
	hitSoundName = hitSoundName or "Hit"

	local hitTable = {}

	for i = 1, hitboxCount do
		local hitbox = HitboxMod.create(self.HumanoidRootPart, hitboxSize, hitboxDuration, hitboxOffset)

		hitbox.Touched:Connect(function(hit)
			local victim = hit.Parent

			if not victim:FindFirstChildWhichIsA("Humanoid") then return end
			if table.find(hitTable, victim) then return end
			if victim == self.Character then return end
			if self:IsTeammate(victim) then return end

			hitbox.BrickColor = BrickColor.new("Lime green")
			table.insert(hitTable, victim)

			local victimHum = victim:FindFirstChildWhichIsA("Humanoid")
			local victimPlayer = Players:GetPlayerFromCharacter(victim)

			local actualDamageDealt = damage

			if victimPlayer then
				local BehaviorRegistry = require(game.ServerScriptService.BehaviorRegistry)
				local victimBehavior = BehaviorRegistry.get(victimPlayer)
				if victimBehavior and type(victimBehavior.TakeDamage) == "function" then
					actualDamageDealt = victimBehavior:TakeDamage(damage, 0)
				else
					warn("[Hitbox] No behavior found for", victimPlayer.Name, "- applying direct damage")
					victimHum.Health = math.max(0, victimHum.Health - damage)
					actualDamageDealt = damage
				end
			else
				victimHum.Health = math.max(0, victimHum.Health - damage)
				actualDamageDealt = damage
			end

			Remotes.HitIndicator:FireClient(self.Player, victim.HumanoidRootPart.Position, actualDamageDealt)

			if hitSoundName and self.Sounds[hitSoundName] then
				self.Sounds[hitSoundName]:Play()
			end

			if knockback and knockback > 0 then
				local direction = (victim.HumanoidRootPart.Position - self.HumanoidRootPart.Position).Unit
				self:ApplyKnockback(victim, direction, knockback)
			end

			if rewardType then
				self:GiveReward(rewardType)
			end

			if onHitCallback then
				onHitCallback(victim)
			end
		end)

		task.wait(hitboxDelay)
	end
end

function Behavior:ApplyKnockback(victim, direction, power)
	local hrp = victim:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	for _, force in ipairs(hrp:GetChildren()) do
		if force:IsA("LinearVelocity") or force:IsA("VectorForce") then
			force:Destroy()
		end
	end

	local victimPlayer = Players:GetPlayerFromCharacter(victim)
	if victimPlayer then
		hrp:SetNetworkOwner(nil)
	end

	hrp.AssemblyAngularVelocity = Vector3.zero

	local attachment = Instance.new("Attachment", hrp)
	local knockback = Instance.new("LinearVelocity")
	knockback.Attachment0 = attachment
	knockback.MaxForce = math.huge
	local flatDir = Vector3.new(direction.X, 0, direction.Z).Unit
	knockback.VectorVelocity = flatDir * power
	knockback.Parent = hrp

	task.delay(0.25, function()
		if knockback then knockback:Destroy() end
		if attachment then attachment:Destroy() end

		if victimPlayer and hrp and hrp.Parent then
			pcall(function()
				hrp:SetNetworkOwner(victimPlayer)
			end)
		end
	end)
end

-- ===============================================
-- HELPERS
-- ===============================================

function Behavior:CanUseAbility(abilityName)
	local helpless = self.Character:GetAttribute("Helpless") or 0

	local isRagdoll = self.Character:FindFirstChild("IsRagdoll")
	local ragdolled = isRagdoll and isRagdoll.Value or false

	return self.CanUseAbilities and 
		self.Humanoid.Health > 0 and 
		not self.AbilityCooldowns[abilityName] and 
		helpless <= 0 and
		not ragdolled and
		not self.Character:GetAttribute("ActiveTool") and 
		not self.Stunned
end

function Behavior:IsTeammate(victim)
	if not victim or not victim:FindFirstChildWhichIsA("Humanoid") then 
		return false 
	end

	local victimPlayer = Players:GetPlayerFromCharacter(victim)

	if victimPlayer and victimPlayer.Team == Teams.Killers and self.Player.Team == Teams.Killers then
		return true
	end

	return false
end

function Behavior:GiveReward(rewardType)
	if not self.Player or not self.Player.Parent then return end

	local customRewards = self.Config.CustomRewards or {}
	local customReward = customRewards[rewardType]

	if customReward then
		local killerName = self.Player.EquippedKiller.Value or "Killer"
		local message = string.format(customReward.messageTemplate or "%s", killerName)
		local money = customReward.money or 0
		local malice = customReward.malice or 0

		local leaderstats = self.Player:FindFirstChild("leaderstats")
		if not leaderstats then
			leaderstats = Instance.new("Folder")
			leaderstats.Name = "leaderstats"
			leaderstats.Parent = self.Player
		end

		local moneyVal = leaderstats:FindFirstChild("Money")
		if not moneyVal then
			moneyVal = Instance.new("IntValue")
			moneyVal.Name = "Money"
			moneyVal.Value = 0
			moneyVal.Parent = leaderstats
		end
		moneyVal.Value = moneyVal.Value + money

		local maliceVal = leaderstats:FindFirstChild("Killer Chance")
		if not maliceVal then
			maliceVal = Instance.new("NumberValue")
			maliceVal.Name = "Killer Chance"
			maliceVal.Value = 0
			maliceVal.Parent = leaderstats
		end
		maliceVal.Value = maliceVal.Value + malice

		Remotes.GiveReward:FireClient(self.Player, message, money, malice)
	else
		local defaultReward = RewardModule.DefaultRewards[rewardType]
		if defaultReward then
			local money = defaultReward.money or 0
			local malice = defaultReward.malice or 0

			local leaderstats = self.Player:FindFirstChild("leaderstats")
			if not leaderstats then
				leaderstats = Instance.new("Folder")
				leaderstats.Name = "leaderstats"
				leaderstats.Parent = self.Player
			end

			local moneyVal = leaderstats:FindFirstChild("Money")
			if not moneyVal then
				moneyVal = Instance.new("IntValue")
				moneyVal.Name = "Money"
				moneyVal.Value = 0
				moneyVal.Parent = leaderstats
			end
			moneyVal.Value = moneyVal.Value + money

			local maliceVal = leaderstats:FindFirstChild("Killer Chance")
			if not maliceVal then
				maliceVal = Instance.new("NumberValue")
				maliceVal.Name = "Killer Chance"
				maliceVal.Value = 0
				maliceVal.Parent = leaderstats
			end
			maliceVal.Value = maliceVal.Value + malice

			Remotes.GiveReward:FireClient(self.Player, defaultReward.message, money, malice)
		end
	end
end

-- ===============================================
-- LOOPS
-- ===============================================

function Behavior:StartLoops()
	-- Stamina loop
	task.spawn(function()
		while self.Character and self.Character.Parent do
			if self.Running and self.Humanoid.MoveDirection ~= Vector3.zero and self.NearSurvivor then
				if self.Stamina <= 0 then
					self:EndRun()
				else
					self.Stamina = self.Stamina - 1
					task.wait(1 / (self.Config.StaminaLoss or 10))
				end
			elseif self.CanGainStamina and self.Stamina < self.Config.Stamina then
				self.Stamina = self.Stamina + 1
				task.wait(1 / (self.Config.StaminaGain or 5))
			else
				task.wait(0.1)
			end
		end
	end)

	-- Near survivor check
	task.spawn(function()
		while self.Character and self.Character.Parent do
			local survivors = Teams.Survivors:GetPlayers()
			local nearCount = 0

			for _, survivor in ipairs(survivors) do
				if survivor.Character and survivor.Character:FindFirstChild("HumanoidRootPart") then
					local sChar = survivor.Character
					local sHum = sChar:FindFirstChildWhichIsA("Humanoid")

					if sHum and sHum.Health > 0 then
						local dist = (self.HumanoidRootPart.Position - sChar.HumanoidRootPart.Position).Magnitude
						if dist <= 100 then
							nearCount = nearCount + 1
						end
					end
				end
			end

			self.NearSurvivor = nearCount > 0
			task.wait(0.5)
		end
	end)

	-- Movement attribute watcher
	task.spawn(function()
		while self.Character and self.Character.Parent do
			if not self.Character:GetAttribute("CanMove") or self.Stunned then
				if self.Running then
					self:EndRun()
				end
				TweenService:Create(self.Humanoid, TweenInfo.new(0), {WalkSpeed = 0}):Play()
			else
				if self.Humanoid.WalkSpeed == 0 then
					TweenService:Create(self.Humanoid, TweenInfo.new(0.25), 
						{WalkSpeed = self.Character:GetAttribute("IntendedWalkSpeed")}):Play()
				end
			end
			task.wait(0.1)
		end
	end)

	-- Walking backwards detection
	task.spawn(function()
		while self.Character and self.Character.Parent do
			local vel = nil
			if self.HumanoidRootPart and self.HumanoidRootPart.Parent then
				vel = self.HumanoidRootPart.AssemblyLinearVelocity
			elseif self.Humanoid and self.Humanoid.RootPart then
				vel = self.Humanoid.RootPart.AssemblyLinearVelocity
			end

			local direction = Vector3.new(0,0,0)
			if vel then
				direction = self.HumanoidRootPart.CFrame:VectorToObjectSpace(vel)
			end

			if direction.Z / self.Humanoid.WalkSpeed >= 0.1 then
				if not self.WalkingBackwards then
					self.WalkingBackwards = true
					self.Character:SetAttribute("IntendedWalkSpeed", 
						self.Character:GetAttribute("IntendedWalkSpeed") - 5)
				end
			else
				if self.WalkingBackwards then
					self.WalkingBackwards = false
					self.Character:SetAttribute("IntendedWalkSpeed", 
						self.Character:GetAttribute("IntendedWalkSpeed") + 5)
				end
			end
			task.wait(0.1)
		end
	end)

	-- Attribute changes
	self.Character.AttributeChanged:Connect(function(att)
		if att == "IntendedWalkSpeed" then
			TweenService:Create(self.Humanoid, TweenInfo.new(0.25), 
				{WalkSpeed = self.Character:GetAttribute("IntendedWalkSpeed")}):Play()
		elseif att == "CanRun" and not self.Character:GetAttribute("CanRun") then
			self:EndRun()
		end
	end)
end

-- ===============================================
-- CLEANUP
-- ===============================================

function Behavior:Destroy()
	local BehaviorRegistry = require(game.ServerScriptService.BehaviorRegistry)
	BehaviorRegistry.unregister(self.Player)

	for _, connection in ipairs(self.Connections) do
		connection:Disconnect()
	end

	self.Connections = {}
	self.Character = nil
	self.Player = nil
end

return Behavior