-- TradeBeacons
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

local UpgradeGenerator = include("upgradegenerator")

local TradeBeacons_UtilityMerchant_ship_addItems = UtilityMerchant.shop.addItems
function UtilityMerchant.shop:addItems(...)
    TradeBeacons_UtilityMerchant_ship_addItems(self, ...)

    local numSystems = getInt(1,3)
    local madeSystems = 0
    local generator = UpgradeGenerator()
    local x, y = Sector():getCoordinates()
    local rarities, weights = generator:getSectorRarityDistribution(x, y)

    repeat
        local rarity = getValueFromDistribution(rarities, random())
        local item = UsableInventoryItem("tradebeacon.lua", Rarity(rarity), Seed(appTimeMs()))

        UtilityMerchant.add(item, getInt(1, 15 - rarity))
        madeSystems = madeSystems + 1
    until madeSystems == numSystems
end
