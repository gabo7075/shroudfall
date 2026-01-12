-- ModuleScript: ReplicatedStorage > Packets > Survivors > [CharacterName] > Config
return {
	-- UI/Shop Data (used by InventoryData)
	DisplayName = "Survivor Template",
	Price = 999,
	ImageId = "rbxassetid://101873701815779",
	Exclusive = false,
	
	-- Character Stats
	Health = 100,
	Stamina = 100,
	WalkSpeed = 16,
	RunSpeed = 22,
	StaminaLoss = 10,  -- Stamina lost per second while running
	StaminaGain = 5,   -- Stamina gained per second while recovering
	
	-- Animation IDs (optional - will use defaults if not specified)
	Animations = {
		Idle = "rbxassetid://139187437656429",
		Walk = "rbxassetid://98546993310870",
		Run = "rbxassetid://101089497691524",
		InjuredIdle = "rbxassetid://96243184323491",
		InjuredWalk = "rbxassetid://119088829288250",
		InjuredRun = "rbxassetid://136315598224264",
	},
	
	-- Ability 1 (Q) - Speed Boost
	Ability1Name = "Speed",
	Ability1Image = "rbxassetid://126902881718435",
	Ability1Cooldown = 10,
	
	-- Ability 2 (E) - Resistance
	Ability2Name = "Resistance",
	Ability2Image = "rbxassetid://97165310608563",
	Ability2Cooldown = 15,
	
	-- Ability 3 (R) - Optional third ability
	-- Ability3Name = "Heal",
	-- Ability3Image = "rbxassetid://...",
	-- Ability3Cooldown = 20,
	
	-- Ability 4 (F) - Optional fourth ability
	-- Ability4Name = "Invisibility",
	-- Ability4Image = "rbxassetid://...",
	-- Ability4Cooldown = 25,
	
	-- Custom Rewards (optional)
	CustomRewards = {
		Ab1Speed = {
			money = 10,
			malice = 0.25,
			messageTemplate = "Speed buffed as %s."
		}
	}
}