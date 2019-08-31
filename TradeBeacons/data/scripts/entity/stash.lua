-- TradeBeacons
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

local UtilityGenerator = include ("utilitygenerator")

function receiveUtility(faction)

    local rarity = Rarity(RarityType.Uncommon)

    if random():getFloat() < 0.3 then
        rarity = Rarity(RarityType.Exceptional)
    elseif random():getFloat() < 0.7 then
        rarity = Rarity(RarityType.Rare)
    end

    local x, y = Sector():getCoordinates()

    UtilityGenerator.initialize(random():createSeed())
    local utility = UpgradeGenerator.generateUtility(rarity)
    faction:getInventory():add(utility)
end

local TradeBeacon_claim = claim
function claim()
    TradeBeacon_claim()

    if random():getFloat() < 0.5 then
        receiveUtility(receiver)
    end
end
callable(nil, "claim")
