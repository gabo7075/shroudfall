-- ModuleScript: ReplicatedStorage > InventoryData
local InventoryData = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ===============================================
-- USUARIOS CON ACCESO A CONTENIDO EXCLUSIVO
-- ===============================================

InventoryData.AllowedUsernames = {
	"extermillon09",
	"AlternGabri7075",
	"Player1",
	"Player2",
	"Player3",
}

function InventoryData:HasExclusiveAccess(username)
	for _, name in ipairs(self.AllowedUsernames) do
		if name == username then return true end
	end
	return false
end

-- ===============================================
-- DYNAMIC DATA GENERATION
-- ===============================================

InventoryData.Categories = {}

local function loadConfig(module)
	local success, data = pcall(require, module)
	if success then
		return data
	else
		warn("Failed to load config for: " .. module:GetFullName())
		return nil
	end
end

local function scanPackets()
	local packets = ReplicatedStorage:WaitForChild("Packets")
	local teams = {"Killers", "Survivors"}

	local newCategories = {}

	for _, teamName in ipairs(teams) do
		local teamFolder = packets:FindFirstChild(teamName)
		if not teamFolder then continue end

		local categoryData = {
			Name = teamName,
			DisplayName = teamName,
			-- You can define category images hardcoded here or in a separate config
			ImageId = (teamName == "Killers") and "rbxassetid://107888632746988" or "rbxassetid://95783801257103", 
			Price = 0,
			Items = {}
		}

		for _, charFolder in ipairs(teamFolder:GetChildren()) do
			local charConfigMod = charFolder:FindFirstChild("Config")
			if charConfigMod then
				local charInfo = loadConfig(charConfigMod)
				if charInfo then
					local itemEntry = {
						Name = charFolder.Name, -- Use Folder Name as ID
						DisplayName = charInfo.DisplayName or charFolder.Name,
						ImageId = charInfo.ImageId or "",
						Price = charInfo.Price or 9999,
						Exclusive = charInfo.Exclusive or false,
						Skins = {}
					}

					-- 1. Add Default Skin
					table.insert(itemEntry.Skins, {
						Name = "Default",
						DisplayName = "Default",
						ImageId = charInfo.ImageId, -- Default skin usually shares char image
						Price = 1, -- Usually free/owned
						Exclusive = false
					})

					-- 2. Scan for other Skins
					local skinsFolder = charFolder:FindFirstChild("Skins")
					if skinsFolder then
						for _, skinFolder in ipairs(skinsFolder:GetChildren()) do
							local skinConfigMod = skinFolder:FindFirstChild("Config")
							local skinRig = skinFolder:FindFirstChild("Rig")

							if skinConfigMod then
								local skinInfo = loadConfig(skinConfigMod)
								if skinInfo then
									table.insert(itemEntry.Skins, {
										Name = skinFolder.Name,
										DisplayName = skinInfo.DisplayName or skinFolder.Name,
										ImageId = skinInfo.ImageId or "",
										Price = skinInfo.Price or 9999,
										Exclusive = skinInfo.Exclusive or false
									})
								end
							end
						end
					end

					-- Sort skins by price (optional)
					table.sort(itemEntry.Skins, function(a, b) return a.Price < b.Price end)

					table.insert(categoryData.Items, itemEntry)
				end
			end
		end

		-- Sort characters by price (optional)
		table.sort(categoryData.Items, function(a, b) return a.Price < b.Price end)

		table.insert(newCategories, categoryData)
	end

	InventoryData.Categories = newCategories
	print("Inventory System: Loaded " .. #newCategories .. " categories dynamically.")
end

-- Initialize immediately
scanPackets()

return InventoryData