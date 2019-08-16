
MapCommands.registerModdedMapCommand(OrderTypes.Loot, {
	tooltip = "Loot",
	icon = "data/textures/icons/loot.png",
	callback = "onLootPressed",
})

function MapCommands.onLootPressed() {
    MapCommands.clearOrdersIfNecessary()
    MapCommands.enqueueOrder("addLootOrder")
}