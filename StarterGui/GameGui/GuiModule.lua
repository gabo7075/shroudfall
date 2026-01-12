local replicatedStorage = game:GetService("ReplicatedStorage")
local uis = game:GetService("UserInputService")
local player = game:GetService("Players").LocalPlayer
local playerGui = player.PlayerGui
local clones = replicatedStorage.Clones

local module = {}

--=========== COUNTDOWN ===========--

function module.countDown(textLabel: TextLabel, length: number)
	local current = length
	while current > 0 do
		current -= 0.1
		task.wait(0.1)

		if textLabel then
			if current >= 10 then
				textLabel.Text = math.round(current)
			else
				textLabel.Text = math.round(current * 10) / 10
			end
		end
	end
end

--=========== CREATE ABILITY GUI ===========--

function module.createAbilityGui(name: string, image: string, key: string | Enum.KeyCode, currentCharges: number?, maxCharges: number?, instruction: string?)
	local gui = clones.AbilityTemplate:Clone()
	gui.Name = name
	gui.AbilityName.Text = name

	-- Key display
	if typeof(key) == "string" then
		gui.AbilityKey.Text = key
	else
		gui.AbilityKey.Text = uis:GetStringForKeyCode(key)
	end

	-- Icon
	gui.AbilityIcon.Image = image
	gui.Parent = playerGui.GameGui.Abilities

	local chargeLabel = gui:FindFirstChild("AbilityCharge")

	if currentCharges ~= nil then
		if chargeLabel then
			chargeLabel.Visible = true
			chargeLabel.Text = tostring(currentCharges)
		end
		gui:SetAttribute("CurrentCharges", currentCharges)
	else
		if chargeLabel then
			chargeLabel.Visible = false
		end
		-- comportamiento por defecto si no pasaste currentCharges
		gui:SetAttribute("CurrentCharges", 1)
	end

	if maxCharges ~= nil then
		gui:SetAttribute("MaxCharges", maxCharges)
	end

	-- Instruction handling (uses existing AbilityInstruction TextLabel)
	local instructionLabel = gui:FindFirstChild("AbilityInstruction")
	if instructionLabel then
		if instruction then
			instructionLabel.Text = instruction
			instructionLabel.Visible = true
		else
			instructionLabel.Visible = false
		end
	end

	return gui
end

--=========== UPDATE INSTRUCTION (new helper) ===========--
function module.updateInstruction(gui: Frame, newInstruction: string?)
	local instructionLabel = gui:FindFirstChild("AbilityInstruction")
	if not instructionLabel then return end
	if newInstruction and newInstruction ~= "" then
		instructionLabel.Text = newInstruction
		instructionLabel.Visible = true
	else
		instructionLabel.Visible = false
	end
end
--=========== UPDATE ABILITY DISPLAY NAME ===========
function module.updateAbilityDisplayName(gui: Frame, newName: string?)
	local nameLabel = gui:FindFirstChild("AbilityName")
	if not nameLabel then return end
	if newName and newName ~= "" then
		nameLabel.Text = newName
		nameLabel.Visible = true
	else
		nameLabel.Visible = false
	end
end
--=========== UPDATE ABILITY IMAGE ===========
function module.updateAbilityImage(gui: Frame, newImage: string?)
	local icon = gui:FindFirstChild("AbilityIcon")
	if not icon then return end
	if newImage then
		icon.Image = newImage
	end
end

--=========== ABILITY ACTIVATION / COOLDOWN ===========--

function module.activateAbilityGui(name: string, cooldown: number)
	local gui = playerGui.GameGui.Abilities:FindFirstChild(name)
	if not gui then return end

	local timer = gui.AbilityIcon.AbilityTimer
	timer.Text = cooldown
	timer.Visible = true
	gui.AbilityIcon.ImageColor3 = Color3.new(0.5, 0.5, 0.5)

	module.countDown(timer, cooldown)

	timer.Visible = false
	gui.AbilityIcon.ImageColor3 = Color3.new(1, 1, 1)
end

function module.forceCooldown(name: string, cooldown: number)
	local abilities = playerGui:WaitForChild("GameGui"):WaitForChild("Abilities")
	local gui = abilities:WaitForChild(name)

	local timer = gui.AbilityIcon.AbilityTimer
	timer.Visible = true
	gui.AbilityIcon.ImageColor3 = Color3.new(0.5, 0.5, 0.5)

	task.spawn(function()
		module.countDown(timer, cooldown)
		timer.Visible = false
		gui.AbilityIcon.ImageColor3 = Color3.new(1, 1, 1)
	end)
end

--=========== CHARGE CONSUMPTION ===========--

function module.consumeCharge(gui: Frame)
	local current = gui:GetAttribute("CurrentCharges")
	if current == nil then return end  -- solo esto

	current -= 1
	if current < 0 then current = 0 end

	gui:SetAttribute("CurrentCharges", current)

	local label = gui:FindFirstChild("AbilityCharge")
	if label then
		label.Text = tostring(current)
	end

	if current <= 0 then
		gui.AbilityIcon.ImageColor3 = Color3.new(0.3, 0.3, 0.3)
	end
end

--=========== CHARGE RESTORATION ===========--

function module.restoreCharge(gui: Frame, amount: number?)
	amount = amount or 1

	local current = gui:GetAttribute("CurrentCharges")
	local max = gui:GetAttribute("MaxCharges")
	if current == nil then return end

	if max then
		current = math.min(current + amount, max)
	else
		current = current + amount
	end

	gui:SetAttribute("CurrentCharges", current)

	local label = gui:FindFirstChild("AbilityCharge")
	if label then
		label.Text = tostring(current)
	end

	if current > 0 then
		gui.AbilityIcon.ImageColor3 = Color3.new(1, 1, 1)
	end
end

--=========== RESET CHARGES ===========--

function module.resetCharges(gui: Frame)
	local max = gui:GetAttribute("MaxCharges")
	if not max then return end

	gui:SetAttribute("CurrentCharges", max)

	local label = gui:FindFirstChild("AbilityCharge")
	if label then
		label.Text = tostring(max)
	end

	gui.AbilityIcon.ImageColor3 = Color3.new(1, 1, 1)
end

--=========== STATUS EFFECT CLONES ===========--

function module.createEffectClone(name, length, amount)
	local clone = clones.EffectTemplate:Clone()

	if amount then
		clone.StatusName.Text = name .. " " .. amount
	else
		clone.StatusName.Text = name
	end

	clone.Number.Text = length
	clone.Parent = playerGui.GameGui.StatusEffects

	return clone
end

function module.deleteEffectClone(name)
	local clone = playerGui.GameGui.StatusEffects:FindFirstChild(name)
	if clone and clone.Visible then
		clone:Destroy()
	end
end

return module