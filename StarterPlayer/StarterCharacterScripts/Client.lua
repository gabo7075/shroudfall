-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")
local TweenService = game:GetService("TweenService")

-- Modules
local hitIndicator = require(ReplicatedStorage.HitIndicator)
local statusMod = require(Players.LocalPlayer.PlayerGui.GameGui.StatusEffectsModule)
local gameMod = require(ReplicatedStorage.GameModule)
local lmsmanager = require(ReplicatedStorage.Modules.LMSManager)

-- Remotes
local remotes = ReplicatedStorage.Remotes

-- Player variables
local plr = Players.LocalPlayer
local plrGui = plr.PlayerGui

-- ✅ Initialize character on first load
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:FindFirstChildWhichIsA("Humanoid")
local hrp = char:FindFirstChild("HumanoidRootPart")

-- Utility functions
local function Lerp(a, b, t)
	return a + (b - a) * t
end

-- UI setup
plrGui.GameGui.RunButton.Visible = UserInputService.TouchEnabled

-- Remote events
remotes.ChangeSurvivors.OnClientEvent:Connect(function(name)
	workspace.ChangeSurvivor.ProximityPrompt.ObjectText = "Current Survivor: "..name
	workspace.ChangeSurvivorSkin.ProximityPrompt.ObjectText = "Current Skin: Default"
end)
remotes.ChangeSurvivorSkin.OnClientEvent:Connect(function(name)
	workspace.ChangeSurvivorSkin.ProximityPrompt.ObjectText = "Current Skin: "..name
end)
remotes.ChangeKillers.OnClientEvent:Connect(function(name)
	workspace.ChangeKiller.ProximityPrompt.ObjectText = "Current Killer: "..name
	workspace.ChangeKillerSkin.ProximityPrompt.ObjectText = "Current Skin: Default"
end)
remotes.ChangeKillerSkin.OnClientEvent:Connect(function(name)
	workspace.ChangeKillerSkin.ProximityPrompt.ObjectText = "Current Skin: "..name
end)

remotes.HitIndicator.OnClientEvent:Connect(function(position, damage)
	hitIndicator.create(position, damage)
end)

remotes.GiveEffect.OnClientEvent:Connect(function(name, length, amount, visible)
	if name == "speed" then statusMod.speed(length, amount, visible)
	elseif name == "slow" then statusMod.slow(length, amount, visible)
	elseif name == "invisible" then statusMod.invisible(length, amount, visible)
	elseif name == "poison" then statusMod.poison(length, amount, visible)
	elseif name == "bleed" then statusMod.bleed(length, amount, visible)
	elseif name == "burn" then statusMod.burn(length, amount, visible)
	elseif name == "infected" then statusMod.infected(length, amount, visible)
	elseif name == "regen" then statusMod.regen(length, amount, visible)
	elseif name == "weak" then statusMod.weak(length, amount, visible)
	elseif name == "resist" then statusMod.resist(length, amount, visible)
	elseif name == "helpless" then statusMod.helpless(length, amount, visible)
	elseif name == "blindness" then statusMod.blindness(length, amount, visible)
	elseif name == "brightness" then statusMod.brightness(length, amount, visible)
	elseif name == "darkness" then statusMod.darkness(length, amount, visible)
	elseif name == "undetectable" then statusMod.undetectable(length, amount, visible)
	end
end)

remotes.FindPlayers.OnClientEvent:Connect(function(victims, length)
	gameMod.findPlayers(victims, length)
end)

remotes:WaitForChild("HighlightTargets").OnClientEvent:Connect(function(action, arg1, arg2, arg3)
	if action == "FindPlayers" then
		-- arg1: targets (table), arg2: length, arg3: color
		lmsmanager.findPlayers(arg1, arg2, arg3)
	elseif action == "HighlightVictim" then
		-- arg1: victim (Model/Character), arg2: length, arg3: color
		lmsmanager.highlightVictim(arg1, arg2, arg3)
	end
end)

-- Animation setup
local animNames = {
	idle = { { id = "http://www.roblox.com/asset/?id=180435571", weight = 9 }, { id = "http://www.roblox.com/asset/?id=180435792", weight = 1 } },
	walk = { { id = "http://www.roblox.com/asset/?id=180426354", weight = 10 } },
	run = { { id = "run.xml", weight = 10 } },
	jump = { { id = "http://www.roblox.com/asset/?id=125750702", weight = 10 } },
	fall = { { id = "http://www.roblox.com/asset/?id=180436148", weight = 10 } },
	climb = { { id = "http://www.roblox.com/asset/?id=180436334", weight = 10 } },
	sit = { { id = "http://www.roblox.com/asset/?id=178130996", weight = 10 } },
	toolnone = { { id = "http://www.roblox.com/asset/?id=182393478", weight = 10 } },
	toolslash = { { id = "http://www.roblox.com/asset/?id=129967390", weight = 10 } },
	toollunge = { { id = "http://www.roblox.com/asset/?id=129967478", weight = 10 } },
	wave = { { id = "http://www.roblox.com/asset/?id=128777973", weight = 10 } },
	point = { { id = "http://www.roblox.com/asset/?id=128853357", weight = 10 } },
}

local emoteNames = { wave = false, point = false }

local animTable = {}
local currentAnim = ""
local currentAnimInstance = nil
local currentAnimTrack = nil
local currentAnimKeyframeHandler = nil
local currentAnimSpeed = 1.0
local pose = "Standing"

-- ✅ Store connections to disconnect on respawn
local humConnections = {}

-- Animation functions
local function stopAllAnimations()
	local oldAnim = currentAnim
	if emoteNames[oldAnim] ~= nil and emoteNames[oldAnim] == false then
		oldAnim = "idle"
	end
	currentAnim = ""
	currentAnimInstance = nil
	if currentAnimKeyframeHandler then currentAnimKeyframeHandler:Disconnect() end
	if currentAnimTrack then currentAnimTrack:Stop(); currentAnimTrack:Destroy() end
	return oldAnim
end

local function setAnimationSpeed(speed)
	if speed ~= currentAnimSpeed and currentAnimTrack then
		currentAnimSpeed = speed
		currentAnimTrack:AdjustSpeed(currentAnimSpeed)
	end
end

local function keyFrameReachedFunc(frameName)
	if frameName == "End" then
		local repeatAnim = currentAnim
		if emoteNames[repeatAnim] ~= nil and emoteNames[repeatAnim] == false then
			repeatAnim = "idle"
		end
		local animSpeed = currentAnimSpeed
		playAnimation(repeatAnim, 0.0, hum)
		setAnimationSpeed(animSpeed)
	end
end

function configureAnimationSet(name, fileList)
	animTable[name] = { count = 0, totalWeight = 0, connections = {} }
	for idx, anim in pairs(fileList) do
		animTable[name][idx] = { anim = Instance.new("Animation"), weight = anim.weight }
		animTable[name][idx].anim.Name = name
		animTable[name][idx].anim.AnimationId = anim.id
		animTable[name].count = animTable[name].count + 1
		animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
	end
end

function playAnimation(animName, transitionTime, humanoid)
	local roll = math.random(1, animTable[animName].totalWeight)
	local idx = 1
	while roll > animTable[animName][idx].weight do
		roll = roll - animTable[animName][idx].weight
		idx = idx + 1
	end
	local anim = animTable[animName][idx].anim
	if anim ~= currentAnimInstance then
		if currentAnimTrack then currentAnimTrack:Stop(transitionTime); currentAnimTrack:Destroy() end
		currentAnimSpeed = 1.0
		currentAnimTrack = humanoid:LoadAnimation(anim)
		currentAnimTrack.Priority = Enum.AnimationPriority.Core
		currentAnimTrack:Play(transitionTime)
		currentAnim = animName
		currentAnimInstance = anim
		if currentAnimKeyframeHandler then currentAnimKeyframeHandler:Disconnect() end
		currentAnimKeyframeHandler = currentAnimTrack.KeyframeReached:Connect(keyFrameReachedFunc)
	end
end

-- ✅ Function to setup humanoid events
local function setupHumanoidEvents()
	-- Disconnect old connections
	for _, conn in pairs(humConnections) do
		conn:Disconnect()
	end
	humConnections = {}

	-- Connect new events
	table.insert(humConnections, hum.Running:Connect(function(speed)
		speed /= 1 -- no rig scale
		if speed > 0.01 then
			playAnimation("walk", 0.1, hum)
			if currentAnimInstance and currentAnimInstance.AnimationId == "http://www.roblox.com/asset/?id=180426354" then
				setAnimationSpeed(speed / 14.5)
			end
			pose = "Running"
		else
			if emoteNames[currentAnim] == nil then
				playAnimation("idle", 0.1, hum)
				pose = "Standing"
			end
		end
	end))

	table.insert(humConnections, hum.Jumping:Connect(function() 
		playAnimation("jump", 0.1, hum)
		pose = "Jumping" 
	end))

	table.insert(humConnections, hum.Climbing:Connect(function(speed) 
		playAnimation("climb", 0.1, hum)
		setAnimationSpeed(speed / 12)
		pose = "Climbing" 
	end))

	table.insert(humConnections, hum.FreeFalling:Connect(function() 
		if pose ~= "Jumping" then 
			playAnimation("fall", 0.3, hum) 
		end
		pose = "FreeFall" 
	end))

	table.insert(humConnections, hum.Seated:Connect(function() 
		playAnimation("sit", 0.5, hum)
		pose = "Seated" 
	end))

	table.insert(humConnections, hum.Died:Connect(function() 
		pose = "Dead"
		local killers = Teams.Killers:GetPlayers()
		if #killers == 1 and killers[1].Character then
			workspace.LobbyMusic:Play()
		end
	end))
end

-- Configure animation sets (only once)
for name, fileList in pairs(animNames) do
	configureAnimationSet(name, fileList)
end

-- ✅ Setup initial humanoid events
setupHumanoidEvents()

-- ✅ Handle character respawning
plr.CharacterAdded:Connect(function(newChar)
	-- Stop current animations
	stopAllAnimations()

	-- Update references
	char = newChar
	hum = char:FindFirstChildWhichIsA("Humanoid")
	hrp = char:FindFirstChild("HumanoidRootPart")

	-- Reconnect humanoid events
	setupHumanoidEvents()

	-- Restart idle animation
	playAnimation("idle", 0.1, hum)
	pose = "Standing"
end)

-- Emote chat
Players.LocalPlayer.Chatted:Connect(function(msg)
	local emote = ""
	if string.sub(msg,1,3) == "/e " then emote = string.sub(msg,4)
	elseif string.sub(msg,1,7) == "/emote " then emote = string.sub(msg,8) end
	if pose == "Standing" and emoteNames[emote] ~= nil then
		playAnimation(emote, 0.1, hum)
	end
end)

-- Initialize idle
playAnimation("idle", 0.1, hum)
pose = "Standing"