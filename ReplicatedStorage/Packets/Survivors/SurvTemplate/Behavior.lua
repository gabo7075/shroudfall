-- ModuleScript: ReplicatedStorage > Packets > Survivors > [CharacterName] > Behavior
-- Server-side survivor behavior handler
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Teams = game:GetService("Teams")
local Remotes = ReplicatedStorage.Remotes
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
	self.CharacterType = "Survivor" -- Mark as survivor
	-- State variables
	self.Running = false
	self.WantsToRun = false
	self.CanGainStamina = true
	self.Stamina = config.Stamina or 100
	self.CanUseAbilities = true
	self.WalkingBackwards = false
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
	return self
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
	-- Apply weakness/resistance
	local weakness = self.Player.PlayerGui.GameGui.Stats.Weakness.Value
	local resistance = self.Player.PlayerGui.GameGui.Stats.Resistance.Value
	if weakness > 0 then
		damage = math.round(damage * ((weakness / 5) + 1))
	end
	if resistance > 0 then
		damage = math.round(damage / ((resistance / 5) + 1))
	end
	self.Humanoid.Health = math.max(0, self.Humanoid.Health - damage)
	-- Survivors don't get stunned (unlike killers)
	return damage
end


-- ===============================================
-- ABILITIES
-- ===============================================
function Behavior:SetupAbilities()
	local abilities = {}
	-- Only setup abilities that exist in config
	if self.Config.Ability1Name then
		table.insert(abilities, {
			Name = self.Config.Ability1Name,
			Image = self.Config.Ability1Image or "rbxassetid://123352469952776",
			Key = "Q",
			Cooldown = self.Config.Ability1Cooldown or 10
		})
	end
	if self.Config.Ability2Name then
		table.insert(abilities, {
			Name = self.Config.Ability2Name,
			Image = self.Config.Ability2Image or "rbxassetid://82229308135638",
			Key = "E",
			Cooldown = self.Config.Ability2Cooldown or 15
		})
	end
	if self.Config.Ability3Name then
		table.insert(abilities, {
			Name = self.Config.Ability3Name,
			Image = self.Config.Ability3Image or "rbxassetid://106226036311010",
			Key = "R",
			Cooldown = self.Config.Ability3Cooldown or 20
		})
	end
	if self.Config.Ability4Name then
		table.insert(abilities, {
			Name = self.Config.Ability4Name,
			Image = self.Config.Ability4Image or "rbxassetid://77080976212074",
			Key = "F",
			Cooldown = self.Config.Ability4Cooldown or 25
		})
	end
	-- Send ability info to client for UI (slight delay to ensure client listeners are ready)
	warn("[Behavior:SetupAbilities] Firing SetupAbilities to", self.Player.Name)
	task.spawn(function()
		task.wait(0.5)
		Remotes.SetupAbilities:FireClient(self.Player, abilities)
	end)
end

function Behavior:Ability1()
	if not self:CanUseAbility("Ability1") then return end
	self.CanUseAbilities = false
	self.AbilityCooldowns.Ability1 = true
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
	Remotes.GiveEffect:FireClient(self.Player, "resist", 1, 3, true)
	Remotes.GiveEffect:FireClient(self.Player, "slow", 1, 2, true)
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
	-- Custom ability logic here
	-- Cooldown
	task.spawn(function()
		Remotes.ActivateAbilityCooldown:FireClient(self.Player, 
			self.Config.Ability3Name, 
			self.Config.Ability3Cooldown or 20)
		task.wait(self.Config.Ability3Cooldown or 20)
		self.AbilityCooldowns.Ability3 = false
	end)
	task.wait(1)
	self.CanUseAbilities = true
end

function Behavior:Ability4()
	if not self:CanUseAbility("Ability4") then return end
	self.CanUseAbilities = false
	self.AbilityCooldowns.Ability4 = true
	-- Custom ability logic here
	-- Cooldown
	task.spawn(function()
		Remotes.ActivateAbilityCooldown:FireClient(self.Player, 
			self.Config.Ability4Name, 
			self.Config.Ability4Cooldown or 25)
		task.wait(self.Config.Ability4Cooldown or 25)
		self.AbilityCooldowns.Ability4 = false
	end)
	task.wait(1)
	self.CanUseAbilities = true
end

-- ===============================================
-- HELPERS
-- ===============================================
function Behavior:CanUseAbility(abilityName)
	return self.CanUseAbilities and 
		self.Humanoid.Health > 0 and 
		not self.AbilityCooldowns[abilityName] and 
		self.Player.PlayerGui.GameGui.Stats.Helpless.Value <= 0 and 
		not self.Character:GetAttribute("ActiveTool")
end

-- ✅ FIXED: Now handles rewards on SERVER SIDE for survivors
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
	for _, connection in ipairs(self.Connections) do
		connection:Disconnect()
	end
	self.Connections = {}
	self.Character = nil
	self.Player = nil
end

return Behavior