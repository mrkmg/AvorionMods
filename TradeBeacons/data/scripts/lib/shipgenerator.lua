local UtilityGenerator = include ("utilitygenerator")

local TradeBeacons_ShipGenerator_createFreighterShip = ShipGenerator.createFreighterShip
function ShipGenerator.createFreighterShip(faction, position, volume)
    local ship = TradeBeacons_ShipGenerator_createFreighterShip(faction, position, volume)

    local object = UtilityGenerator.generateSectorUtility(position.x, position.y)
    Loot(ship.index):insert(object)
end
