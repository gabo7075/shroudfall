local replicatedStorage = game:GetService("ReplicatedStorage")

local remotes = replicatedStorage.Remotes
local clones = replicatedStorage.Clones

local plr = game:GetService("Players").LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()

local guiMod = require(plr.PlayerGui.GameGui.GuiModule)

local module = {}

-- ✅ Update char reference when character respawns
plr.CharacterAdded:Connect(function(newChar)
	char = newChar
end)

local invisActive = false
local invisAmount = 0

local originalTransparencies = {}

-- Helper: get all visible parts (Part, MeshPart, AND UnionOperation) recursively
local function getVisibleParts(character)
	local parts = {}
	for _, obj in pairs(character:GetDescendants()) do
		if (obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("UnionOperation")) and obj.Transparency < 1 then
			table.insert(parts, obj)
		end
		if obj:IsA("Decal") and obj.Transparency < 1 then
			table.insert(parts, obj)
		end
	end
	return parts
end

-- Note: You can remove the separate Head decal collection in module.invisible()
-- since getVisibleParts() now handles all decals automaticall

-- Helper: get all accessory handles
local function getAccessoryHandles(character)
	local handles = {}
	for _, accessory in pairs(character:GetChildren()) do
		if accessory:IsA("Accessory") then
			local handle = accessory:FindFirstChild("Handle")
			if handle then
				table.insert(handles, handle)
			end
		end
	end
	return handles
end

local function cleanupEffects()
	local gui = plr:WaitForChild("PlayerGui")
	local overlays = gui:FindFirstChild("EffectOverlays")
	if overlays then
		overlays:Destroy()
	end
end

-- Cuando el personaje respawnea
plr.CharacterAdded:Connect(function(newChar)
	char = newChar -- ✅ Already handled above, but kept for clarity
	local hum = char:WaitForChild("Humanoid")
	hum.Died:Connect(cleanupEffects)
end)

local function destroyEffectClone(effectName)
	local statusEffectsFrame = plr.PlayerGui.GameGui:FindFirstChild("StatusEffects")  -- Adjust if parented elsewhere
	if statusEffectsFrame then
		local clone = statusEffectsFrame:FindFirstChild(effectName)
		if clone then
			clone:Destroy()
		end
	end
end

function module.cancelInvisible()
	if not invisActive then return end

	invisActive = false

	-- ✅ Get the parts that were made invisible
	local invisTble = getVisibleParts(char)

	-- ✅ Fire to server to restore transparency for ALL clients
	remotes.StatusEffects.Invisible:FireServer(invisTble, invisAmount, false)

	-- Restore each part to its original transparency locally
	for part, originalTrans in pairs(originalTransparencies) do
		if part and part.Parent then
			part.Transparency = originalTrans
		end
	end

	originalTransparencies = {}
	invisAmount = 0
	destroyEffectClone("Invisibility")
end

-- NEW: Cancel darkness effect
function module.cancelDarkness()
	local effectGui = plr.PlayerGui:FindFirstChild("EffectOverlays")
	if effectGui then
		local overlay = effectGui:FindFirstChild("DarknessOverlay")
		if overlay then
			overlay:Destroy()
		end
	end
	destroyEffectClone("Darkness")  -- Destroy UI clone to remove visually
end

-- NEW: Cancel undetectable effect
function module.cancelUndetectable()
	destroyEffectClone("Undetectable")
	remotes.StatusEffects.Undetectable:FireServer(char, -9999)  -- Large negative to force attribute to 0 (server clamps >=0)
end

function module.speed(length, amount, visible)
	local clone = guiMod.createEffectClone("Speed", length, amount)
	char:SetAttribute("IntendedWalkSpeed", char:GetAttribute("IntendedWalkSpeed") + (2.5 * amount))

	if visible ~= nil then
		clone.Visible = visible
	end

	guiMod.countDown(clone.Number, length)
	clone:Destroy()

	char:SetAttribute("IntendedWalkSpeed", char:GetAttribute("IntendedWalkSpeed") - (2.5 * amount))
end

function module.slow(length, amount, visible)
	local clone = guiMod.createEffectClone("Slowness", length, amount)
	char:SetAttribute("IntendedWalkSpeed", char:GetAttribute("IntendedWalkSpeed") - (2.5 * amount))

	if visible ~= nil then
		clone.Visible = visible
	end

	guiMod.countDown(clone.Number, length)
	clone:Destroy()

	char:SetAttribute("IntendedWalkSpeed", char:GetAttribute("IntendedWalkSpeed") + (2.5 * amount))
end

function module.invisible(length, amount, visible)
	if invisActive then return end

	invisActive = true
	invisAmount = amount
	local clone = guiMod.createEffectClone("Invisibility", length, amount)
	clone.Name = "Invisibility"

	local invisTble = getVisibleParts(char)

	-- ✅ Store original transparency values
	originalTransparencies = {}
	for _, part in ipairs(invisTble) do
		originalTransparencies[part] = part.Transparency
	end

	remotes.StatusEffects.Invisible:FireServer(invisTble, amount)
	guiMod.countDown(clone.Number, length)
	clone:Destroy()

	if invisActive then
		remotes.StatusEffects.Invisible:FireServer(invisTble, amount, false)
		invisActive = false
		originalTransparencies = {}
	end
end

function module.poison(length, amount, visible)
	local clone = guiMod.createEffectClone("Poison", length, amount)
	local poisoned = true
	remotes.StatusEffects.Poison:FireServer(char)

	if visible ~= nil then
		clone.Visible = visible
	end

	task.spawn(function()
		while poisoned do
			if char:FindFirstChildWhichIsA("Humanoid").Health <= amount then
				remotes.SoftDamage:FireServer(char, char:FindFirstChildWhichIsA("Humanoid").Health - 1)
			else
				remotes.SoftDamage:FireServer(char, amount)
			end
			task.wait(1)
		end
	end)

	guiMod.countDown(clone.Number, length)
	clone:Destroy()

	poisoned = false
	remotes.StatusEffects.Poison:FireServer(char, false)
end

function module.bleed(length, amount, visible)
	local clone = guiMod.createEffectClone("Bleeding", length, amount)
	local bleeding = true

	if visible ~= nil then
		clone.Visible = visible
	end

	task.spawn(function()
		while bleeding do
			if char:FindFirstChildWhichIsA("Humanoid").Health <= amount then
				remotes.SoftDamage:FireServer(char, char:FindFirstChildWhichIsA("Humanoid").Health - 1)
			else
				remotes.SoftDamage:FireServer(char, amount)
			end
			task.wait(1)
		end
	end)

	guiMod.countDown(clone.Number, length)
	clone:Destroy()

	bleeding = false
end

function module.burn(length, amount, visible)
	local clone = guiMod.createEffectClone("Burning", length, amount)
	local burning = true
	remotes.StatusEffects.Burn:FireServer(char, length)

	if visible ~= nil then
		clone.Visible = visible
	end

	task.spawn(function()
		while burning do
			remotes.SoftDamage:FireServer(char, amount)
			task.wait(1)
		end
	end)

	guiMod.countDown(clone.Number, length)
	clone:Destroy()

	burning = false
end

function module.infected(length, amount, visible)
	local clone = guiMod.createEffectClone("Infected", length, amount)
	local infected = true
	remotes.StatusEffects.Infected:FireServer(char, length)

	if visible ~= nil then
		clone.Visible = visible
	end

	task.spawn(function()
		while infected do
			remotes.SoftDamage:FireServer(char, amount)
			task.wait(1)
		end
	end)

	guiMod.countDown(clone.Number, length)
	clone:Destroy()

	infected = false
	remotes.StatusEffects.Infected:FireServer(char, false)
end

function module.regen(length, amount, visible)
	local clone = guiMod.createEffectClone("Regeneration", length, amount)
	local regen = true

	if visible ~= nil then
		clone.Visible = visible
	end

	task.spawn(function()
		while regen do
			remotes.SoftDamage:FireServer(char, -amount)
			task.wait(1)
		end
	end)

	guiMod.countDown(clone.Number, length)
	clone:Destroy()

	regen = false
end

function module.weak(length, amount, visible)
	local clone = guiMod.createEffectClone("Weakness", length, amount)
	plr.PlayerGui.GameGui.Stats.Weakness.Value += amount

	if visible ~= nil then
		clone.Visible = visible
	end

	guiMod.countDown(clone.Number, length)
	clone:Destroy()
	plr.PlayerGui.GameGui.Stats.Weakness.Value -= amount
end

function module.resist(length, amount, visible)
	local clone = guiMod.createEffectClone("Resistance", length, amount)
	plr.PlayerGui.GameGui.Stats.Resistance.Value += amount

	if visible ~= nil then
		clone.Visible = visible
	end

	guiMod.countDown(clone.Number, length)
	clone:Destroy()
	plr.PlayerGui.GameGui.Stats.Resistance.Value -= amount
end

function module.helpless(length, amount, visible)
	local clone = guiMod.createEffectClone("Helpless", length, amount)
	plr.PlayerGui.GameGui.Stats.Helpless.Value += amount

	if visible ~= nil then
		clone.Visible = visible
	end

	guiMod.countDown(clone.Number, length)
	clone:Destroy()
	plr.PlayerGui.GameGui.Stats.Helpless.Value -= amount
end

function module.blindness(length, amount, visible)
	local clone = guiMod.createEffectClone("Blindness", length, amount)
	local lighting = game:GetService("Lighting")
	local hum = char:FindFirstChildWhichIsA("Humanoid")

	local blur = Instance.new("BlurEffect")
	blur.Name = "BlindnessBlur"
	blur.Size = 8 * amount
	blur.Parent = lighting

	if visible ~= nil then
		clone.Visible = visible
	end

	local removed = false

	local function cleanupBlur()
		if removed then return end
		removed = true
		task.wait(0.2)
		if blur then
			blur:Destroy()
		end
	end

	hum.Died:Connect(cleanupBlur)
	hum.HealthChanged:Connect(function(hp)
		if hp <= 0 then
			cleanupBlur()
		end
	end)

	guiMod.countDown(clone.Number, length)
	clone:Destroy()
	cleanupBlur()
end

function module.brightness(length, amount, visible)
	local clone = guiMod.createEffectClone("Brightness", length, amount)
	local playerGui = plr.PlayerGui
	local effectGui = playerGui:FindFirstChild("EffectOverlays")

	if not effectGui then
		effectGui = Instance.new("ScreenGui")
		effectGui.Name = "EffectOverlays"
		effectGui.IgnoreGuiInset = true
		effectGui.ResetOnSpawn = false
		effectGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
		effectGui.Parent = playerGui
	end

	local overlay = Instance.new("Frame")
	overlay.Name = "BrightnessOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(1, 1, 1)
	overlay.BackgroundTransparency = math.clamp(1 - 0.18 * amount, 0, 1)
	overlay.ZIndex = 1000
	overlay.Parent = effectGui

	if visible ~= nil then
		clone.Visible = visible
	end

	guiMod.countDown(clone.Number, length)
	clone:Destroy()
	overlay:Destroy()
end

function module.darkness(length, amount, visible)
	local clone = guiMod.createEffectClone("Darkness", length, amount)
	clone.Name = "Darkness"  -- NEW: Ensure clone is named for easy finding/destruction
	local playerGui = plr.PlayerGui
	local effectGui = playerGui:FindFirstChild("EffectOverlays")

	if not effectGui then
		effectGui = Instance.new("ScreenGui")
		effectGui.Name = "EffectOverlays"
		effectGui.IgnoreGuiInset = true
		effectGui.ResetOnSpawn = false
		effectGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
		effectGui.Parent = playerGui
	end

	local overlay = Instance.new("Frame")
	overlay.Name = "DarknessOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = math.clamp(1 - 0.18 * amount, 0, 1)
	overlay.ZIndex = 1000
	overlay.Parent = effectGui

	if visible ~= nil then
		clone.Visible = visible
	end

	guiMod.countDown(clone.Number, length)
	clone:Destroy()
	overlay:Destroy()
end

function module.undetectable(length, amount, visible)
	local clone = guiMod.createEffectClone("Undetectable", length, amount)
	clone.Name = "Undetectable"
	local undetectable = true

	-- Fire to server to set replicated attribute (assume remotes.StatusEffects.Undetectable exists; create if needed)
	-- Server-side: OnServerEvent, char:SetAttribute("Undetectable", (char:GetAttribute("Undetectable") or 0) + amount)
	remotes.StatusEffects.Undetectable:FireServer(char, amount)

	if visible ~= nil then
		clone.Visible = visible
	end

	guiMod.countDown(clone.Number, length)
	clone:Destroy()

	-- Fire to server to remove stacks
	remotes.StatusEffects.Undetectable:FireServer(char, -amount)
end

return module