-- LootCommand - by Kevin Gravier (MrKMG)

CraftOrders.registerModdedCraftOrder("LootOrder", {
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

if onServer() then

function CraftOrders.loot()
    if checkCaptain() then
        CraftOrders.removeSpecialOrders()
        Entity():addScriptOnce("ai/loot.lua")
        return true
    end
end
callable(CraftOrders, "loot")

end