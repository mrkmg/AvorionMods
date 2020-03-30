-- LootOrder
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

include ("ordertypes")

MapCommands.registerModdedMapCommand(OrderType.Loot, {
    tooltip = "Loot",
    icon = "data/textures/icons/loot.png",
    callback = "onLootPressed",
})

function MapCommands.onLootPressed() 
    MapCommands.clearOrdersIfNecessary()
    MapCommands.enqueueOrder("addLootOrder")
    if not enqueueNextOrder then MapCommands.runOrders() end
end
