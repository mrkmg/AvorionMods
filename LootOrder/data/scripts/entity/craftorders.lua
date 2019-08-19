-- LootOrder - by Kevin Gravier (MrKMG)

CraftOrders.registerModdedCraftOrder(OrderType.Loot, {
    title = "Loot",
    callback = "onUserLootOrder"
})

function CraftOrders.onUserLootOrder()
    if onClient() then
        invokeServerFunction("onUserLootOrder")
        ScriptUI():stopInteraction()
        return
    end

    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "clearAllOrders")
    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "addLootOrder", true)
end
callable(CraftOrders, "onUserLootOrder")


function CraftOrders.loot()
    print ("CraftOrders.loot")
    if onClient() then
        invokeServerFunction("loot")
        ScriptUI():stopInteraction()
        return
    end

    if checkCaptain() then
        CraftOrders.removeSpecialOrders()
        Entity():addScriptOnce("ai/loot.lua")
        return true
    end
end
callable(CraftOrders, "loot")
