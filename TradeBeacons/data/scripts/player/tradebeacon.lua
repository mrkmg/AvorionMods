package.path = package.path .. ";data/scripts/lib/?.lua"

include ("utility")
local TradeBeaconSerializer = include ("tradebeaconserializer")

--namespace TradeBeacon
TradeBeacon = {}
local knownBeacons = {}

if onServer() then
    function TradeBeacon.secure()
        local knownBeaconsCopy = {}
        for beaconId,beaconData in pairs(knownBeacons) do
            if beaconData ~= nil then
                knownBeaconsCopy[beaconId] = {
                    x = beaconData.x,
                    y = beaconData.y,
                    burnOutTime = beaconData.burnOutTime,
                    sectorData = TradeBeaconSerializer.serializeSectorData(beaconData.sectorData),
                    timeSinceCheckin = beaconData.timeSinceCheckin
                }
            end
        end
        return {
            knownBeacons = knownBeaconsCopy
        }
    end

    function TradeBeacon.restore(data)
        if data ~= nil and data.knownBeacons ~= nil then
            knownBeacons = {}
            for beaconId, beaconData in pairs(data.knownBeacons) do
                knownBeacons[beaconId] = {
                    x = beaconData.x,
                    y = beaconData.y,
                    burnOutTime = beaconData.burnOutTime,
                    sectorData = TradeBeaconSerializer.deserializeSectorData(beaconData.sectorData),
                    timeSinceCheckin = beaconData.timeSinceCheckin
                }
            end
        end
    end

    function TradeBeacon.getUpdateInterval()
        return 60
    end

    function TradeBeacon.updateServer(timeStep)
        for beaconId, beaconData in pairs(knownBeacons) do
            beaconData.burnOutTime = beaconData.burnOutTime - timeStep
            beaconData.timeSinceCheckin = beaconData.timeSinceCheckin + timeStep

            local isBeaconBurnedOut = beaconData.burnOutTime <= 0
            local isBeaconStale = beaconData.timeSinceCheckin > 5 * 60
            local isBeaconInWarningPeriod = beaconData.burnOutTime <= 10 * 60 and beaconData.burnOutTime >= 9 * 60

            if (isBeaconBurnedOut or isBeaconStale or isBeaconInWarningPeriod) and not Galaxy():sectorLoaded(beaconData.x, beaconData.y) then
                Galaxy():loadSector(beaconData.x, beaconData.y)
            end

            -- if beacon is over a minute old, and has not deregistered itself, force it out of the cache
            if beaconData.burnOutTime < -60 then
                knownBeacons[beaconId] = nil
            end
        end
    end

    function TradeBeacon.registerTradeBeacon(x, y, beaconId, sectorDataString, burnOutTime)
        local sectorData = TradeBeaconSerializer.deserializeSectorData(sectorDataString)
        knownBeacons[beaconId] = {
            x = x,
            y = y,
            sectorData = sectorData,
            burnOutTime = burnOutTime,
            timeSinceCheckin = 0
        }
    end

    function TradeBeacon.deregisterTradeBeacon(beaconId)
        knownBeacons[beaconId] = nil
    end

    function TradeBeacon.requestSectorsData(x, y, maxDistance, shipId, caller)
        local sectorsData = {}
        local xyVec = vec2(x, y)

        for _, beaconData in pairs(knownBeacons) do
            if beaconData ~= nil then
                local dist = distance(vec2(beaconData.x, beaconData.y), xyVec)
                -- check dist > 0 to not send sector data for the sector the ship is currently in
                -- due to the local systems already collecting that data
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

