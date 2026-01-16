local players = game:GetService("Players")
local uis = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")

local remotes = replicatedStorage.Remotes

local plr = players.LocalPlayer
local char = plr.Character
local hum = char:FindFirstChildWhichIsA("Humanoid")
local mouse = plr:GetMouse()
local camera = workspace.CurrentCamera

local playerGui = plr.PlayerGui
local gameGui = playerGui.GameGui

char:SetAttribute("CanMove", true)
char:SetAttribute("CanRun", true)
char:SetAttribute("IntendedWalkSpeed", script:GetAttribute("WalkSpeed"))

running = false
stamina = script:GetAttribute("Stamina")

remotes.Damage.OnClientEvent:Connect(function(killer, damage, stunTime)
	if gameGui.Stats.Weakness.Value > 0 then
		damage = math.round(damage * ((gameGui.Stats.Weakness.Value / 5) + 1))
	end
	if gameGui.Stats.Resistance.Value > 0 then
		damage = math.round(damage / ((gameGui.Stats.Resistance.Value / 5) + 1))
	end
	remotes.Damage:FireServer(killer, false, char, damage, stunTime)
end)

function startRun()
	if char:GetAttribute("CanRun") and not running then
		running = true
		char:SetAttribute("IntendedWalkSpeed", (char:GetAttribute("IntendedWalkSpeed") + (script:GetAttribute("RunSpeed") - script:GetAttribute("WalkSpeed"))))
		tweenService:Create(camera, TweenInfo.new(1, Enum.EasingStyle.Sine), {FieldOfView = 80}):Play()
	end
end

function endRun()
	if running then
		running = false
		char:SetAttribute("IntendedWalkSpeed", (char:GetAttribute("IntendedWalkSpeed") - (script:GetAttribute("RunSpeed") - script:GetAttribute("WalkSpeed"))))
		tweenService:Create(camera, TweenInfo.new(1, Enum.EasingStyle.Sine), {FieldOfView = 70}):Play()
	end
end

gameGui.RunButton.MouseButton1Click:Connect(function()
	if running then
		gameGui.RunButton.ImageColor3 = Color3.new(1, 1, 1)
		endRun()
	else
		gameGui.RunButton.ImageColor3 = Color3.new(0.5, 0.5, 0.5)
		startRun()
	end
end)

uis.InputBegan:Connect(function(input, istyping)
	if istyping then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		startRun()
	end
end)

uis.InputEnded:Connect(function(input, istyping)
	if istyping then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		endRun()
	end
end)

char.AttributeChanged:Connect(function(att)
	if att == "IntendedWalkSpeed" then
		tweenService:Create(hum, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {WalkSpeed = char:GetAttribute("IntendedWalkSpeed")}):Play()
	end
end)

task.spawn(function()
	while task.wait() do
		if char:GetAttribute("CanMove") == false then
			tweenService:Create(hum, TweenInfo.new(0, Enum.EasingStyle.Linear), {WalkSpeed = 0}):Play()
		end
	end
end)