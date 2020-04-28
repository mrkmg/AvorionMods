-- LootOrder
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

include ("ordertypes")

MapCommands.registerModdedMapCommand(OrderType.Loot, {
    tooltip = "Loot",
    icon = "data/textures/icons/cash.png",
    callback = "onLootPressed",
})

function MapCommands.onLootPressed()
    MapCommands.clearOrdersIfNecessary()
    MapCommands.enqueueOrder("addLootOrder")
    if not MapCommands.isEnqueueing() then MapCommands.runOrders() end
end
