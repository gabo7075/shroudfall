-- ModuleScript: ReplicatedStorage > Packets > Survivors > [CharacterName] > Config
return {
	-- UI/Shop Data (used by InventoryData)
	DisplayName = "Survivor Template",
	Price = 999,
	ImageId = "rbxassetid://101873701815779",
	Exclusive = true,

	-- Character Stats
	Class = "Sentinel",
	Health = 100,
	Stamina = 100,
	WalkSpeed = 12,
	RunSpeed = 26,
	StaminaLoss = 10,
	StaminaGain = 20,

	-- Animation IDs (optional - will use defaults if not specified)
	Animations = {
		-- Idle = "rbxassetid://139187437656429",
		-- Walk = "rbxassetid://98546993310870",
		-- Run = "rbxassetid://101089497691524",
		-- InjuredIdle = "rbxassetid://96243184323491",
		-- InjuredWalk = "rbxassetid://119088829288250",
		-- InjuredRun = "rbxassetid://136315598224264",
		Punch = "rbxassetid://136672494666856",
	},
	
	-- Sounds
	Sounds = {
		Speed = {
			Id = "rbxassetid://99173388",
			Volume = 1,
			PlaybackSpeed = 1,
		},
		Hit = {
			Id = "rbxassetid://8595980577",
			Volume = 1,
			PlaybackSpeed = 1,
		},
	},

	-- Ability 1 (Q) - Speed Boost
	Ability1Name = "Speed",
	Ability1Image = "rbxassetid://126902881718435",
	Ability1Cooldown = 8,

	-- Ability 2 (E) - Resistance
	Ability2Name = "Resistance",
	Ability2Image = "rbxassetid://97165310608563",
	Ability2Cooldown = 6,

	-- Ability 3 (R) - Stun
	Ability3Name = "Stun",
	Ability3Image = "rbxassetid://97165310608563",
	Ability3Cooldown = 3,
	Ability3Damage = 30,
	Ability3Knockback = 30,

	-- Custom Rewards (optional)
	CustomRewards = {
		Ab1Speed = {
			money = 10,
			malice = 0.25,
			messageTemplate = "Speed buffed as %s."
		}
	}
}