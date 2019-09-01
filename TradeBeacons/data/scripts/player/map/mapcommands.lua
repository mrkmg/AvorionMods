-- TradeBeacons
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

include ("ordertypes")

MapCommands.registerModdedMapCommand(OrderType.DropTradeBeacon, {
    tooltip = "Drop Trade Beacon",
    icon = "data/textures/icons/satellite.png",
    callback = "onTradeTradeBeaconPressed",
})

function MapCommands.onTradeTradeBeaconPressed()
    MapCommands.clearOrdersIfNecessary()
    MapCommands.enqueueOrder("addDropTradeBeaconOrder")
end
