local tweenService = game:GetService("TweenService")
local debris = game:GetService("Debris")
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local module = {}

function module.create(attachmentOrPart: Instance, size: Vector3, duration: number, offset: CFrame?)
	offset = offset or CFrame.new()

	local hitbox = Instance.new("Part")
	hitbox.Anchored = true  -- ✅ ADD THIS LINE
	hitbox.CanCollide = false
	hitbox.CastShadow = false
	hitbox.Material = Enum.Material.ForceField
	hitbox.Size = size
	hitbox.BrickColor = BrickColor.new("Really red")
	if replicatedStorage.Configuration.VisibleHitboxxes.Value == false then
		hitbox.Transparency = 1
	end
	hitbox.Parent = workspace.GameDebris

	-- Continuously update position based on the attachment's world position
	local conn
	conn = runService.Heartbeat:Connect(function()
		if hitbox and hitbox.Parent and attachmentOrPart and attachmentOrPart.Parent then
			-- Get live CFrame from attachment or part
			local liveCFrame = attachmentOrPart:IsA("Attachment") and attachmentOrPart.WorldCFrame or attachmentOrPart.CFrame
			hitbox.CFrame = liveCFrame * offset
		else
			if conn then
				conn:Disconnect()
			end
		end
	end)

	task.delay(duration, function()
		if conn then conn:Disconnect() end
		hitbox.CanTouch = false
		tweenService:Create(hitbox, TweenInfo.new(1, Enum.EasingStyle.Linear), {Transparency = 1}):Play()
		debris:AddItem(hitbox, 1)
	end)

	return hitbox
end

return module