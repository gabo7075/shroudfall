-- LocalScript: StarterPlayer > StarterCharacterScripts > CharacterClientHandler
-- Universal handler for client-side UI, animations, and input (Killers AND Survivors)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChildWhichIsA("Humanoid")
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local playerGui = player:WaitForChild("PlayerGui")
local gameGui = playerGui:WaitForChild("GameGui")
local barsGui = gameGui:WaitForChild("Bars")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local guiMod = require(gameGui.GuiModule)

-- State
local wantsToRun = false
local abilities = {}
local animations = {}
local animationsReady = false
local characterType = nil -- Will be set by server
local abilitiesRequested = false
local currentState = {
	Health = 100,
	MaxHealth = 100,
	Stamina = 100,
	MaxStamina = 100,
	Running = false,
	WalkSpeed = 16,
	CharacterType = "Unknown"
}

-- debug log removed


-- ===============================================
-- FOOTSTEP HANDLING (moved before animation setup so handlers can connect)
-- ===============================================

local function footStep(frame)
	if frame == "footstep" then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		if humanoid.FloorMaterial == Enum.Material.Grass or 
		   humanoid.FloorMaterial == Enum.Material.LeafyGrass or 
		   humanoid.FloorMaterial == Enum.Material.Snow or 
		   humanoid.FloorMaterial == Enum.Material.Sand or 
		   humanoid.FloorMaterial == Enum.Material.Mud then
			local grassStep = hrp:FindFirstChild("GrassStep")
			if grassStep then grassStep:Play() end
		elseif humanoid.FloorMaterial ~= Enum.Material.Air then
			local groundStep = hrp:FindFirstChild("GroundStep")
			if groundStep then groundStep:Play() end
		end
	end
end


local function createAndLoadAnim(id, priority)
	local animObj = Instance.new("Animation")
	animObj.AnimationId = id
	local track = humanoid:LoadAnimation(animObj)
	track.Priority = priority or Enum.AnimationPriority.Idle
	return track
end

-- Default animation IDs for Killers
local defaultKillerAnimIds = {
	Idle = "rbxassetid://134755063723435",
	Walk = "rbxassetid://131769059732662",
	Run = "rbxassetid://124573520877102",
	StunStart = "rbxassetid://120826985941169",
	StunLoop = "rbxassetid://74533868293322",
	StunEnd = "rbxassetid://81361634197851",
	Punch = "rbxassetid://136672494666856",
}

-- Default animation IDs for Survivors
local defaultSurvivorAnimIds = {
	Idle = "rbxassetid://139187437656429",
	Walk = "rbxassetid://98546993310870",
	Run = "rbxassetid://101089497691524",
	InjuredIdle = "rbxassetid://96243184323491",
	InjuredWalk = "rbxassetid://119088829288250",
	InjuredRun = "rbxassetid://136315598224264",
}

local function setupAnimations(animIds, charType)
	if not charType or charType == "Unknown" then
		return
	end

	characterType = charType
	animIds = animIds or (characterType == "Survivor" and defaultSurvivorAnimIds or defaultKillerAnimIds)
    
	if characterType == "Survivor" then
		-- Survivor animations (with injured states)
		animations.Idle = createAndLoadAnim(animIds.Idle)
		animations.Walk = createAndLoadAnim(animIds.Walk)
		animations.Run = createAndLoadAnim(animIds.Run)
		animations.InjuredIdle = createAndLoadAnim(animIds.InjuredIdle)
		animations.InjuredWalk = createAndLoadAnim(animIds.InjuredWalk)
		animations.InjuredRun = createAndLoadAnim(animIds.InjuredRun)
	else
		-- Killer animations (with stun states)
		animations.Idle = createAndLoadAnim(animIds.Idle)
		animations.Walk = createAndLoadAnim(animIds.Walk)
		animations.Run = createAndLoadAnim(animIds.Run)
		animations.StunStart = createAndLoadAnim(animIds.StunStart, Enum.AnimationPriority.Action4)
		animations.StunLoop = createAndLoadAnim(animIds.StunLoop, Enum.AnimationPriority.Action3)
		animations.StunEnd = createAndLoadAnim(animIds.StunEnd, Enum.AnimationPriority.Action4)
		animations.Punch = createAndLoadAnim(animIds.Punch, Enum.AnimationPriority.Action)
	end

	-- Connect footstep handlers to movement animations (if present)
	if animations.Run and animations.Run.KeyframeReached then
		animations.Run.KeyframeReached:Connect(footStep)
	end
	if animations.Walk and animations.Walk.KeyframeReached then
		animations.Walk.KeyframeReached:Connect(footStep)
	end
	if animations.InjuredRun and animations.InjuredRun.KeyframeReached then
		animations.InjuredRun.KeyframeReached:Connect(footStep)
	end
	if animations.InjuredWalk and animations.InjuredWalk.KeyframeReached then
		animations.InjuredWalk.KeyframeReached:Connect(footStep)
	end

	-- Mark animations as ready so the animation loop can run
	animationsReady = true
end

-- ===============================================
-- REMOTE LISTENERS
-- ===============================================

-- Setup abilities from server
Remotes.SetupAbilities.OnClientEvent:Connect(function(abilityData)
	-- SetupAbilities received
	abilitiesRequested = true
	-- Ensure the Abilities folder exists
	local abilitiesFolder = gameGui:FindFirstChild("Abilities") or gameGui:WaitForChild("Abilities")

	-- Clear existing abilities
	for _, frame in ipairs(abilitiesFolder:GetChildren()) do
		if frame:IsA("Frame") then
			frame:Destroy()
		end
	end

	abilities = {}

	-- Create ability GUIs
	for i, data in ipairs(abilityData) do
		local keyCode = data.Key
		if UserInputService.GamepadEnabled then
			if i == 1 then keyCode = Enum.KeyCode.ButtonY
			elseif i == 2 then keyCode = Enum.KeyCode.ButtonB
			elseif i == 3 then keyCode = Enum.KeyCode.ButtonA
			elseif i == 4 then keyCode = Enum.KeyCode.ButtonX
			end
		else
			-- Convert string to KeyCode if needed
			if data.Key == "M1" then
				keyCode = "M1"
			elseif data.Key == "Q" then
				keyCode = Enum.KeyCode.Q
			elseif data.Key == "E" then
				keyCode = Enum.KeyCode.E
			elseif data.Key == "R" then
				keyCode = Enum.KeyCode.R
			elseif data.Key == "F" then
				keyCode = Enum.KeyCode.F
			end
		end

		local ok, gui = pcall(function()
			return guiMod.createAbilityGui(data.Name, data.Image, keyCode)
		end)

		if not ok or not gui then
			warn("Failed to create ability GUI for", tostring(data.Name))
		else
			gui:SetAttribute("AbilityIndex", i)

			abilities[i] = {
				Name = data.Name,
				GUI = gui,
				Cooldown = data.Cooldown,
				KeyCode = keyCode
			}

			-- Add click handler (support template ImageButton or overlay AbilityIconButton)
			if gui:FindFirstChild("AbilityIcon") and gui.AbilityIcon:IsA("ImageButton") then
				gui.AbilityIcon.MouseButton1Click:Connect(function()
					Remotes.CharacterInput:FireServer("Ability" .. i)
				end)
			else
				local overlay = gui:FindFirstChild("AbilityIconButton")
				if overlay and overlay:IsA("ImageButton") then
					overlay.MouseButton1Click:Connect(function()
						Remotes.CharacterInput:FireServer("Ability" .. i)
					end)
				end
			end
		end
	end
end)

-- Sync state from server
Remotes.SyncCharacterState.OnClientEvent:Connect(function(state)
	currentState = state

	-- Update character type if different
	if state.CharacterType and state.CharacterType ~= characterType then
		characterType = state.CharacterType
		setupAnimations(nil, characterType)
	elseif not characterType then
		-- Infer killer if server includes stun info (killers send stun fields)
		if state.Stunned ~= nil then
			characterType = "Killer"
			setupAnimations(nil, characterType)
		end
	end

	-- Ask server for abilities now that we have character type and animations set
	pcall(function()
		if not abilitiesRequested and Remotes:FindFirstChild("RequestAbilities") then
			Remotes.RequestAbilities:FireServer()
			abilitiesRequested = true
		end
	end)

	-- Update UI
	TweenService:Create(barsGui.Health.Bar, TweenInfo.new(0.1),
		{Size = UDim2.new(state.Health / state.MaxHealth, 0, 1, 0)}):Play()
	TweenService:Create(barsGui.Stamina.Bar, TweenInfo.new(0.1),
		{Size = UDim2.new(state.Stamina / state.MaxStamina, 0, 1, 0)}):Play()

	barsGui.Health.Number.Text = math.floor(state.Health)
	barsGui.Stamina.Number.Text = math.floor(state.Stamina)
end)

-- Play animations
Remotes.PlayAnimation.OnClientEvent:Connect(function(animName)
	if animations[animName] then
		animations[animName]:Play()
	end
end)

-- Stop animations
Remotes.StopAnimation.OnClientEvent:Connect(function(animName)
	if animations[animName] then
		animations[animName]:Stop()
	end
end)

-- Activate cooldown
Remotes.ActivateAbilityCooldown.OnClientEvent:Connect(function(abilityName, cooldown)
	guiMod.activateAbilityGui(abilityName, cooldown)
end)

-- ===============================================
-- INPUT HANDLING
-- ===============================================

local function startRun()
	if not wantsToRun then
		wantsToRun = true
		TweenService:Create(camera, TweenInfo.new(1, Enum.EasingStyle.Sine), {FieldOfView = 80}):Play()
	end
	Remotes.CharacterInput:FireServer("StartRun")
end

local function endRun()
	if wantsToRun then
		wantsToRun = false
		TweenService:Create(camera, TweenInfo.new(1, Enum.EasingStyle.Sine), {FieldOfView = 70}):Play()
	end
	Remotes.CharacterInput:FireServer("EndRun")
end

-- Mobile run button
gameGui.RunButton.MouseButton1Click:Connect(function()
	if wantsToRun then
		endRun()
	else
		startRun()
	end
end)

-- Mouse input (only for killers with M1 attacks)
mouse.Button1Down:Connect(function()
	if characterType == "Killer" then
		Remotes.CharacterInput:FireServer("Ability1")
	end
end)

-- Keyboard/Gamepad input
UserInputService.InputBegan:Connect(function(input, isTyping)
	if isTyping then return end
	
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
		startRun()
	else
		-- Check abilities
		for i, ability in ipairs(abilities) do
			if ability.KeyCode == input.KeyCode then
				Remotes.CharacterInput:FireServer("Ability" .. i)
				break
			end
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, isTyping)
	if isTyping then return end
	
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
		endRun()
	end
end)

-- ===============================================
-- ANIMATION LOOP
-- ===============================================

task.spawn(function()
	while task.wait() do
		if not animationsReady then
			task.wait(0.1)
		else
			if characterType == "Survivor" then
			-- Survivor animation logic (with injured states)
			if currentState.Health > (currentState.MaxHealth / 2) then
				-- Healthy animations
				if animations.InjuredIdle then animations.InjuredIdle:Stop(0.5) end
				if animations.InjuredWalk then animations.InjuredWalk:Stop(0.5) end
				if animations.InjuredRun then animations.InjuredRun:Stop(0.5) end
				
				if humanoid.MoveDirection == Vector3.zero then
					if not animations.Idle.IsPlaying then
						animations.Idle:Play()
						animations.Walk:Stop()
						animations.Run:Stop()
					end
				else
					animations.Idle:Stop(0.5)
					
					if currentState.Running then
						if not animations.Run.IsPlaying then
							animations.Run:Play(0.5)
							animations.Walk:Stop(0.5)
						end
						animations.Run:AdjustSpeed(currentState.WalkSpeed / 22)
					else
						if not animations.Walk.IsPlaying then
							animations.Walk:Play(0.5)
							animations.Run:Stop(0.5)
						end
						animations.Walk:AdjustSpeed(currentState.WalkSpeed / 16)
					end
				end
			else
				-- Injured animations
				animations.Idle:Stop(0.5)
				animations.Walk:Stop(0.5)
				animations.Run:Stop(0.5)
				
				if humanoid.MoveDirection == Vector3.zero then
					if not animations.InjuredIdle.IsPlaying then
						animations.InjuredIdle:Play()
						animations.InjuredWalk:Stop()
						animations.InjuredRun:Stop()
					end
				else
					animations.InjuredIdle:Stop(0.5)
					
					if currentState.Running then
						if not animations.InjuredRun.IsPlaying then
							animations.InjuredRun:Play(0.5)
							animations.InjuredWalk:Stop(0.5)
						end
						animations.InjuredRun:AdjustSpeed(currentState.WalkSpeed / 22)
					else
						if not animations.InjuredWalk.IsPlaying then
							animations.InjuredWalk:Play(0.5)
							animations.InjuredRun:Stop(0.5)
						end
						animations.InjuredWalk:AdjustSpeed(currentState.WalkSpeed / 16)
					end
				end
			end
		else
			-- Killer animation logic (simple)
			if humanoid.MoveDirection == Vector3.zero then
				if not animations.Idle.IsPlaying then
					animations.Idle:Play()
					animations.Walk:Stop()
					animations.Run:Stop()
				end
			else
				animations.Idle:Stop(0.5)
				
				if currentState.Running then
					if not animations.Run.IsPlaying then
						animations.Run:Play(0.5)
						animations.Walk:Stop(0.5)
					end
					animations.Run:AdjustSpeed(currentState.WalkSpeed / 22)
				else
					if not animations.Walk.IsPlaying then
						animations.Walk:Play(0.5)
						animations.Run:Stop(0.5)
					end
					animations.Walk:AdjustSpeed(currentState.WalkSpeed / 16)
				end
			end
			end
		end
	end
end)

-- ===============================================
-- FOOTSTEP HANDLING
-- ===============================================

local function footStep(frame)
	if frame == "footstep" then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		
		if humanoid.FloorMaterial == Enum.Material.Grass or 
		   humanoid.FloorMaterial == Enum.Material.LeafyGrass or 
		   humanoid.FloorMaterial == Enum.Material.Snow or 
		   humanoid.FloorMaterial == Enum.Material.Sand or 
		   humanoid.FloorMaterial == Enum.Material.Mud then
			local grassStep = hrp:FindFirstChild("GrassStep")
			if grassStep then grassStep:Play() end
		elseif humanoid.FloorMaterial ~= Enum.Material.Air then
			local groundStep = hrp:FindFirstChild("GroundStep")
			if groundStep then groundStep:Play() end
		end
	end
end

-- Footstep handlers are connected when animations are setup

-- Show bars GUI
barsGui.Visible = true