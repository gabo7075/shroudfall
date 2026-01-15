local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- CONFIG (defaults if Config not found)
local DEFAULT_OUTER_RADIUS = 60
local DEFAULT_L1_MIN = 45
local DEFAULT_L2_MIN = 30
local DEFAULT_L3_MIN = 6
local UPDATE_INTERVAL = 0.12
local CROSSFADE_TIME = 0.5

-- Cache for rig -> config mapping
local rigConfigCache = {}

-- Helper: get character root
local function getCharRoot()
	if player.Character then
		return player.Character:FindFirstChild("HumanoidRootPart") or player.Character.PrimaryPart
	end
	return nil
end

-- Find terror rigs (searches for attribute "TerrorRig" = true)
local function findTerrorRigs()
	local rigs = {}
	for _, v in ipairs(workspace:GetChildren()) do
		if v:IsA("Model") then
			local isTerrorRig = false
			pcall(function()
				isTerrorRig = v:GetAttribute("TerrorRig") == true
			end)
			if isTerrorRig then
				table.insert(rigs, v)
			end
		end
	end
	return rigs
end

-- Get rig position
local function getRigPosition(rig)
	if not rig then return nil end
	if rig.PrimaryPart then return rig.PrimaryPart.Position end
	local hrp = rig:FindFirstChild("HumanoidRootPart")
	if hrp then return hrp.Position end
	for _, d in ipairs(rig:GetDescendants()) do
		if d:IsA("BasePart") then return d.Position end
	end
	return nil
end

-- Get killer name from rig using attribute
local function getKillerNameFromRig(rig)
	if not rig then return nil end
	local killerName = nil
	pcall(function()
		killerName = rig:GetAttribute("CharacterName")
	end)
	return killerName
end

-- Load Config module for a killer
local function loadKillerConfig(killerName)
	if not killerName then return nil end

	local configPath = ReplicatedStorage:FindFirstChild("Packets")
	if not configPath then return nil end

	configPath = configPath:FindFirstChild("Killers")
	if not configPath then return nil end

	configPath = configPath:FindFirstChild(killerName)
	if not configPath then return nil end

	local configModule = configPath:FindFirstChild("Config")
	if not configModule or not configModule:IsA("ModuleScript") then return nil end

	local success, config = pcall(function()
		return require(configModule)
	end)

	return success and config or nil
end

-- Get terror radius configuration from Config
local function getRigConfig(rig)
	local config = {
		outerRadius = DEFAULT_OUTER_RADIUS,
		l1Min = DEFAULT_L1_MIN,
		l2Min = DEFAULT_L2_MIN,
		l3Min = DEFAULT_L3_MIN,
		useVolume = false
	}

	if not rig then return config end

	-- Check cache first
	if rigConfigCache[rig] then
		return rigConfigCache[rig]
	end

	local killerName = getKillerNameFromRig(rig)
	if not killerName then return config end

	local killerConfig = loadKillerConfig(killerName)
	if not killerConfig or not killerConfig.TerrorRadius then return config end

	local tr = killerConfig.TerrorRadius
	config.outerRadius = tr.OuterRadius or DEFAULT_OUTER_RADIUS
	config.l1Min = tr.L1_Min or DEFAULT_L1_MIN
	config.l2Min = tr.L2_Min or DEFAULT_L2_MIN
	config.l3Min = tr.L3_Min or DEFAULT_L3_MIN
	config.useVolume = tr.UseVolume or false

	-- Cache the config
	rigConfigCache[rig] = config

	return config
end

-- ✅ NEW: Get terror sounds from server-sided character model
local function getTerrorSoundsFromRig(rig)
	if not rig then return nil end

	local terrorFolder = rig:FindFirstChild("TerrorSounds")
	if not terrorFolder then
		return nil
	end

	local sounds = {}
	local maxVolumes = {}
	local chaseSoundIndex = nil

	for _, sound in ipairs(terrorFolder:GetChildren()) do
		if sound:IsA("Sound") then
			local layerIndex = sound:GetAttribute("LayerIndex")
			if layerIndex then
				sounds[layerIndex] = sound
				maxVolumes[layerIndex] = sound:GetAttribute("MaxVolume") or 0.6

				if sound:GetAttribute("IsChase") == true then
					chaseSoundIndex = layerIndex
				end
			end
		end
	end

	-- Fallback: if no chase sound marked, use last layer
	if not chaseSoundIndex and #sounds >= 4 then
		chaseSoundIndex = #sounds
	end

	return sounds, maxVolumes, chaseSoundIndex
end

-- Helper: undetectable checks
local function getRigUndetectable(rig)
	local und = 0
	pcall(function()
		und = rig:GetAttribute("Undetectable") or 0
	end)
	return und > 0
end

local function getPlayerUndetectable(player)
	if not player or not player.Character then return false end
	local und = 0
	pcall(function()
		und = player.Character:GetAttribute("Undetectable") or 0
	end)
	return und > 0
end

-- Tween volume safely
local function tweenVolume(sound, target, time)
	if not sound or not sound:IsA("Sound") then return end
	local ok, _ = pcall(function()
		TweenService:Create(sound, TweenInfo.new(time, Enum.EasingStyle.Linear), {Volume = target}):Play()
	end)
	if not ok then
		sound.Volume = target
	end
end

local function ensurePlaying(sound)
	if not sound or not sound:IsA("Sound") then return end
	if not sound.Playing then
		pcall(function() sound:Play() end)
	end
end

local function fadeOutAndStop(sound, fadeTime)
	if not sound or not sound:IsA("Sound") then return end
	tweenVolume(sound, 0, fadeTime)
	delay(fadeTime + 0.05, function()
		if sound and sound:IsA("Sound") then
			pcall(function() sound:Stop() end)
		end
	end)
end

-- Per-rig state
local rigStateCache = {}

local function ensureRigState(rig)
	if rigStateCache[rig] then return rigStateCache[rig] end

	-- ✅ Get sounds from server-sided character model
	local sounds, maxVolumes, chaseSoundIndex = getTerrorSoundsFromRig(rig)
	if not sounds then return nil end

	local config = getRigConfig(rig)
	local state = {
		sounds = sounds,
		maxVolumes = maxVolumes,
		chaseActive = false,
		chaseSoundIndex = chaseSoundIndex,
		config = config
	}

	rigStateCache[rig] = state
	return state
end

local function cleanupRigState(rig)
	rigStateCache[rig] = nil
	rigConfigCache[rig] = nil
end

-- Main loop variables
local accumulator = 0
local activeRigStates = {}
local ambientSound = nil
local isAmbientFaded = false
local lockedChaseRig = nil

-- ✅ Simplified cleanup (no need to destroy sounds anymore - server handles it)
local function cleanTerrorSounds()
	print("[TerrorRadius] Cleaning terror sound states...")

	-- Just reset client-side state tracking
	rigStateCache = {}
	activeRigStates = {}
	rigConfigCache = {}
	lockedChaseRig = nil

	print("[TerrorRadius] Cleanup complete")
end

-- Character respawn cleanup
player.CharacterAdded:Connect(function()
	wait(0.05)
	cleanTerrorSounds()
	activeRigStates = {}
	lockedChaseRig = nil
end)

-- Cleanup when rigs are removed
workspace.ChildRemoved:Connect(function(child)
	if rigStateCache[child] then
		cleanupRigState(child)
	end
end)

-- Main heartbeat loop
RunService.Heartbeat:Connect(function(dt)
	accumulator = accumulator + dt
	if accumulator < UPDATE_INTERVAL then return end
	accumulator = 0

	local charRoot = getCharRoot()
	if not charRoot then return end

	local rigs = findTerrorRigs()
	if #rigs == 0 then
		for rig, st in pairs(rigStateCache) do
			if st and st.sounds then
				for _, s in ipairs(st.sounds) do
					fadeOutAndStop(s, CROSSFADE_TIME)
				end
				st.chaseActive = false
			end
		end
		activeRigStates = {}
		lockedChaseRig = nil
		if ambientSound and isAmbientFaded then
			tweenVolume(ambientSound, 0.1, CROSSFADE_TIME)
			isAmbientFaded = false
		end
		return
	end

	if ambientSound and not ambientSound.Parent then
		ambientSound = nil
		isAmbientFaded = false
	end

	if not ambientSound then
		local currentMap = workspace.GameDebris:FindFirstChild("CurrentMap")
		if currentMap then
			local newSound = currentMap:FindFirstChild("Music")
			if newSound and newSound:IsA("Sound") then
				ambientSound = newSound
				tweenVolume(ambientSound, 0.1, 0)
				isAmbientFaded = false
			end
		end
	end

	local rigsInRange = {}
	local anyActive = false

	for _, rig in ipairs(rigs) do
		local pos = getRigPosition(rig)
		if pos then
			local st = ensureRigState(rig)
			if st then
				local isSelf = (rig == player.Character)

				if not isSelf then
					local rigPlayer = Players:GetPlayerFromCharacter(rig)

					if rigPlayer and rigPlayer.Team == Teams.Killers and player.Team == Teams.Killers then
						continue
					end

					if getRigUndetectable(rig) then
						if activeRigStates[rig] then
							for _, s in ipairs(st.sounds) do
								fadeOutAndStop(s, CROSSFADE_TIME)
							end
							activeRigStates[rig] = nil
							st.chaseActive = false
						end
						if lockedChaseRig == rig then
							lockedChaseRig = nil
						end
						continue
					end
				end

				local nearestDist = (pos - charRoot.Position).Magnitude

				if isSelf then
					local closestDist = math.huge
					local hasDetectableSurvivor = false

					for _, p in ipairs(Players:GetPlayers()) do
						if p ~= player and p.Team == Teams.Survivors and p.Character then
							if getPlayerUndetectable(p) then 
								continue 
							end

							hasDetectableSurvivor = true
							local sRoot = getRigPosition(p.Character)
							if sRoot then
								local d = (charRoot.Position - sRoot).Magnitude
								if d < closestDist then 
									closestDist = d 
								end
							end
						end
					end

					if not hasDetectableSurvivor or closestDist == math.huge then
						nearestDist = st.config.outerRadius + 1
					else
						nearestDist = closestDist
					end
				end

				local cfg = st.config

				if nearestDist < cfg.outerRadius then
					table.insert(rigsInRange, {rig = rig, dist = nearestDist, state = st, config = cfg, isSelf = isSelf})
				else
					if st.chaseActive then
						st.chaseActive = false
					end
					if activeRigStates[rig] then
						for _, s in ipairs(st.sounds) do
							fadeOutAndStop(s, CROSSFADE_TIME)
						end
						activeRigStates[rig] = nil
					end
					if lockedChaseRig == rig then
						lockedChaseRig = nil
					end
				end
			end
		end
	end

	if #rigsInRange == 0 then
		for rig, _ in pairs(activeRigStates) do
			activeRigStates[rig] = nil
		end
		lockedChaseRig = nil
		if ambientSound and isAmbientFaded then
			tweenVolume(ambientSound, 0.1, CROSSFADE_TIME)
			isAmbientFaded = false
		end
		return
	end

	local targetRig = nil

	if lockedChaseRig then
		local lockedRigInRange = false
		for _, rigData in ipairs(rigsInRange) do
			if rigData.rig == lockedChaseRig then
				lockedRigInRange = true
				targetRig = rigData
				break
			end
		end

		if not lockedRigInRange then
			lockedChaseRig = nil
			table.sort(rigsInRange, function(a, b) return a.dist < b.dist end)
			targetRig = rigsInRange[1]
		end
	else
		table.sort(rigsInRange, function(a, b) return a.dist < b.dist end)
		targetRig = rigsInRange[1]
	end

	for _, rigData in ipairs(rigsInRange) do
		if rigData.rig ~= targetRig.rig then
			local st = rigData.state
			if st.chaseActive then
				st.chaseActive = false
			end
			if activeRigStates[rigData.rig] then
				for _, s in ipairs(st.sounds) do
					fadeOutAndStop(s, CROSSFADE_TIME)
				end
				activeRigStates[rigData.rig] = nil
			end
		end
	end

	local rig = targetRig.rig
	local nearestDist = targetRig.dist
	local st = targetRig.state
	local cfg = targetRig.config
	local isSelf = targetRig.isSelf
	local currentActiveIndex = activeRigStates[rig]

	if st.chaseActive then
		if nearestDist >= cfg.outerRadius then
			st.chaseActive = false
			activeRigStates[rig] = nil
			lockedChaseRig = nil
			if st.chaseSoundIndex and st.sounds[st.chaseSoundIndex] then
				fadeOutAndStop(st.sounds[st.chaseSoundIndex], CROSSFADE_TIME)
			end
		else
			for i, s in ipairs(st.sounds) do
				if i == st.chaseSoundIndex then
					ensurePlaying(s)
					local target = (st.maxVolumes and st.maxVolumes[i]) or 0.6
					if s.Volume < target then
						tweenVolume(s, target, 0.1)
					end
				else
					if s.Volume > 0 or s.Playing then
						s.Volume = 0
						pcall(function() s:Stop() end)
					end
				end
			end
			anyActive = true
			return
		end
	end

	local desiredIndex = nil

	if nearestDist > cfg.outerRadius then
		if currentActiveIndex ~= nil then
			for _, s in ipairs(st.sounds) do
				fadeOutAndStop(s, CROSSFADE_TIME)
			end
			activeRigStates[rig] = nil
		end
	elseif isSelf then
		if nearestDist <= cfg.l3Min then
			desiredIndex = st.chaseSoundIndex or 4
			st.chaseActive = true
			lockedChaseRig = rig
		end
	else
		if nearestDist <= cfg.l3Min then
			desiredIndex = st.chaseSoundIndex or 4
			st.chaseActive = true
			lockedChaseRig = rig
		elseif nearestDist < cfg.l2Min then
			desiredIndex = 3
		elseif nearestDist < cfg.l1Min then
			desiredIndex = 2
		else
			desiredIndex = 1
		end
	end

	if desiredIndex and desiredIndex ~= currentActiveIndex then
		for i, s in ipairs(st.sounds) do
			if i == desiredIndex then
				if not s.Playing then
					s.TimePosition = 0
				end
				ensurePlaying(s)
				local target = (st.maxVolumes and st.maxVolumes[i]) or 0.6
				tweenVolume(s, target, CROSSFADE_TIME)
			else
				if s.Playing or s.Volume > 0 then
					fadeOutAndStop(s, CROSSFADE_TIME)
				end
			end
		end
		activeRigStates[rig] = desiredIndex
		anyActive = true
	elseif desiredIndex and desiredIndex == currentActiveIndex then
		local currentSound = st.sounds[desiredIndex]
		if currentSound and not currentSound.Playing then
			ensurePlaying(currentSound)
			local target = (st.maxVolumes and st.maxVolumes[desiredIndex]) or 0.6
			tweenVolume(currentSound, target, 0.1)
		end
		anyActive = true
	end

	if ambientSound then
		if anyActive and not isAmbientFaded then
			tweenVolume(ambientSound, 0, CROSSFADE_TIME)
			isAmbientFaded = true
		elseif not anyActive and isAmbientFaded then
			tweenVolume(ambientSound, 0.1, CROSSFADE_TIME)
			isAmbientFaded = false
		end
	end
end)