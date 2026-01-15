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
	
	self.CharacterType = "Survivor"
	-- State variables
	self.Running = false
	self.WantsToRun = false
	self.CanGainStamina = true
	self.Stamina = config.Stamina or 100
	self.CanUseAbilities = true
	self.WalkingBackwards = false
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
	-- Ability cooldowns
	self.AbilityCooldowns = {
		Ability1 = false,
		Ability2 = false,
		Ability3 = false
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
	self:SetupAnimations()
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
-- REMOTE SETUP
-- ===============================================
function Behavior:SetupAnimations()
	-- Send animation IDs to client so they can be loaded on-demand
	task.spawn(function()
		task.wait(0.2) -- Small delay to ensure client is ready
		Remotes.SetupAnimations:FireClient(self.Player, self.Config.Animations or {}, "Survivor")
	end)
end

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
		WalkSpeed = self.Humanoid.WalkSpeed,
		CharacterType = "Survivor"
	})
end

-- ===============================================
-- MOVEMENT
-- ===============================================
function Behavior:StartRun()
	if not self.Character:GetAttribute("CanRun") or 
		not self.Character:GetAttribute("CanMove") or 
		self.Stamina <= 0 or 
		self.Running then
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
-- DAMAGE
-- ===============================================
function Behavior:TakeDamage(damage, stunTime)
	if not self.Humanoid or self.Humanoid.Health <= 0 then return end

	local weakness = self.Character:GetAttribute("Weakness") or 0
	local resistance = self.Character:GetAttribute("Resistance") or 0

	--[[print("------------------------------------------------")
	print("[DAÑO] Golpe recibido por: " .. self.Player.Name)
	print("[DAÑO] Atributo Weakness detectado: " .. tostring(weakness))
	print("[DAÑO] Atributo Resistance detectado: " .. tostring(resistance))]]

	-- Cálculo de Daño
	local originalDamage = damage

	-- Aplicar Debilidad
	if weakness > 0 then
		damage = math.round(damage * ((weakness / 5) + 1))
	end

	-- Aplicar Resistencia
	if resistance > 0 then
		damage = math.round(damage / ((resistance / 5) + 1))
	end

	--[[print("[DAÑO] Daño base: " .. originalDamage .. " -> Daño Final: " .. damage)
	print("------------------------------------------------")]]

	self.Humanoid.Health = math.max(0, self.Humanoid.Health - damage)

	-- Los supervivientes no se stunean al recibir daño
	return damage
end

function Behavior:CalculateDamageOutput(baseDamage)
	local strength = self.Character:GetAttribute("Strength") or 0

	if strength > 0 then
		-- Aumenta daño un 20% por nivel (ajustable)
		baseDamage = math.round(baseDamage * ((strength / 5) + 1))
	end

	return baseDamage
end

-- ===============================================
-- ABILITIES
-- ===============================================
function Behavior:SetupAbilities()
	-- Send ability info to client for UI (slight delay to ensure client listeners are ready)
	local abilities = {
		{
			Name = self.Config.Ability1Name,
			Image = self.Config.Ability1Image,
			Key = "Q",
			Cooldown = self.Config.Ability1Cooldown
		},
		{
			Name = self.Config.Ability2Name,
			Image = self.Config.Ability2Image,
			Key = "E",
			Cooldown = self.Config.Ability2Cooldown
		},
		{
			Name = self.Config.Ability3Name,
			Image = self.Config.Ability3Image,
			Key = "R",
			Cooldown = self.Config.Ability3Cooldown
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
	if self.Sounds.Speed then
		self.Sounds.Speed:Play()
	end
	-- Speed boost (from your example)
	Remotes.GiveEffect:FireClient(self.Player, "speed", 5, 1, true)
	-- Give reward
	self:GiveReward("Ab1Speed")
	-- Cooldown
	task.spawn(function()
		Remotes.ActivateAbilityCooldown:FireClient(self.Player, 
			self.Config.Ability1Name, 
			self.Config.Ability1Cooldown or 10)
		task.wait(self.Config.Ability1Cooldown or 10)
		self.AbilityCooldowns.Ability1 = false
	end)
	task.wait(5)
	self.CanUseAbilities = true
end

function Behavior:Ability2()
	if not self:CanUseAbility("Ability2") then return end
	self.CanUseAbilities = false
	self.AbilityCooldowns.Ability2 = true
	-- Resistance + Slow (from your example)
	Remotes.GiveEffect:FireClient(self.Player, "resist", 5, 3, true)
	-- Cooldown
	task.spawn(function()
		Remotes.ActivateAbilityCooldown:FireClient(self.Player, 
			self.Config.Ability2Name, 
			self.Config.Ability2Cooldown or 15)
		task.wait(self.Config.Ability2Cooldown or 15)
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
	Remotes.PlayAnimation:FireClient(self.Player, "Punch")

	task.delay(0.22, function()
		local finalDamage = self:CalculateDamageOutput(self.Config.Ability3Damage or 30)
		self:CreateMeleeHitbox(
			finalDamage,  -- Now uses Strength-modified damage
			self.Config.Ability3Knockback or 30,
			nil,
			function(victim)
				local victimPlayer = Players:GetPlayerFromCharacter(victim)
				if victimPlayer then
					Remotes.GiveEffect:FireClient(victimPlayer, "bleed", 3, 1)
				end
			end,
			Vector3.new(6.5,6.5,7),
			CFrame.new(0,0,-2),
			9,
			0.125,
			0.1,
			"Hit",
			3
		)
	end)

	task.wait(1)

	task.spawn(function()
		Remotes.ActivateAbilityCooldown:FireClient(self.Player, 
			self.Config.Ability3Name, 
			self.Config.Ability3Cooldown)
		task.wait(self.Config.Ability3Cooldown)
		self.AbilityCooldowns.Ability3 = false
	end)

	self.CanUseAbilities = true
end

-- ===============================================
-- HITBOX HELPER (SURVIVOR)
-- ===============================================

function Behavior:CreateMeleeHitbox(damage, knockback, rewardType, onHitCallback, hitboxSize, hitboxOffset, hitboxCount, hitboxDelay, hitboxDuration, hitSoundName, stunTime)
	hitboxSize = hitboxSize or Vector3.new(4.3, 5.2, 5.2)
	hitboxOffset = hitboxOffset or CFrame.new(0, 0, -1.5)
	hitboxCount = hitboxCount or 7
	hitboxDelay = hitboxDelay or 0.03
	hitboxDuration = hitboxDuration or 0.125
	hitSoundName = hitSoundName or "Hit"
	stunTime = stunTime or 0

	local hitTable = {}

	for i = 1, hitboxCount do
		local hitbox = HitboxMod.create(self.HumanoidRootPart, hitboxSize, hitboxDuration, hitboxOffset)

		hitbox.Touched:Connect(function(hit)
			local victim = hit.Parent
			if not victim or not victim:FindFirstChildWhichIsA("Humanoid") then return end
			if table.find(hitTable, victim) then return end
			if victim == self.Character then return end
			if self:IsTeammate(victim) then return end

			table.insert(hitTable, victim)

			local victimHum = victim:FindFirstChildWhichIsA("Humanoid")
			local victimPlayer = Players:GetPlayerFromCharacter(victim)

			local actualDamageDealt = damage
			local victimBehavior = nil

			-- APLICAR DAÑO (inmediato)
			if victimPlayer then
				local BehaviorRegistry = require(game.ServerScriptService.BehaviorRegistry)
				victimBehavior = BehaviorRegistry.get(victimPlayer)
				if victimBehavior and type(victimBehavior.TakeDamage) == "function" then
					-- FIX: Pass nil for stunTime here so TakeDamage returns immediately without yielding.
					-- We handle the actual stun asynchronously at the bottom of this function.
					actualDamageDealt = victimBehavior:TakeDamage(damage, nil) or damage
				else
					victimHum.Health = math.max(0, victimHum.Health - damage)
					actualDamageDealt = damage
				end
			else
				victimHum.Health = math.max(0, victimHum.Health - damage)
				actualDamageDealt = damage
			end

			-- HIT INDICATOR (inmediato)
			Remotes.HitIndicator:FireClient(self.Player, victim.HumanoidRootPart.Position, actualDamageDealt)

			-- SONIDO (inmediato)
			if hitSoundName and self.Sounds[hitSoundName] then
				self.Sounds[hitSoundName]:Play()
			end

			-- KNOCKBACK (inmediato)
			if knockback and knockback > 0 then
				local direction = (victim.HumanoidRootPart.Position - self.HumanoidRootPart.Position).Unit
				self:ApplyKnockback(victim, direction, knockback)
			end

			-- REWARD + CALLBACK (inmediato)
			if rewardType then
				self:GiveReward(rewardType)
			end

			if onHitCallback then
				onHitCallback(victim)
			end
			
			-- APLICAR STUN (inmediato)
			if stunTime and stunTime > 0 then
				if victimBehavior and type(victimBehavior.Stun) == "function" then
					task.spawn(function()
						pcall(function() victimBehavior:Stun(stunTime) end)
					end)
				else
					-- Fallback: usar atributo Helpless
					if victim and victim.Parent then
						victim:SetAttribute("Helpless", stunTime)
						task.delay(stunTime, function()
							if victim and victim.Parent then
								pcall(function() victim:SetAttribute("Helpless", 0) end)
							end
						end)
					end
				end
			end
		end)

		task.wait(hitboxDelay)
	end
end

function Behavior:ApplyKnockback(victim, direction, power)
	local hrp = victim:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Clean previous forces
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
	-- ✅ FIX: Leer atributo Helpless
	local helpless = self.Character:GetAttribute("Helpless") or 0
	
	local isRagdoll = self.Character:FindFirstChild("IsRagdoll")
	local ragdolled = isRagdoll and isRagdoll.Value or false

	return self.CanUseAbilities and 
		self.Humanoid.Health > 0 and 
		not self.AbilityCooldowns[abilityName] and 
		helpless <= 0 and -- Verificación corregida
		not ragdolled and
		not self.Character:GetAttribute("ActiveTool")
end

function Behavior:IsTeammate(victim)
	if not victim or not victim:FindFirstChildWhichIsA("Humanoid") then 
		return false 
	end

	local victimPlayer = Players:GetPlayerFromCharacter(victim)

	if victimPlayer and victimPlayer.Team == Teams.Survivors and self.Player.Team == Teams.Survivors then
		return true
	end

	return false
end

function Behavior:GiveReward(rewardType)
	if not self.Player or not self.Player.Parent then return end

	local customRewards = self.Config.CustomRewards or {}
	local customReward = customRewards[rewardType]

	if customReward then
		-- Handle custom reward
		local survivorName = self.Player.EquippedSurvivor.Value or "Survivor"
		local message = string.format(customReward.messageTemplate or "%s", survivorName)
		local money = customReward.money or 0
		local malice = customReward.malice or 0

		-- Add money to leaderstats (SERVER SIDE)
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

		-- Add malice to leaderstats (SERVER SIDE)
		local maliceVal = leaderstats:FindFirstChild("Killer Chance")
		if not maliceVal then
			maliceVal = Instance.new("NumberValue")
			maliceVal.Name = "Killer Chance"
			maliceVal.Value = 0
			maliceVal.Parent = leaderstats
		end
		maliceVal.Value = maliceVal.Value + malice

		-- Show popup to client
		Remotes.GiveReward:FireClient(self.Player, message, money, malice)
	else
		-- Handle default reward
		local defaultReward = RewardModule.DefaultRewards[rewardType]
		if defaultReward then
			local money = defaultReward.money or 0
			local malice = defaultReward.malice or 0

			-- Add money to leaderstats (SERVER SIDE)
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

			-- Add malice to leaderstats (SERVER SIDE)
			local maliceVal = leaderstats:FindFirstChild("Killer Chance")
			if not maliceVal then
				maliceVal = Instance.new("NumberValue")
				maliceVal.Name = "Killer Chance"
				maliceVal.Value = 0
				maliceVal.Parent = leaderstats
			end
			maliceVal.Value = maliceVal.Value + malice

			-- Show popup to client
			Remotes.GiveReward:FireClient(self.Player, defaultReward.message, money, malice)
		end
	end
end

-- ===============================================
-- LOOPS
-- ===============================================
function Behavior:StartLoops()
	-- Stamina loop (survivors drain stamina always when running)
	task.spawn(function()
		while self.Character and self.Character.Parent do
			if self.Running and self.Humanoid.MoveDirection ~= Vector3.zero then
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
	-- Movement attribute watcher
	task.spawn(function()
		while self.Character and self.Character.Parent do
			if not self.Character:GetAttribute("CanMove") then
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
			local direction = self.HumanoidRootPart.CFrame:VectorToObjectSpace(
				self.Humanoid.RootPart.AssemblyLinearVelocity)
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
	-- Landing slowdown
	self.Humanoid.StateChanged:Connect(function(state)
		if state == Enum.HumanoidStateType.Landed then
			self.Character:SetAttribute("IntendedWalkSpeed", 
				self.Character:GetAttribute("IntendedWalkSpeed") - 10)
			task.wait(0.5)
			self.Character:SetAttribute("IntendedWalkSpeed", 
				self.Character:GetAttribute("IntendedWalkSpeed") + 10)
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
	-- luego tu cleanup normal

	for _, connection in ipairs(self.Connections) do
		connection:Disconnect()
	end
	self.Connections = {}
	self.Character = nil
	self.Player = nil
end

return Behavior