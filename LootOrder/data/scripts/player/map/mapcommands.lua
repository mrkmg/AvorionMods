-- LootOrder - by Kevin Gravier (MrKMG)

include ("ordertypes")

MapCommands.registerModdedMapCommand(OrderType.Loot, {
    tooltip = "Loot",
    icon = "data/textures/icons/loot.png",
    callback = "onLootPressed",
})

function MapCommands.onLootPressed() 
    MapCommands.clearOrdersIfNecessary()
    MapCommands.enqueueOrder("addLootOrder")
end
