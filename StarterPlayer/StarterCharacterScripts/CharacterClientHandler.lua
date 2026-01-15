-- ============================================
-- FILE 1: CharacterClientHandler.lua (FULL REPLACEMENT)
-- ============================================

-- LocalScript: StarterPlayer > StarterCharacterScripts > CharacterClientHandler
-- Universal handler for client-side UI and input (Killers AND Survivors)
-- NOTE: Animation loading is handled by Behavior modules, not here

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
local characterType = nil
local animations = {}

-- ===============================================
-- ABILITY SETUP FROM SERVER
-- ===============================================
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

	-- Update local characterType for input logic
	if state.CharacterType and state.CharacterType ~= "Unknown" then
		characterType = state.CharacterType
	elseif not characterType then
		if state.Stunned ~= nil then
			characterType = "Killer"
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

-- Activate cooldown
Remotes.ActivateAbilityCooldown.OnClientEvent:Connect(function(abilityName, cooldown)
	guiMod.activateAbilityGui(abilityName, cooldown)
end)

-- ===============================================
-- ANIMATION HANDLERS (minimal)
-- ===============================================

local function createAndLoadAnim(id, priority)
	local animObj = Instance.new("Animation")
	animObj.AnimationId = id
	local track = humanoid:LoadAnimation(animObj)
	track.Priority = priority or Enum.AnimationPriority.Action
	return track
end

-- Server behaviors fire this to the client to load animations
if Remotes:FindFirstChild("LoadAnimations") then
	Remotes.LoadAnimations.OnClientEvent:Connect(function(animTable)
		if not animTable then return end

		for name, id in pairs(animTable) do
			if not animations[name] and id and id ~= "" then
				local priority = Enum.AnimationPriority.Action
				if name == "Idle" then
					priority = Enum.AnimationPriority.Idle
				elseif name == "Walk" or name == "Run" or name:match("Injured") then
					priority = Enum.AnimationPriority.Core
				end

				local ok, track = pcall(function()
					return createAndLoadAnim(id, priority)
				end)

				if ok and track then
					animations[name] = track
					if track.KeyframeReached then
						pcall(function()
							track.KeyframeReached:Connect(function(frame)
								if frame == "footstep" then
									local hrp = character:FindFirstChild("HumanoidRootPart")
									if hrp then
										local groundStep = hrp:FindFirstChild("GroundStep")
										if groundStep then groundStep:Play() end
									end
								end
							end)
						end)
					end
				else
					warn("[Client] Failed loading animation:", name, id)
				end
			end
		end

		-- Notify server that animations finished loading (once)
		pcall(function()
			if Remotes:FindFirstChild("AnimationsLoaded") then
				Remotes.AnimationsLoaded:FireServer()
			end
		end)
	end)
end

if Remotes:FindFirstChild("PlayAnimation") then
	Remotes.PlayAnimation.OnClientEvent:Connect(function(animName)
		if not animName then return end
		local track = animations[animName]
		if track then
			track:Play()
		else
			warn("[Client] PlayAnimation: track not found:", animName)
		end
	end)
end

if Remotes:FindFirstChild("StopAnimation") then
	Remotes.StopAnimation.OnClientEvent:Connect(function(animName)
		if not animName then return end
		local track = animations[animName]
		if track then
			track:Stop()
		end
	end)
end

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

-- Show bars GUI
if not player.Neutral and player.Team ~= nil then
	barsGui.Visible = true
else
	barsGui.Visible = false
end