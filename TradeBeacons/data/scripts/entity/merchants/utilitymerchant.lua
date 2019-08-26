
function UtilityMerchant.shop:addItems()
    local item = UsableInventoryItem("energysuppressor.lua", Rarity(RarityType.Exceptional))
    UtilityMerchant.add(item, getInt(2, 3))

    local item2 = UsableInventoryItem("tradebeacon.lua", Rarity(RarityType.Exceptional))
    UtilityMerchant.add(item2, getInt(3, 10))
end
