package.path = package.path .. ";data/scripts/lib/?.lua"

include ("utility")
local TradeBeaconSerializer = include ("tradebeaconserializer")

--namespace TradeBeacon
TradeBeacon = {}
local knownBeacons = {}

if onServer() then
    function TradeBeacon.secure()
        return {
            knownBeacons = knownBeacons
        }
    end

    function TradeBeacon.restore(data)
        if data ~= nil and data.knownBeacons ~= nil then
            knownBeacons = data.knownBeacons
        end
    end

    function getUpdateInterval()
        return 30
    end

    function updateServer(timeStep)
        for beaconId, beaconData in pairs(knownBeacons) do
            beaconData.burnOutTime = beaconData - timeStep

            if beaconData.burnOutTime < 0 then
                TradeBeacon.deregisterTradeBeacon(beaconId)
            end
        end
    end

    function TradeBeacon.registerTradeBeacon(x, y, beaconId, sectorDataString, burnOutTime)
        local sectorData = TradeBeaconSerializer.deserializeSectorData(sectorDataString)
        knownBeacons[beaconId] = {x = x, y = y, sectorData = sectorData, burnOutTime = burnOutTime}
    end

    function TradeBeacon.deregisterTradeBeacon(beaconId)
        knownBeacons[beaconId] = nil
    end

    function TradeBeacon.requestSectorsData(x, y, maxDistance, shipId, caller)
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

