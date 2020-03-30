-- TransferCargoOrder
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

OrderChain.registerModdedOrderChain(OrderType.TransferCargo, {
    isFinishedFunction = "transferCargoFinished",
    canEnchainAfter = true,
    onActivateFunction = "startTransferCargo",
    canEnchainAfterCheck = "canEnchainAfterTransferCargo",
});


function OrderChain.addTransferCargoOrder(factionIndex, craftName)
    if onClient() then
        invokeServerFunction("addTransferCargoOrder", factionIndex, craftName)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end

    local targetCraft = Sector():getEntityByFactionAndName(factionIndex, craftName)
    local order = {action = OrderType.TransferCargo, targetIndex = targetCraft.index.string}

    if OrderChain.canEnchain(order) then
        OrderChain.enchain(order)
    end
end
callable(OrderChain, "addTransferCargoOrder")

function OrderChain.startTransferCargo(order)
    Entity():invokeFunction("data/scripts/entity/craftorders.lua", "transferCargo", order.targetIndex)
    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "runOrders")
end

function OrderChain.transferCargoFinished(order)
    local entity = Entity()
    
    if not entity:hasScript("data/scripts/entity/ai/transferCargo.lua") then
        return true
    end

    return false
end

function OrderChain.canEnchainAfterTransferCargo(order)
    return true
end