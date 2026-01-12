-- ModuleScript: ReplicatedStorage > Packets > Killers > [CharacterName] > Config
return {
	-- UI/Shop Data (used by InventoryData)
	DisplayName = "Killer Template",
	Price = 9999,
	ImageId = "rbxassetid://101873701815779",
	Exclusive = true,
	
	-- Character Stats
	Health = 100,
	Stamina = 100,
	WalkSpeed = 16,
	RunSpeed = 22,
	StaminaLoss = 10,  -- Stamina lost per second while running
	StaminaGain = 5,   -- Stamina gained per second while recovering
	
	-- Animation IDs (optional - will use defaults if not specified)
	Animations = {
		Idle = "rbxassetid://134755063723435",
		Walk = "rbxassetid://131769059732662",
		Run = "rbxassetid://124573520877102",
		StunStart = "rbxassetid://120826985941169",
		StunLoop = "rbxassetid://74533868293322",
		StunEnd = "rbxassetid://81361634197851",
		Punch = "rbxassetid://136672494666856",
	},
	
	-- Ability 1 (M1/Basic Attack)
	Ability1Name = "Punch",
	Ability1Image = "rbxassetid://123352469952776",
	Ability1Cooldown = 1.6,
	Ability1Damage = 25,
	Ability1Knockback = 15,
	Ability1AnimLength = 1,
	
	-- Ability 2 (Q)
	Ability2Name = "Speed Boost",
	Ability2Image = "rbxassetid://82229308135638",
	Ability2Cooldown = 4,
	
	-- Ability 3 (E)
	Ability3Name = "Heavy Attack",
	Ability3Image = "rbxassetid://106226036311010",
	Ability3Cooldown = 1.6,
	Ability3Damage = 30,
	Ability3Knockback = 30,
	Ability3AnimLength = 1,
	
	-- Ability 4 (R)
	Ability4Name = "Locate Survivors",
	Ability4Image = "rbxassetid://77080976212074",
	Ability4Cooldown = 7,
	
	-- Custom Rewards (optional)
	CustomRewards = {
		Ability3Hit = {
			money = 60,
			malice = 0,
			messageTemplate = "Attacked survivor with special ability as %s."
		}
	},
	
	-- Terror Radius Configuration (optional - for TerrorRadius script)
	TerrorRadius = {
		OuterRadius = 60,
		L1_Min = 45,
		L2_Min = 30,
		L3_Min = 6,
		UseVolume = false
	}
}