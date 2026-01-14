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
local loadedAnimations = {} -- ✅ Cache for dynamically loaded animations
local animationsReady = false
local characterType = nil
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

-- ===============================================
-- ANIMATION SYSTEM (DYNAMIC)
-- ===============================================

local function createAndLoadAnim(id, priority)
	local animObj = Instance.new("Animation")
	animObj.AnimationId = id
	local track = humanoid:LoadAnimation(animObj)
	track.Priority = priority or Enum.AnimationPriority.Idle
	return track
end

-- ✅ Function to load an animation on-demand
local function loadAnimationOnDemand(animName, animId, priority)
	if not loadedAnimations[animName] then
		local success, track = pcall(function()
			return createAndLoadAnim(animId, priority)
		end)

		if success then
			loadedAnimations[animName] = track
			print("[Client] Loaded animation on-demand:", animName)
		else
			warn("[Client] Failed to load animation:", animName, track)
			return nil
		end
	end

	return loadedAnimations[animName]
end

-- Default animation IDs for Killers
local defaultKillerAnimIds = {
	Idle = "rbxassetid://134755063723435",
	Walk = "rbxassetid://131769059732662",
	Run = "rbxassetid://124573520877102",
	StunStart = "rbxassetid://120826985941169",
	StunLoop = "rbxassetid://74533868293322",
	StunEnd = "rbxassetid://81361634197851",
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

	-- ✅ Load ONLY core movement animations upfront
	-- All other animations (Punch, Swing, etc.) are loaded on-demand

	if characterType == "Survivor" then
		-- Survivor core animations
		animations.Idle = createAndLoadAnim(animIds.Idle)
		animations.Walk = createAndLoadAnim(animIds.Walk)
		animations.Run = createAndLoadAnim(animIds.Run)
		animations.InjuredIdle = createAndLoadAnim(animIds.InjuredIdle)
		animations.InjuredWalk = createAndLoadAnim(animIds.InjuredWalk)
		animations.InjuredRun = createAndLoadAnim(animIds.InjuredRun)
	else
		-- Killer core animations
		animations.Idle = createAndLoadAnim(animIds.Idle)
		animations.Walk = createAndLoadAnim(animIds.Walk)
		animations.Run = createAndLoadAnim(animIds.Run)

		-- Killers need stun animations loaded upfront since they're used by behavior
		if animIds.StunStart then
			animations.StunStart = createAndLoadAnim(animIds.StunStart, Enum.AnimationPriority.Action4)
		end
		if animIds.StunLoop then
			animations.StunLoop = createAndLoadAnim(animIds.StunLoop, Enum.AnimationPriority.Action3)
		end
		if animIds.StunEnd then
			animations.StunEnd = createAndLoadAnim(animIds.StunEnd, Enum.AnimationPriority.Action4)
		end
	end

	-- Connect footstep handlers to movement animations
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

	-- ✅ Store all animation IDs for on-demand loading
	for name, id in pairs(animIds) do
		if not animations[name] then -- Don't overwrite already loaded ones
			loadedAnimations[name] = id -- Store the ID, not the track
		end
	end

	animationsReady = true
end

-- ===============================================
-- REMOTE LISTENERS
-- ===============================================

-- ✅ NEW: Receive animation IDs from server
Remotes.SetupAnimations = Remotes:FindFirstChild("SetupAnimations") or Instance.new("RemoteEvent", Remotes)
Remotes.SetupAnimations.Name = "SetupAnimations"

Remotes.SetupAnimations.OnClientEvent:Connect(function(animIds, charType)
	print("[Client] Received animation setup from server")
	setupAnimations(animIds, charType)
end)

-- Setup abilities from server
Remotes.SetupAbilities.OnClientEvent:Connect(function(abilityData)
	abilitiesRequested = true
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

			-- Add click handler
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
		if state.Stunned ~= nil then
			characterType = "Killer"
			setupAnimations(nil, characterType)
		end
	end

	-- Request abilities if needed
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

-- ✅ IMPROVED: Play animations (with on-demand loading)
Remotes.PlayAnimation.OnClientEvent:Connect(function(animName)
	-- First check if it's already loaded in animations table
	if animations[animName] then
		animations[animName]:Play()
		return
	end

	-- If not, check if we have the ID cached and load it on-demand
	if loadedAnimations[animName] then
		-- If it's a string (ID), load it now
		if type(loadedAnimations[animName]) == "string" then
			local track = loadAnimationOnDemand(animName, loadedAnimations[animName], Enum.AnimationPriority.Action)
			if track then
				track:Play()
			end
			-- If it's already a track, play it
		elseif typeof(loadedAnimations[animName]) == "Instance" then
			loadedAnimations[animName]:Play()
		end
	else
		warn("[Client] Animation not found:", animName)
	end
end)

-- Stop animations
Remotes.StopAnimation.OnClientEvent:Connect(function(animName)
	if animations[animName] then
		animations[animName]:Stop()
	elseif loadedAnimations[animName] and typeof(loadedAnimations[animName]) == "Instance" then
		loadedAnimations[animName]:Stop()
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

-- Mouse input
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
				-- Survivor animation logic
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
				-- Killer animation logic
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

-- Show bars GUI
if not player.Neutral and player.Team ~= nil then
	barsGui.Visible = true
else
	barsGui.Visible = false
end