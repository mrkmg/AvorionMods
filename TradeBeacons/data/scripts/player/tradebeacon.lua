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
        local sectorsData = {}

        for _, beaconData in pairs(knownBeacons) do
            if beaconData ~= nil then
                local dist = distance(vec2(beaconData.x, beaconData.y), vec2(x, y))
                if dist <= maxDistance and dist > 0 then
                    table.insert(sectorsData, beaconData.sectorData)
                end
            end
        end

        if #sectorsData > 0 then
            local sectorsDataString = TradeBeaconSerializer.serializeSectorsData(sectorsData)
            invokeRemoteEntityFunction(
                x, y, nil, Uuid(shipId),
                "tradingoverview.lua", "receiveTradingInfoFromPlayer",
                caller, sectorsDataString
            )
        end
    end
end

