package.path = package.path .. ";data/scripts/lib/?.lua"
include ("sync")
include ("utility")

--namespace TradeBeacon
TradeBeacon = {}
defineSyncFunction("data", TradeBeacon)

local knownBeacons = {}
local knownTradingShips = {}

function TradeBeacon.secure()
    return {knownBeacons = knownBeacons, knownTradingShips = knownTradingShips}
end

function TradeBeacon.restore(data)
    data = data or {}
    if data.knownBeacons ~= nil then
        knownBeacons = data.knownBeacons
    end

    if data.knownTradingShips ~= nil then
        knownTradingShips = data.knownTradingShips
    end
end

function TradeBeacon.onSync()

end

function TradeBeacon.sendInfoToShip(x, y, shipId, caller, tradeData)
    shipId = Uuid(shipId)
    invokeRemoteEntityFunction(
        x, y, nil, shipId,
        "tradingoverview.lua", "receiveTradingInfoFromBeacon",
        caller, tradeData
    )
end

function TradeBeacon.registerTradeBeacon(x, y, beaconId, tradeData)
    if onClient() then
        return
    end
    knownBeacons[beaconId] = {x = x, y = y, tradeData = tradeData}
end
callable(nil, "registerTradebeacon")

function TradeBeacon.deregisterTradeBeacon(beaconId)
    knownBeacons[beaconId] = nil
    TradeBeacon.sync()
end
callable(nil, "deregisterTradeBeacon")

function TradeBeacon.registerTradingShip(x, y, maxDistance, shipId, caller)
    if onClient() then
        return
    end

    knownTradingShips[shipId] = {x = x, y = y, maxDistance = maxDistance }
    TradeBeacon.sync()

    for _, beaconData in pairs(knownBeacons) do
        if beaconData ~= nil then
            if distance(vec2(beaconData.x, beaconData.y), vec2(x, y)) <= maxDistance then
                TradeBeacon.sendInfoToShip(x, y, shipId, caller, beaconData.tradeData)
            end
        end
    end
end
callable(nil, "registerTradingShip")

function TradeBeacon.deregisterTradingShip(shipId)
    knownTradingShips[shipId] = nil
    TradeBeacon.sync()
end
callable(nil, "deregisterTradingShip")
