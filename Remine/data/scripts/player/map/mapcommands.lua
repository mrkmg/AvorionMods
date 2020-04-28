MapCommands.registerModdedMapCommand('remine', {
    tooltip = "Remine",
    icon = "data/textures/icons/remine.png",
    callback = "enqueueRemine"
})

function MapCommands.enqueueRemine()
    MapCommands.clearOrdersIfNecessary()
    MapCommands.enqueueOrder("addRemine", MapCommands.markedX, MapCommands.markedY)
    if not MapCommands.isEnqueueing() then MapCommands.runOrders() end
end