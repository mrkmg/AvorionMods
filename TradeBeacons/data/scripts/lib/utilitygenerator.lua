
package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("galaxy")
include ("randomext")
include ("utility")

local rand = nil

local scripts = {}
local weights = {}

local UtilityGenerator = {}

UtilityGenerator.scripts = scripts
UtilityGenerator.weights = weights

function UtilityGenerator.add(script, weight)
    table.insert(scripts, script)
    table.insert(weights, weight)
end

UtilityGenerator.add("data/scripts/items/tradebeacon.lua", 1)

function UtilityGenerator.initialize(seed)
    if seed then
        rand = Random(seed)
    else
        rand = random()
    end

    for i = 1, 624 do
        rand:getInt()
    end

end

function UtilityGenerator.getProbabilities()
    local rarities = {}

    table.insert(rarities, Rarity(-1))
    table.insert(rarities, Rarity(0))
    table.insert(rarities, Rarity(1))
    table.insert(rarities, Rarity(2))
    table.insert(rarities, Rarity(3))
    table.insert(rarities, Rarity(4))
    table.insert(rarities, Rarity(5))

    local weights = {}

    table.insert(weights, 16)
    table.insert(weights, 48)
    table.insert(weights, 16)
    table.insert(weights, 8)
    table.insert(weights, 4)
    table.insert(weights, 1)
    table.insert(weights, 0.2)

    return rarities, weights
end

function UtilityGenerator.getSectorProbabilities(x, y)
    local rarities = {}

    table.insert(rarities, Rarity(-1))
    table.insert(rarities, Rarity(0))
    table.insert(rarities, Rarity(1))
    table.insert(rarities, Rarity(2))
    table.insert(rarities, Rarity(3))
    table.insert(rarities, Rarity(4))
    table.insert(rarities, Rarity(5))

    local weights = {}
    local pos = length(vec2(x, y)) / (Balancing_GetDimensions() / 2) -- 0 (center) to 1 (edge) to ~1.5 (corner)

    table.insert(weights, 2 + pos * 14) -- 16 at edge, 2 in center
    table.insert(weights, 8 + pos * 40) -- 48 at edge, 8 in center
    table.insert(weights, 8 + pos * 8) -- 16 at edge, 8 in center
    table.insert(weights, 8)
    table.insert(weights, 4)
    table.insert(weights, 1)
    table.insert(weights, 0.2)

    return rarities, weights
end

function UtilityGenerator.generateSectorUtility(x, y)
    local rarities, rweights = UtilityGenerator.getSectorProbabilities(x, y)

    local rarity = rarities[selectByWeight(rand, rweights)]
    local script = scripts[selectByWeight(rand, weights)]

    return UsableInventoryItem(script, rarity, rand:createSeed())
end

function UtilityGenerator.generateUtility(rarity, weights_in)

    if rarity == nil then
        local rarities, rweights = UtilityGenerator.getProbabilities()
        rweights = weights_in or rweights

        rarity = rarities[selectByWeight(rand, rweights)]
    end

    local script = scripts[selectByWeight(rand, weights)]

    return UsableInventoryItem(script, rarity, rand:createSeed())
end

return UtilityGenerator
