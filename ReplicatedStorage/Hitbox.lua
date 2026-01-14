local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local module = {}

--[[
	Creates a hitbox that stays in front of the character regardless of movement direction
	
	@param attachmentOrPart - The part/attachment to track
	@param size - Size of the hitbox
	@param duration - How long the hitbox exists
	@param offset - CFrame offset from the attachment
	@return Part - The hitbox part
]]
function module.create(attachmentOrPart: Instance, size: Vector3, duration: number, offset: CFrame?)
	offset = offset or CFrame.new()

	local hitbox = Instance.new("Part")
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.CastShadow = false
	hitbox.Material = Enum.Material.ForceField
	hitbox.Size = size
	hitbox.BrickColor = BrickColor.new("Really red")

	if ReplicatedStorage.Configuration.VisibleHitboxxes.Value == false then
		hitbox.Transparency = 1
	end

	hitbox.Parent = workspace.GameDebris

	-- Get the character's root part
	local rootPart = nil
	if attachmentOrPart:IsA("Attachment") then
		rootPart = attachmentOrPart.Parent
		-- Traverse up to find HumanoidRootPart if attachment is on another part
		local char = rootPart and rootPart.Parent
		if char then
			rootPart = char:FindFirstChild("HumanoidRootPart") or rootPart
		end
	else
		rootPart = attachmentOrPart
	end

	-- Function to get the hitbox position (always relative to character facing)
	local function getHitboxCFrame()
		if attachmentOrPart:IsA("Attachment") then
			return attachmentOrPart.WorldCFrame * offset
		else
			return attachmentOrPart.CFrame * offset
		end
	end

	-- Set initial position
	hitbox.CFrame = getHitboxCFrame()

	-- Update position continuously
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if hitbox and hitbox.Parent and attachmentOrPart and attachmentOrPart.Parent then
			hitbox.CFrame = getHitboxCFrame()
		else
			if conn then
				conn:Disconnect()
			end
		end
	end)

	-- Cleanup after duration
	task.delay(duration, function()
		if conn then 
			conn:Disconnect() 
		end
		hitbox.CanTouch = false
		TweenService:Create(hitbox, TweenInfo.new(1, Enum.EasingStyle.Linear), {Transparency = 1}):Play()
		Debris:AddItem(hitbox, 1)
	end)

	return hitbox
end

return module