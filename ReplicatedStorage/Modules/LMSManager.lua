local module = {}

local tweenService = game:GetService("TweenService")
local debris = game:GetService("Debris")
local teams = game:GetService("Teams")
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Referencia segura al RemoteEvent
local Remotes = replicatedStorage:WaitForChild("Remotes")
local HighlightEvent = Remotes:FindFirstChild("HighlightTargets")

--[[ 
    Función Universal: findPlayers
    - Si se llama desde el SERVIDOR: Requiere el argumento 'viewer' (Player). Manda señal al cliente.
    - Si se llama desde el CLIENTE: Dibuja los efectos visuales localmente.
]]
function module.findPlayers(viewerOrTargets, targetsOrLength, lengthOrColor, colorOverride)
    if runService:IsServer() then
        -- Lógica de Servidor: Redirigir al cliente específico
        local viewer = viewerOrTargets -- El jugador que VERÁ el highlight (ej: Killer)
        local targets = targetsOrLength -- Lista de jugadores a marcar
        local duration = lengthOrColor
        local color = colorOverride
        
        if viewer and HighlightEvent then
            HighlightEvent:FireClient(viewer, "FindPlayers", targets, duration, color)
        end
    else
        -- Lógica de Cliente: Crear visuales
        local targets = viewerOrTargets -- En cliente, el primer arg son los objetivos
        local length = targetsOrLength
        local color = lengthOrColor
        
        for i = 1, #targets do
            task.spawn(function()
                local player = targets[i]
                if not player or not player.Character then return end
                
                module._createLocalHighlight(player.Character, length, player.Team, color)
            end)
        end
    end
end

--[[ 
    Función Universal: highlightVictim
    Igual que arriba, pero para un solo objetivo.
]]
function module.highlightVictim(viewerOrVictim, victimOrLength, lengthOrColor, colorOverride)
    if runService:IsServer() then
        local viewer = viewerOrVictim
        local victim = victimOrLength
        local duration = lengthOrColor
        local color = colorOverride
        
        if viewer and HighlightEvent then
            -- Pasamos al victim dentro de una tabla para reusar lógica si queremos, 
            -- o mandamos un evento distinto. Aquí mandamos "HighlightVictim"
            HighlightEvent:FireClient(viewer, "HighlightVictim", victim, duration, color)
        end
    else
        local victim = viewerOrVictim
        local length = victimOrLength
        local color = lengthOrColor
        
        if victim then
             module._createLocalHighlight(victim, length, nil, color)
        end
    end
end

--[[ 
    Función Privada (Cliente Only): Crea el efecto visual
]]
function module._createLocalHighlight(character, length, team, customColor)
    local und = character:GetAttribute("Undetectable") or 0
    if und > 0 then return end

    local high = Instance.new("Highlight")
    
    -- Lógica de colores
    if customColor then
        -- Si pasamos un color manual (ej: Verde para Ability3)
        high.OutlineColor = customColor
        high.FillColor = customColor
    elseif team then
        -- Lógica por defecto de equipos (LMS)
        if team == teams.Survivors then
            high.OutlineColor = Color3.fromRGB(255, 255, 0) -- Amarillo
            high.FillColor = Color3.fromRGB(255, 255, 0)
        elseif team == teams.Killers then
            high.OutlineColor = Color3.fromRGB(255, 0, 0) -- Rojo
            high.FillColor = Color3.fromRGB(255, 0, 0)
        end
    else
        -- Fallback
        high.OutlineColor = Color3.fromRGB(255, 255, 255)
        high.FillColor = Color3.fromRGB(255, 255, 255)
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

-- ... (El resto de funciones como checkLMSConditions y stopAllLMSMusic se quedan igual)

return module