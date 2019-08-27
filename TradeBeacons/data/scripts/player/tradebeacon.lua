package.path = package.path .. ";data/scripts/lib/?.lua"

include ("utility")
local TradeBeaconSerializer = include ("tradebeaconserializer")

--namespace TradeBeacon
TradeBeacon = {}

local knownBeacons = {}

function TradeBeacon.registerTradeBeacon(x, y, beaconId, sectorDataString)
    if onServer() then
        local sectorData = TradeBeaconSerializer.deserializeSectorData(sectorDataString)
        knownBeacons[beaconId] = {x = x, y = y, sectorData = sectorData}
    end
end

function TradeBeacon.deregisterTradeBeacon(beaconId)
    if onServer() then
        knownBeacons[beaconId] = nil
    end
end

function TradeBeacon.requestSectorsData(x, y, maxDistance, shipId, caller)
    if onServer() then
        knownTradingShips[shipId] = {x = x, y = y, maxDistance = maxDistance }
        TradeBeacon.sync()

        local sectorsData = {}
        for _, beaconData in pairs(knownBeacons) do
            if beaconData ~= nil then
                if distance(vec2(beaconData.x, beaconData.y), vec2(x, y)) <= maxDistance then
                    table.insert(sectorsData, beaconData.tradeData)
                end
            end
        end

        if #sectorsData > 0 then
            TradeBeacon.sendInfoToShip(x, y, shipId, caller, sectorsData)
        end
    end
end

function TradeBeacon.sendInfoToShip(x, y, shipId, caller, sectorsData)
    shipId = Uuid(shipId)
    local sectorsDataString = TradeBeaconSerializer.serializeSectorsData(sectorsData)
    invokeRemoteEntityFunction(
            x, y, nil, shipId,
            "tradingoverview.lua", "receiveTradingInfoFromPlayer",
            caller, sectorsDataString
    )
end

