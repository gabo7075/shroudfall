-- ServerScript: ServerScriptService > RemoteSetup
-- Creates necessary remote events for the new behavior system

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get or create Remotes folder
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
end

-- ===============================================
-- CREATE REMOTE EVENTS
-- ===============================================

local function createRemote(name, remoteType)
	local existing = Remotes:FindFirstChild(name)
	if existing then return existing end
	
	local remote
	if remoteType == "Event" then
		remote = Instance.new("RemoteEvent")
	elseif remoteType == "Function" then
		remote = Instance.new("RemoteFunction")
	end
	
	remote.Name = name
	remote.Parent = Remotes
	return remote
end

-- Character behavior remotes
createRemote("CharacterInput", "Event")         -- Client → Server: Input handling
createRemote("SyncCharacterState", "Event")     -- Server → Client: State sync
createRemote("SetupAbilities", "Event")         -- Server → Client: Ability UI setup
createRemote("PlayAnimation", "Event")          -- Server → Client: Play animation
createRemote("StopAnimation", "Event")          -- Server → Client: Stop animation
createRemote("ActivateAbilityCooldown", "Event") -- Server → Client: Start cooldown UI

createRemote("RequestAbilities", "Event") -- Client → Server: ask server to resend ability data

-- Keep existing remotes for compatibility
createRemote("GiveReward", "Event")
createRemote("HitIndicator", "Event")
createRemote("GiveEffect", "Event")
createRemote("PlaySound", "Event")
createRemote("Damage", "Event")
createRemote("SoftDamage", "Event")
createRemote("Heal", "Event")
createRemote("DamageKnockback", "Event")
createRemote("FindPlayers", "Event")
createRemote("Connect", "Event")
createRemote("ShowObj", "Event")
createRemote("Delete", "Event")

-- Status effect remotes
local statusEffects = Remotes:FindFirstChild("StatusEffects")
if not statusEffects then
	statusEffects = Instance.new("Folder")
	statusEffects.Name = "StatusEffects"
	statusEffects.Parent = Remotes
end

local function createStatusRemote(name)
	local existing = statusEffects:FindFirstChild(name)
	if existing then return existing end
	
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = statusEffects
	return remote
end

createStatusRemote("Invisible")
createStatusRemote("Poison")
createStatusRemote("Burn")
createStatusRemote("Infected")
createStatusRemote("Undetectable")

print("✓ Remote events setup complete")