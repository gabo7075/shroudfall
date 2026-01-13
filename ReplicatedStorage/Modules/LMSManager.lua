local module = {}

local tweenService = game:GetService("TweenService")
local debris = game:GetService("Debris")
local teams = game:GetService("Teams")

function module.findPlayers(plrs, length)
	for i = 1, #plrs do
		task.spawn(function()
			local character = plrs[i].Character

			if character then
				local und = character:GetAttribute("Undetectable") or 0
				if und > 0 then return end

				local high = Instance.new("Highlight")
				if plrs[i].Team == teams.Survivors then
					high.OutlineColor = Color3.fromRGB(255, 255, 0)
					high.FillColor = Color3.fromRGB(255, 255, 0)
				elseif plrs[i].Team == teams.Killers then
					high.OutlineColor = Color3.fromRGB(255, 0, 0)
					high.FillColor = Color3.fromRGB(255, 0, 0)
				end
				high.FillTransparency = 1
				high.OutlineTransparency = 1
				high.Parent = character

				tweenService:Create(high, TweenInfo.new(1, Enum.EasingStyle.Linear), {
					FillTransparency = 0.5,
					OutlineTransparency = 0
				}):Play()

				task.wait(length)

				tweenService:Create(high, TweenInfo.new(1, Enum.EasingStyle.Linear), {
					FillTransparency = 1,
					OutlineTransparency = 1
				}):Play()
				debris:AddItem(high, 1)
			end
		end)
	end
end

function module.highlightVictim(victim, length)
	task.spawn(function()
		if victim then
			local und = victim:GetAttribute("Undetectable") or 0
			if und > 0 then return end

			local high = Instance.new("Highlight")
			high.OutlineColor = Color3.fromRGB(255, 255, 0)
			high.FillColor = Color3.fromRGB(255, 255, 0)
			high.FillTransparency = 1
			high.OutlineTransparency = 1
			high.Parent = victim

			tweenService:Create(high, TweenInfo.new(1, Enum.EasingStyle.Linear), {
				FillTransparency = 0.5,
				OutlineTransparency = 0
			}):Play()

			task.wait(length)

			tweenService:Create(high, TweenInfo.new(1, Enum.EasingStyle.Linear), {
				FillTransparency = 1,
				OutlineTransparency = 1
			}):Play()
			debris:AddItem(high, 1)
		end
	end)
end

-- Check if conditions for special LMS music are met
function module.checkLMSConditions(killer, survivor)
	if not killer or not survivor then
		return "LastManStanding", 80
	end

	-- Anti Burras vs Burras
	if killer.Team == teams.Killers and killer.EquippedKiller.Value == "Anti Burras"
		and survivor.Team == teams.Survivors and survivor.EquippedSurvivor.Value == "Burras"
		and killer.EquippedKillerSkin.Value ~= "c00l"
		and killer.EquippedKillerSkin.Value ~= "pasar13" then
		return "TheEvilClone", 100
	end

	-- Zorath vs Ben
	if killer.Team == teams.Killers and killer.EquippedKiller.Value == "Zorath"
		and survivor.Team == teams.Survivors and survivor.EquippedSurvivor.Value == "Ben" then
		return "Slaughter", 96
	end
	
	-- Jeff vs Jane
	if killer.Team == teams.Killers and killer.EquippedKiller.Value == "Jeff The Killer"
		and survivor.Team == teams.Survivors and survivor.EquippedSurvivor.Value == "Jane" 
		and killer.EquippedKillerSkin.Value ~= "Eyeless Jack" then
		return "SDAMOS", 92
	end

	-- The Retributor vs Leo/Joseph/Gabo/Extermillon
	if killer.Team == teams.Killers 
		and killer.EquippedKiller.Value == "The Retributor"
		and survivor.Team == teams.Survivors
		and (survivor.EquippedSurvivor.Value == "Leo"
			or survivor.EquippedSurvivor.Value == "Joseph"
			or survivor.EquippedSurvivor.Value == "Gabo"
			or survivor.EquippedSurvivor.Value == "Extermillon") then
		return "NewBlood", 102
	end

	-- N43 (gatoleandro2 skin) vs Leo
	if killer.Team == teams.Killers and killer.EquippedKiller.Value == "N43"
		and survivor.Team == teams.Survivors and survivor.EquippedSurvivor.Value == "Leo"
		and killer.EquippedKillerSkin.Value == "gatoleandro2" then
		return "Paradox", 91
	end

	-- r3ADe vs Jkiins11
	if killer.Team == teams.Killers and killer.EquippedKiller.Value == "r3ADe"
		and survivor.Team == teams.Survivors and survivor.EquippedSurvivor.Value == "Jkiins11" then
		return "Scammed", 87
	end

	-- Default
	return "LastManStanding", 80
end

-- Stop all LMS music tracks
function module.stopAllLMSMusic()
	local lmsFolder = workspace:FindFirstChild("LMS")
	if not lmsFolder then return end

	local tracks = {"LastManStanding", "TheEvilClone", "Slaughter", "Paradox", "Patches", "NewBlood", "Scammed", "SDAMOS"}
	for _, trackName in ipairs(tracks) do
		local track = lmsFolder:FindFirstChild(trackName)
		if track and track:IsA("Sound") then
			track:Stop()
		end
	end
end

return module