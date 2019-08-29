local UpgradeGenerator = include("upgradegenerator")

local TradeBeacons_UtilityMerchant_ship_addItems = UtilityMerchant.shop.addItems
function UtilityMerchant.shop:addItems(...)
    TradeBeacons_UtilityMerchant_ship_addItems(self, ...)

    local numSystems = getInt(1,3)
    local madeSystems = 0
    local x, y = Sector():getCoordinates()
    local rarities, weights = UpgradeGenerator.getSectorProbabilities(x, y)

    repeat
        local rarity = rarities[selectByWeight(random(), weights)]
        local item = UsableInventoryItem("tradebeacon.lua", rarity, Seed(appTimeMs()))

        UtilityMerchant.add(item, getInt(1, 15 - rarity.value))
        madeSystems = madeSystems + 1
    until madeSystems == numSystems

end
