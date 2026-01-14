-- BehaviorRegistry (ServerScriptService)
local BehaviorRegistry = {}
local registry = {} -- registry[player] = behaviorInstance

function BehaviorRegistry.register(player, behavior)
	if not player then return end
	registry[player] = behavior
end

function BehaviorRegistry.unregister(player)
	if not player then return end
	registry[player] = nil
end

function BehaviorRegistry.get(player)
	return registry[player]
end

function BehaviorRegistry.getByCharacter(character)
	for p,b in pairs(registry) do
		if p.Character == character then
			return b
		end
	end
	return nil
end

return BehaviorRegistry