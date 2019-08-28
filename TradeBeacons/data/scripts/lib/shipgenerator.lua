local UtilityGenerator = include ("utilitygenerator")

local TradeBeacons_ShipGenerator_createFreighterShip = ShipGenerator.createFreighterShip
function ShipGenerator.createFreighterShip(faction, position, volume)
    local ship = TradeBeacons_ShipGenerator_createFreighterShip(faction, position, volume)

    if random():getFloat() < 0.3 then
        local object = UtilityGenerator.generateSectorUtility(position.x, position.y)
        Loot(ship.index):insert(object)
    end

    return ship
end

local TradeBeacons_ShipGenerator_createTradingShip = ShipGenerator.createTradingShip
function ShipGenerator.createTradingShip(faction, position, volume)
    local ship = TradeBeacons_ShipGenerator_createTradingShip(faction, position, volume)

    if random():getFloat() < 0.8 then
        local object = UtilityGenerator.generateSectorUtility(position.x, position.y)
        Loot(ship.index):insert(object)
    end

    return ship
end
