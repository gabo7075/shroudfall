local module = {}
local serverStorage = game:GetService("ServerStorage")
local lighting = game:GetService("Lighting")

function module.loadMap(mapName)
	local map = serverStorage.Maps:FindFirstChild(mapName):Clone()
	map.Parent = workspace.GameDebris

	-- Reset lighting (FIXED)
	for _, light in pairs(lighting:GetChildren()) do
		if not light:IsA("Atmosphere") and not light:IsA("Sky") and not light:IsA("Bloom") 
			and not light:IsA("BlurEffect") and not light:IsA("ColorCorrectionEffect") 
			and not light:IsA("DepthOfFieldEffect") and not light:IsA("SunRaysEffect") then
			-- Only destroy if it's safe to destroy
			light:Destroy()
		else
			-- For lighting effects, just destroy them
			light:Destroy()
		end
	end

	-- Apply map lighting
	local mapLight = map.Lighting:GetChildren()
	for i = 1, #mapLight do
		mapLight[i].Parent = lighting
	end

	task.wait(5)

	-- Play map music
	local music = map:FindFirstChild("Music")
	if music and music:IsA("Sound") then
		music:Play()
	end

	map.Name = "CurrentMap"

	-- Setup spawns and items
	local spawns = map.Spawns:GetChildren()
	for i = 1, #spawns do
		spawns[i].Transparency = 1
		if spawns[i].Name == "Item" then
			local hasItem = math.random(1, 2)
			if hasItem == 2 then
				local numItems = serverStorage.Items:GetChildren()
				local randomItem = math.random(1, #numItems)
				local item = numItems[randomItem]:Clone()
				item.Parent = workspace.GameDebris
				item.Handle.CFrame = spawns[i].CFrame
			end
		end
	end

	return spawns
end

function module.resetLighting()
	-- Reset lighting (FIXED)
	for _, light in pairs(lighting:GetChildren()) do
		light:Destroy()
	end

	local lobbyLighting = serverStorage.LobbyLighting:GetChildren()
	for i = 1, #lobbyLighting do
		lobbyLighting[i]:Clone().Parent = lighting
	end
end

function module.selectRandomMap()
	local maps = serverStorage.Maps:GetChildren()
	local randomIndex = math.random(1, #maps)
	return maps[randomIndex].Name
end

return module