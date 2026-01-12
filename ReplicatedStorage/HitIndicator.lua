local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")
local debris = game:GetService("Debris")

local module = {}

function module.create(position: Vector3, damage: number)
	local clone = replicatedStorage.Clones.HitIndicator:Clone()
	clone.BillboardGui.TextLabel.Text = damage
	clone.Position = position
	clone.Parent = workspace
	
	tweenService:Create(clone, TweenInfo.new(1, Enum.EasingStyle.Circular), {Position = clone.Position + Vector3.new(math.random(-3, 3), math.random(-3, 3), math.random(-3, 3))}):Play()
	tweenService:Create(clone.BillboardGui.TextLabel, TweenInfo.new(1, Enum.EasingStyle.Linear), {TextTransparency = 1}):Play()
	debris:AddItem(clone, 1)
end

return module