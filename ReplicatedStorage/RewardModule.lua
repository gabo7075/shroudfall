-- RewardModule
-- Place in ReplicatedStorage

local module = {}

-- Define reward types
module.DefaultRewards = {
	KilledSurvivor = {money = 50, malice = 0, message = "Killed A Survivor."}, --Currently not working
	SurvivorDisconnected = {money = 50, malice = 0, message = "Survivor Disconnected."}, --Currently not working
	SurvivorHit = {money = 15, malice = 0, message = "Hit a survivor."}
}

-- Function to create a reward pop-up (client-side)
function module.showRewardPopup(player, message, money, malice)
	money = money or 0
	malice = malice or 0
	local playerGui = player:WaitForChild("PlayerGui")
	local rewardGui = playerGui:FindFirstChild("RewardGui")

	if not rewardGui then
		rewardGui = Instance.new("ScreenGui")
		rewardGui.Name = "RewardGui"
		rewardGui.ResetOnSpawn = false
		rewardGui.DisplayOrder = 100
		rewardGui.Parent = playerGui
	end

	-- Count existing notifications
	local existingNotifs = {}
	for _, child in ipairs(rewardGui:GetChildren()) do
		if child:IsA("TextLabel") and child.Name == "RewardNotification" then
			table.insert(existingNotifs, child)
		end
	end

	-- Remove oldest if we have 3 already
	if #existingNotifs >= 3 then
		existingNotifs[1]:Destroy()
		table.remove(existingNotifs, 1)
	end

	-- Move existing notifications up
	for i, notif in ipairs(existingNotifs) do
		notif:TweenPosition(
			UDim2.new(0.5, 0, 0.1 - (0.08 * (#existingNotifs - i + 1)), 0),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.3,
			true
		)
	end

	-- Create new notification
	local notification = Instance.new("TextLabel")
	notification.Name = "RewardNotification"
	notification.Size = UDim2.new(0, 400, 0, 50)
	notification.Position = UDim2.new(0.5, 0, 0.1, 0)  -- Moves it further up
	notification.AnchorPoint = Vector2.new(0.5, 0.5)
	notification.BackgroundTransparency = 1
	notification.Font = Enum.Font.GothamBold
	notification.TextSize = 20
	notification.TextColor3 = Color3.new(1, 1, 1)
	notification.TextStrokeColor3 = Color3.new(0, 0, 0)
	notification.TextStrokeTransparency = 0
	-- Crear texto del mensaje
	local rewardText
	if malice > 0 then
		rewardText = string.format("%s (+$%d, +%.2f Malice)", message, money, malice)
	else
		rewardText = string.format("%s (+$%d)", message, money)
	end

	notification.Text = rewardText
	notification.TextTransparency = 1
	notification.Parent = rewardGui

	-- Fade in
	notification:TweenPosition(
		UDim2.new(0.5, 0, 0.1, 0),  -- Same as initial
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Back,
		0.5,
		true
	)

	local tweenService = game:GetService("TweenService")
	tweenService:Create(notification, TweenInfo.new(0.5), {TextTransparency = 0}):Play()

	-- Wait and fade out
	task.delay(3, function()
		tweenService:Create(notification, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		task.wait(0.5)
		notification:Destroy()
	end)
end

return module