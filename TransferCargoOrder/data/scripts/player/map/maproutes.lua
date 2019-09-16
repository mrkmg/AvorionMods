-- TransferCargoOrder
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

MapRoutes.registerModdedMapRoute(OrderType.TransferCargo, {
    orderDescriptionFunction = "transferOrderDiscription",
    pixelIcon = "data/textures/icons/pixel/crate.png",
});

function MapRoutes.transferOrderDiscription(order, i, line)
    line.ltext = "[${i}] Transfer cargo"%_t % {i = i}
end
callable(MapRoutes, "transferOrderDiscription")
