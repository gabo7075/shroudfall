-- ===============================================
-- LocalScript: StarterPlayer > StarterPlayerScripts > InventoryShopManager
-- ===============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local InventoryData = require(ReplicatedStorage:WaitForChild("InventoryData"))
local player = Players.LocalPlayer

-- Variables globales
local gui
local EquippedKiller
local EquippedKillerSkin
local EquippedSurvivor
local EquippedSurvivorSkin
local categoriesFrame
local mainFrame
local characterFrames = {}
local skinFrames = {}
local navigationStack = {}
local currentCategory = nil
local currentCharacter = nil
local selectedButtons = {}
local ownedData = {Killers = {}, Survivors = {}}

-- Configuración visual
local CONFIG = {
	ButtonSize = UDim2.new(0, 100, 0, 100),
	ButtonPadding = 10,
	CornerRadius = UDim.new(0, 8),
	TextSize = 14,

	Colors = {
		Background = Color3.fromRGB(45, 45, 45),
		Selected = Color3.fromRGB(0, 170, 255),
		Hover = Color3.fromRGB(60, 60, 60),
		BackButton = Color3.fromRGB(200, 50, 50),
		Owned = Color3.fromRGB(0, 200, 0),
		Locked = Color3.fromRGB(100, 100, 100)
	}
}

-- ===============================================
-- REMOTE EVENTS
-- ===============================================

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EquipCharacterRemote = Remotes:WaitForChild("EquipCharacter")
local PurchaseItemRemote = Remotes:WaitForChild("PurchaseItem")

-- ===============================================
-- OWNERSHIP CHECKING
-- ===============================================

local function isFreeItem(categoryName, characterName, skinName)
	-- Free characters and their default skins
	if categoryName == "Killers" then
		if characterName == "Zombie" or characterName == "Alien" then
			return skinName == nil or skinName == "Default"
		end
	elseif categoryName == "Survivors" then
		if characterName == "Dummy" or characterName == "Burras" or characterName == "Rae" then
			return skinName == nil or skinName == "Default"
		end
	end
	return false
end

local function loadOwnedData()
	local HttpService = game:GetService("HttpService")

	-- Load from attributes
	local killersJson = player:GetAttribute("OwnedKillers")
	local survivorsJson = player:GetAttribute("OwnedSurvivors")

	if killersJson and type(killersJson) == "string" then
		ownedData.Killers = HttpService:JSONDecode(killersJson)
	end

	if survivorsJson and type(survivorsJson) == "string" then
		ownedData.Survivors = HttpService:JSONDecode(survivorsJson)
	end
end

local function isCharacterOwned(categoryName, characterName)
	-- Always return true for free items
	if isFreeItem(categoryName, characterName, nil) then
		return true
	end

	local data = categoryName == "Killers" and ownedData.Killers or ownedData.Survivors
	return data[characterName] and data[characterName].Owned == true
end

local function isSkinOwned(categoryName, characterName, skinName)
	-- Always return true for free items
	if isFreeItem(categoryName, characterName, skinName) then
		return true
	end

	local data = categoryName == "Killers" and ownedData.Killers or ownedData.Survivors
	if not data[characterName] then return false end
	if not data[characterName].Skins then return false end
	return data[characterName].Skins[skinName] == true
end

-- ===============================================
-- FUNCIONES DE CREACIÓN DE UI
-- ===============================================

-- Helper function to calculate display order (owned items first)
local function calculateDisplayOrder(originalOrder, isOwned)
	-- Owned items: keep original order (0-9999)
	-- Locked items: add 10000 to push them to the end
	if isOwned then
		return originalOrder
	else
		return originalOrder + 10000
	end
end

local function createButton(parent, data, buttonType, categoryName, characterName)
	local button = Instance.new("ImageButton")
	button.Name = data.Name
	button.Size = CONFIG.ButtonSize
	button.BackgroundColor3 = CONFIG.Colors.Background
	button.BorderSizePixel = 0

	-- Determine ownership first (needed for LayoutOrder calculation)
	local isOwned = false
	local isFree = isFreeItem(categoryName, characterName or data.Name, data.Name)

	if buttonType == "character" then
		isOwned = isCharacterOwned(categoryName, data.Name) or isFree
	elseif buttonType == "skin" then
		isOwned = isSkinOwned(categoryName, characterName, data.Name) or isFree
	elseif buttonType == "category" then
		isOwned = true -- Categories always accessible
	end

	-- Set LayoutOrder: owned items first, then locked items
	button.LayoutOrder = calculateDisplayOrder(data.Price or 0, isOwned)
	button.Parent = parent

	button:SetAttribute("OriginalBgTransparency", 0)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = CONFIG.CornerRadius
	corner.Parent = button

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "ItemImage"
	imageLabel.Size = UDim2.new(1, 0, 1, 0)
	imageLabel.Position = UDim2.new(0, 0, 0, 0)
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = data.ImageId or ""
	imageLabel.ScaleType = Enum.ScaleType.Crop
	imageLabel.Parent = button
	local imgCorner = Instance.new("UICorner")
	imgCorner.CornerRadius = CONFIG.CornerRadius
	imgCorner.Parent = imageLabel

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -10, 0.25, 0)
	nameLabel.Position = UDim2.new(0, 5, 0.75, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = data.DisplayName or data.Name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextSize = CONFIG.TextSize
	nameLabel.TextWrapped = true
	nameLabel.TextScaled = true
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = button

	-- Price/Status label
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "PriceLabel"
	priceLabel.Size = UDim2.new(1, -10, 0.15, 0)
	priceLabel.Position = UDim2.new(0, 5, 0.05, 0)
	priceLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	priceLabel.BackgroundTransparency = 0.3
	priceLabel.TextColor3 = Color3.new(1, 1, 1)
	priceLabel.TextSize = 12
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.TextStrokeTransparency = 0
	priceLabel.Parent = button

	local priceCorner = Instance.new("UICorner")
	priceCorner.CornerRadius = UDim.new(0, 4)
	priceCorner.Parent = priceLabel

	-- Determine ownership and price
	local price = data.Price or 0

	if buttonType == "character" then
		priceLabel.Text = isFree and "FREE" or (isOwned and "OWNED" or "$" .. price)
		priceLabel.TextColor3 = isFree and Color3.fromRGB(255, 255, 0) or (isOwned and CONFIG.Colors.Owned or Color3.new(1, 1, 1))
	elseif buttonType == "skin" then
		priceLabel.Text = isFree and "FREE" or (isOwned and "OWNED" or "$" .. price)
		priceLabel.TextColor3 = isFree and Color3.fromRGB(255, 255, 0) or (isOwned and CONFIG.Colors.Owned or Color3.new(1, 1, 1))
	elseif buttonType == "category" then
		-- Categories are always accessible, hide price label
		priceLabel.Visible = false
	end

	-- Lock overlay for unowned items (but not for categories)
	if not isOwned and not isFree and buttonType ~= "category" then
		local lockOverlay = Instance.new("Frame")
		lockOverlay.Name = "LockOverlay"
		lockOverlay.Size = UDim2.new(1, 0, 1, 0)
		lockOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		lockOverlay.BackgroundTransparency = 0.6
		lockOverlay.BorderSizePixel = 0
		lockOverlay.ZIndex = 2
		lockOverlay.Parent = button

		local lockCorner = Instance.new("UICorner")
		lockCorner.CornerRadius = CONFIG.CornerRadius
		lockCorner.Parent = lockOverlay

		local lockIcon = Instance.new("TextLabel")
		lockIcon.Size = UDim2.new(0.4, 0, 0.4, 0)
		lockIcon.Position = UDim2.new(0.3, 0, 0.3, 0)
		lockIcon.BackgroundTransparency = 1
		lockIcon.Text = "🔒"
		lockIcon.TextSize = 40
		lockIcon.TextScaled = true
		lockIcon.ZIndex = 3
		lockIcon.Parent = lockOverlay
	end

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 0
	stroke.Color = CONFIG.Colors.Selected
	stroke.Parent = button
	stroke.Name = "SelectionStroke"

	button.MouseEnter:Connect(function()
		if button.BackgroundColor3 ~= CONFIG.Colors.Selected then
			button.BackgroundColor3 = CONFIG.Colors.Hover
		end
	end)

	button.MouseLeave:Connect(function()
		if button.BackgroundColor3 ~= CONFIG.Colors.Selected then
			button.BackgroundColor3 = CONFIG.Colors.Background
		end
	end)

	return button
end

local function createBackButton(parent)
	local backButton = Instance.new("TextButton")
	backButton.Name = "BackButton"
	backButton.Size = UDim2.new(0, 100, 0, 40)
	backButton.Position = UDim2.new(0, 10, 0, 10)
	backButton.Text = "← Back"
	backButton.TextColor3 = Color3.new(1, 1, 1)
	backButton.BackgroundColor3 = CONFIG.Colors.BackButton
	backButton.Font = Enum.Font.GothamBold
	backButton.TextSize = 14
	backButton.ZIndex = 10
	backButton.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = CONFIG.CornerRadius
	corner.Parent = backButton

	backButton.MouseButton1Click:Connect(function()
		navigateBack()
	end)

	return backButton
end

local function createScrollingFrame(name, parent)
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = name
	scrollFrame.Size = UDim2.new(1, 0, 1, 0)
	scrollFrame.Position = UDim2.new(0, 0, 0, 0)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.Visible = false
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.Parent = parent

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = CONFIG.ButtonSize
	grid.CellPadding = UDim2.new(0, CONFIG.ButtonPadding, 0, CONFIG.ButtonPadding)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scrollFrame

	grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y)
	end)

	createBackButton(scrollFrame)

	return scrollFrame
end

-- ===============================================
-- FUNCIONES DE NAVEGACIÓN
-- ===============================================

local function hideAllFrames()
	mainFrame.Visible = false
	for _, frame in pairs(characterFrames) do
		frame.Visible = false
	end
	for _, frame in pairs(skinFrames) do
		frame.Visible = false
	end
end

local function tweenFadeIn(frame)
	frame.Visible = true
	for _, descendant in ipairs(frame:GetDescendants()) do
		if descendant:IsA("GuiObject") then
			descendant.BackgroundTransparency = 1
			if descendant:IsA("ImageButton") or descendant:IsA("ImageLabel") then
				descendant.ImageTransparency = 1
			end
			if descendant:IsA("TextButton") or descendant:IsA("TextLabel") then
				descendant.TextTransparency = 1
			end
		end
	end

	task.wait()

	for _, descendant in ipairs(frame:GetDescendants()) do
		if descendant:IsA("GuiObject") then
			local originalBgTrans = descendant:GetAttribute("OriginalBgTransparency") or 
				(descendant.Name == "BackButton" and 0) or 
				(descendant.Name == "PriceLabel" and 0.3) or
				(descendant.Name == "LockOverlay" and 0.6) or 1

			game:GetService("TweenService"):Create(descendant, TweenInfo.new(0.3), {
				BackgroundTransparency = originalBgTrans
			}):Play()

			if descendant:IsA("ImageButton") or descendant:IsA("ImageLabel") then
				game:GetService("TweenService"):Create(descendant, TweenInfo.new(0.3), {
					ImageTransparency = 0
				}):Play()
			end
			if descendant:IsA("TextButton") or descendant:IsA("TextLabel") then
				game:GetService("TweenService"):Create(descendant, TweenInfo.new(0.3), {
					TextTransparency = 0
				}):Play()
			end
		end
	end
end

function navigateToMain()
	hideAllFrames()
	tweenFadeIn(mainFrame)
	navigationStack = {}
	currentCategory = nil
	currentCharacter = nil
end

function navigateToCharacters(category)
	hideAllFrames()

	local frameKey = category.Name .. "_Characters"
	local charFrame = characterFrames[frameKey]

	if charFrame then
		tweenFadeIn(charFrame)
		table.insert(navigationStack, {type = "main"})
		currentCategory = category
		currentCharacter = nil
	end
end

function navigateToSkins(category, character)
	hideAllFrames()

	local frameKey = category.Name .. "_" .. character.Name .. "_Skins"
	local skinsFrame = skinFrames[frameKey]

	if skinsFrame then
		tweenFadeIn(skinsFrame)
		table.insert(navigationStack, {type = "characters", category = category})
		currentCategory = category
		currentCharacter = character
	end
end

function navigateBack()
	if #navigationStack == 0 then
		navigateToMain()
		return
	end

	local previous = table.remove(navigationStack)

	if previous.type == "main" then
		navigateToMain()
	elseif previous.type == "characters" then
		navigateToCharacters(previous.category)
	end
end

-- ===============================================
-- PURCHASE SYSTEM
-- ===============================================

local function purchaseItem(category, character, skin)
	local categoryName = category.Name
	local characterName = character.Name
	local skinName = skin and skin.Name or nil

	-- Check if already owned
	if skinName then
		if isSkinOwned(categoryName, characterName, skinName) or isFreeItem(categoryName, characterName, skinName) then
			warn("Already owned:", skinName)
			return
		end
	else
		if isCharacterOwned(categoryName, characterName) or isFreeItem(categoryName, characterName, nil) then
			warn("Already owned:", characterName)
			return
		end
	end

	-- Call server to purchase
	local result = PurchaseItemRemote:InvokeServer(categoryName, characterName, skinName)

	if result and result.success then
		print("✓ Purchase successful:", result.message)

		-- Reload owned data
		loadOwnedData()

		-- Reinitialize UI to update buttons
		initialize()

		-- Navigate back to the appropriate screen
		if skinName then
			navigateToSkins(category, character)
		else
			navigateToCharacters(category)
		end
	else
		warn("❌ Purchase failed:", result and result.message or "Unknown error")
	end
end

-- ===============================================
-- EQUIP SYSTEM
-- ===============================================

local function updateSelectedButton(category, button)
	local key = category.Name

	if selectedButtons[key] then
		local oldStroke = selectedButtons[key]:FindFirstChild("SelectionStroke")
		if oldStroke then oldStroke.Thickness = 0 end
	end

	selectedButtons[key] = button
	local newStroke = button:FindFirstChild("SelectionStroke")
	if newStroke then newStroke.Thickness = 3 end
end

local function equipSkin(category, character, skin)
	print("Equipando:", category.Name, character.Name, skin.Name)

	if category.Name == "Killers" then
		if EquippedKiller then
			EquippedKiller.Value = character.Name
		end
		if EquippedKillerSkin then
			EquippedKillerSkin.Value = skin.Name
		end
		print("Killer equipado:", character.Name, "con skin:", skin.Name)

	elseif category.Name == "Survivors" then
		if EquippedSurvivor then
			EquippedSurvivor.Value = character.Name
		end
		if EquippedSurvivorSkin then
			EquippedSurvivorSkin.Value = skin.Name
		end
		print("Survivor equipado:", character.Name, "con skin:", skin.Name)
	end

	EquipCharacterRemote:FireServer(category.Name, character.Name, skin.Name)
end

-- ===============================================
-- RESTORE VISUAL SELECTION
-- ===============================================

local function restoreVisualSelection()
	task.wait(0.1)

	-- Killers
	if EquippedKiller and EquippedKillerSkin then
		local killerName = EquippedKiller.Value
		local skinName = EquippedKillerSkin.Value

		for _, category in ipairs(InventoryData.Categories) do
			if category.Name == "Killers" then
				for _, character in ipairs(category.Items) do
					if character.Name == killerName then
						for _, skin in ipairs(character.Skins) do
							if skin.Name == skinName then
								local frameKey = "Killers_" .. killerName .. "_Skins"
								local skinsFrame = skinFrames[frameKey]

								if skinsFrame then
									local skinButton = skinsFrame:FindFirstChild(skinName)
									if skinButton and skinButton:IsA("ImageButton") then
										updateSelectedButton(category, skinButton)
										print("✓ Restaurada selección visual Killer:", killerName, skinName)
									end
								end
								break
							end
						end
						break
					end
				end
				break
			end
		end
	end

	-- Survivors
	if EquippedSurvivor and EquippedSurvivorSkin then
		local survivorName = EquippedSurvivor.Value
		local skinName = EquippedSurvivorSkin.Value

		for _, category in ipairs(InventoryData.Categories) do
			if category.Name == "Survivors" then
				for _, character in ipairs(category.Items) do
					if character.Name == survivorName then
						for _, skin in ipairs(character.Skins) do
							if skin.Name == skinName then
								local frameKey = "Survivors_" .. survivorName .. "_Skins"
								local skinsFrame = skinFrames[frameKey]

								if skinsFrame then
									local skinButton = skinsFrame:FindFirstChild(skinName)
									if skinButton and skinButton:IsA("ImageButton") then
										updateSelectedButton(category, skinButton)
										print("✓ Restaurada selección visual Survivor:", survivorName, skinName)
									end
								end
								break
							end
						end
						break
					end
				end
				break
			end
		end
	end
end

-- ===============================================
-- INICIALIZACIÓN
-- ===============================================

local function cleanup()
	if mainFrame then mainFrame:Destroy() end
	for _, frame in pairs(characterFrames) do
		if frame then frame:Destroy() end
	end
	for _, frame in pairs(skinFrames) do
		if frame then frame:Destroy() end
	end

	characterFrames = {}
	skinFrames = {}
	selectedButtons = {}
	navigationStack = {}
end

function initialize()
	cleanup()

	-- Load ownership data
	loadOwnedData()

	local playerGui = player:WaitForChild("PlayerGui")
	gui = playerGui:WaitForChild("InventoryGui")

	EquippedKiller = player:WaitForChild("EquippedKiller", 10)
	EquippedKillerSkin = player:WaitForChild("EquippedKillerSkin", 10)
	EquippedSurvivor = player:WaitForChild("EquippedSurvivor", 10)
	EquippedSurvivorSkin = player:WaitForChild("EquippedSurvivorSkin", 10)

	-- Update TextFrame
	local textFrame = gui:WaitForChild("TextFrame")
	local srvLabel = textFrame:WaitForChild("SRV")
	local klrLabel = textFrame:WaitForChild("KLR")

	local function updateTextLabels()
		if EquippedSurvivor and EquippedSurvivorSkin then
			srvLabel.Text = string.format(
				"Equipped Survivor: %s | Equipped Skin: %s",
				EquippedSurvivor.Value or "None",
				EquippedSurvivorSkin.Value or "Default"
			)
		end

		if EquippedKiller and EquippedKillerSkin then
			klrLabel.Text = string.format(
				"Equipped Killer: %s | Equipped Skin: %s",
				EquippedKiller.Value or "None",
				EquippedKillerSkin.Value or "Default"
			)
		end

		local leaderstats = player:FindFirstChild("leaderstats")
	end

	EquippedSurvivor.Changed:Connect(updateTextLabels)
	EquippedSurvivorSkin.Changed:Connect(updateTextLabels)
	EquippedKiller.Changed:Connect(updateTextLabels)
	EquippedKillerSkin.Changed:Connect(updateTextLabels)

	updateTextLabels()

	categoriesFrame = gui:WaitForChild("Frame")

	mainFrame = Instance.new("ScrollingFrame")
	mainFrame.Name = "#MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundTransparency = 1
	mainFrame.BorderSizePixel = 0
	mainFrame.ScrollBarThickness = 6
	mainFrame.Parent = categoriesFrame

	local mainGrid = Instance.new("UIGridLayout")
	mainGrid.CellSize = CONFIG.ButtonSize
	mainGrid.CellPadding = UDim2.new(0, CONFIG.ButtonPadding, 0, CONFIG.ButtonPadding)
	mainGrid.SortOrder = Enum.SortOrder.LayoutOrder
	mainGrid.Parent = mainFrame

	local playerUsername = player.Name

	for _, category in ipairs(InventoryData.Categories) do
		local categoryButton = createButton(mainFrame, category, "category", nil, nil)

		categoryButton.MouseButton1Click:Connect(function()
			navigateToCharacters(category)
		end)

		local characterFrame = createScrollingFrame(category.Name .. "_Characters", categoriesFrame)
		characterFrames[category.Name .. "_Characters"] = characterFrame

		for _, character in ipairs(category.Items) do
			local canAccess = not character.Exclusive or InventoryData:HasExclusiveAccess(playerUsername)
			if not canAccess then continue end

			local charButton = createButton(characterFrame, character, "character", category.Name, nil)

			charButton.MouseButton1Click:Connect(function()
				-- Free items are always accessible
				if isFreeItem(category.Name, character.Name, nil) then
					navigateToSkins(category, character)
					return
				end

				local isOwned = isCharacterOwned(category.Name, character.Name)

				if isOwned then
					navigateToSkins(category, character)
				else
					-- Purchase character
					purchaseItem(category, character, nil)
				end
			end)

			local skinsFrame = createScrollingFrame(
				category.Name .. "_" .. character.Name .. "_Skins",
				categoriesFrame
			)
			skinFrames[category.Name .. "_" .. character.Name .. "_Skins"] = skinsFrame

			for _, skin in ipairs(character.Skins) do
				local canAccessSkin = not skin.Exclusive or InventoryData:HasExclusiveAccess(playerUsername)
				if not canAccessSkin then continue end

				local skinButton = createButton(skinsFrame, skin, "skin", category.Name, character.Name)

				skinButton.MouseButton1Click:Connect(function()
					-- Free items are always equippable
					if isFreeItem(category.Name, character.Name, skin.Name) then
						updateSelectedButton(category, skinButton)
						equipSkin(category, character, skin)
						return
					end

					local isOwned = isSkinOwned(category.Name, character.Name, skin.Name)

					if isOwned then
						updateSelectedButton(category, skinButton)
						equipSkin(category, character, skin)
					else
						-- Purchase skin
						purchaseItem(category, character, skin)
					end
				end)
			end
		end
	end

	navigateToMain()
	restoreVisualSelection()
end

-- ===============================================
-- RECONEXIÓN
-- ===============================================

local function onCharacterAdded(character)
	task.wait(0.5)
	initialize()
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Listen for attribute changes (when purchases happen)
player.AttributeChanged:Connect(function(attr)
	if attr == "OwnedKillers" or attr == "OwnedSurvivors" then
		loadOwnedData()
	end
end)

if player.Character then
	initialize()
else
	player.CharacterAdded:Wait()
	initialize()
end