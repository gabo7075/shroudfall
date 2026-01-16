local tweenService = game:GetService("TweenService")
local debris = game:GetService("Debris")
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local module = {}

function module.create(cframe: CFrame, size: Vector3, duration: number, shape: Enum.PartType?)
	local hitbox = Instance.new("Part")
	hitbox.CanCollide = false
	hitbox.CastShadow = false
	hitbox.Material = Enum.Material.ForceField
	hitbox.CFrame = cframe
	hitbox.Size = size
	hitbox.BrickColor = BrickColor.new("Really red")

	-- Set shape, default to Block if nil
	hitbox.Shape = shape or Enum.PartType.Block

	if replicatedStorage.Configuration.VisibleHitboxxes.Value == false then
		hitbox.Transparency = 1
	end
	hitbox.Parent = workspace.GameDebris

	runService.RenderStepped:Connect(function()
		if hitbox then
			hitbox.CFrame = cframe
			hitbox.Velocity = Vector3.zero
		end
	end)

	task.delay(duration, function()
		hitbox.CanTouch = false
		tweenService:Create(hitbox, TweenInfo.new(1, Enum.EasingStyle.Linear), {Transparency = 1}):Play()
		debris:AddItem(hitbox, 1)
	end)

	return hitbox
end

return module