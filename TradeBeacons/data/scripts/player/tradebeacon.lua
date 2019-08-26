package.path = package.path .. ";data/scripts/lib/?.lua"
include ("sync")

--namespace TradeBeacon
TradeBeacon = {}
defineSyncFunction("data", TradeBeacon)

--[[
Trading Data

Root
{
    sectorIndex = TradingData
}

TradingData
{
    sellable = {}
    buyable = {}
}

]]--
local knownBeacons = {}

function printSource()
    if onClient() then print ("On Client") end
    if onServer() then print ("On Server") end
end


function TradeBeacon.secure()
    return knownBeacons
end

function TradeBeacon.restore(data)
    knownBeacons = data or {}
end

function TradeBeacon.onSync()

end

function TradeBeacon.removeTradingData(entityId)
    printSource()
    knownBeacons[entityId] = nil
    TradeBeacon.sync()
end

function TradeBeacon.storeTradingData(x, y, entityId)
    knownBeacons[entityId] = {x = x, y = y}
    TradeBeacon.sync()
end

function TradeBeacon.getTradingData(x, y, targetEntityId)

    for beaconId, coords in pairs(knownBeacons) do
        if coords ~= nil then
            invokeRemoteEntityFunction(coords.x, coords.y, nil, beaconId, "data/scripts/entity/tradebeacon.lua", "sendRouteInfoTo", x, y, targetEntityId)
        end
    end
end
callable(nil, "getTradingData")

