-- TradeBeacons
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

MapRoutes.registerModdedMapRoute(OrderType.DropTradeBeacon, {
    orderDescriptionFunction = "dropTradeBeacon",
    pixelIcon = "data/textures/icons/pixel/satellite.png",
});

function MapRoutes.dropTradeBeacon(order, i, line)
    line.ltext = "[${i}] Drop Trade Beacon"%_t % {i = i}
end
callable(MapRoutes, "dropTradeBeacon")
