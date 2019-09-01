-- TradeBeacons
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

include ("../items/tradebeacon")

OrderChain.registerModdedOrderChain(OrderType.DropTradeBeacon, {
    isFinishedFunction = "tradeBeaconDropBeaconFinished",
    canEnchainAfter = true,
    onActivateFunction = "tradeBeaconOnActivateFunction",
    canEnchainAfterCheck = "tradeBeaconCanEnchainAfterCheck",
})

local function getFactionTradeBeaconIndex(faction)
    local factionInventory = {faction:getInventory():getItemsByType(InventoryItemType.UsableItem)}
    for _, items in pairs(factionInventory) do
        for itemIndex, itemDetail in pairs(items) do
            if itemDetail.item.script == "tradebeacon.lua" then
                return itemIndex
            end
        end
    end
    return nil
end

function OrderChain.addDropTradeBeaconOrder()
    if onClient() then
        invokeServerFunction("tradeBeaconDropBeacon")
        return
    end

    local entity = Entity()

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(entity, AlliancePrivilege.ManageShips)
        if not owner then return end
    end

    local faction = getParentFaction()
    local beaconIndex = getFactionTradeBeaconIndex(faction)

    if beaconIndex then
        local order = {action = OrderType.DropTradeBeacon}

        if OrderChain.canEnchain(order) then
            OrderChain.enchain(order)
        end
    else
        Player():sendChatMessage("Order"%_T, ChatMessageType.Warning, [[No access to any Trade Beacons]]%_T)
    end
end
callable(OrderChain, "addDropTradeBeaconOrder")

function OrderChain.tradeBeaconOnActivateFunction()
    local faction = getParentFaction()

    local factionInventory = faction:getInventory()
    local beaconIndex = getFactionTradeBeaconIndex(faction)

    if beaconIndex ~= nil then
        local beacon = factionInventory:take(beaconIndex)
        TradeBeacon.remoteActivate(beacon)
    else
        faction:sendChatMessage("Order"%_T, ChatMessageType.Warning, [[No access to any Trade Beacons]]%_T)
    end
end
callable(OrderChain, "tradeBeaconOnActivateFunction")

function OrderChain.tradeBeaconDropBeaconFinished(order)
    return true
end
callable(OrderChain, "tradeBeaconDropBeaconFinished")

function OrderChain.tradeBeaconCanEnchainAfterCheck()
    return true
end
