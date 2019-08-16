-- LootCommand - by Kevin Gravier (MrKMG)

OrderChain.registerModdedOrderChain("LootOrder", {
    isFinishedFunction = "lootOrderFinished",
    canEnchainAfter = true,
    onActivateFunction = "startLooting",
    displayName = "Loot"%_T,
    icon = "data/textures/icons/loot.png",
    pixelIcon = "data/textures/icons/pixel/loot.png",
});

function OrderChain.addLootOrder(persistent)
    if onClient() then
        invokeServerFunction("addLootOrder", persistent)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end

    local order = {action = "LootOrder", persistent = persistent}

    if OrderChain.canEnchain(order) then
        OrderChain.enchain(order)
    end
end
callable(OrderChain, "addLootOrder")

function OrderChain.startLooting()
    Entity():invokeFunction("data/scripts/entity/craftorders.lua", "loot")
end
callable(OrderChain, "startLooting")

function OrderChain.lootOrderFinished(order)
    local persistent = order.persistent
    local entity = Entity()
    if not entity:hasScript("data/scripts/entity/ai/loot.lua") then
        return true
    end

    if persistent then return false end

    local ret, result = entity:invokeFunction("data/scripts/entity/ai/loot.lua", "canContinueLooting")
    if ret == 0 and result == true then return false end

    entity:removeScript("data/scripts/entity/ai/loot.lua")
    return true
end
callable(OrderChain, "lootOrderFinished")

