package.path = package.path .. ";data/scripts/lib/?.lua"

include ("utility")
local TradeBeaconSerializer = include ("tradebeaconserializer")
local Queue = include ("queue")
local CONFIG_maxBeaconStaleTime = 5 * 60 -- 5 minute
local CONFIG_sectorLoadDelay = 30 -- 30 seconds
local CONFIG_maxBurnOutUntilRemove = -60 -- one minute past burned out

--namespace TradeBeacon
TradeBeacon = {}

local knownBeacons = {}

function TradeBeacon.sync(data)
    if onServer() then
        if callingPlayer then
            invokeClientFunction(Player(callingPlayer), "sync", TradeBeacon.secure())
        end
    else
        if data then
            TradeBeacon.restore(data)
        else
            invokeServerFunction("sync")
        end
    end
end
callable(TradeBeacon, "sync")

function TradeBeacon.secure()
    local knownBeaconsCopy = {}
    for beaconId,beaconData in pairs(knownBeacons) do
        if beaconData ~= nil then
            knownBeaconsCopy[beaconId] = {
                x = beaconData.x,
                y = beaconData.y,
                burnOutTime = beaconData.burnOutTime,
                sectorData = TradeBeaconSerializer.serializeSectorData(beaconData.sectorData),
                lastSeen = beaconData.lastSeen,
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
                burnOutTime = beaconData.burnOutTime or 0,
                sectorData = TradeBeaconSerializer.deserializeSectorData(beaconData.sectorData),
                lastSeen = beaconData.lastSeen or 0,
            }
        end
    end
end

if onClient() then
    local beaconTooltipContainer

    function TradeBeacon.initialize()
        local player = Player()
        player:registerCallback("onShowGalaxyMap", "onShowGalaxyMap")
        player:registerCallback("onSelectMapCoordinates", "onSelectMapCoordinates")
        player:registerCallback("onMapRenderAfterUI", "onMapRenderAfterUI")

        beaconTooltipContainer = GalaxyMap():createContainer()
    end

    function TradeBeacon.onShowGalaxyMap()
        TradeBeacon.sync()
    end

    function TradeBeacon.onSelectMapCoordinates(x, y)
        beaconTooltipContainer:hide()
        local tooltip = Tooltip()

        local titleLine = TooltipLine()
        titleLine.fontSize = 14
        titleLine.ctext = "Trade Beacons"
        tooltip:addLine(titleLine)

        local emptyLine = TooltipLine()
        tooltip:addLine(emptyLine)

        local isBeacon = false
        for _, beaconData in pairs(knownBeacons) do
            if beaconData.x == x and beaconData.y == y then
                isBeacon = true
                local line = TooltipLine()
                line.ltext = beaconData.burnOutTime
                line.rtext = beaconData.lastSeen
                tooltip:addLine(line)
            end
        end
        if isBeacon then
            beaconTooltipContainer.tooltip = tooltip
            beaconTooltipContainer:show()
        end
    end

    function TradeBeacon.onMapRenderAfterUI()
        local craft = Player().craft

        if valid(craft) and craft:hasScript("tradingoverview.lua") then
            local beaconScanRange = craft:getValue("beaconScanRange")
            if beaconScanRange ~= nil and beaconScanRange > 0 then
                TradeBeacon.renderRange(beaconScanRange)
            end
        end
    end

    function TradeBeacon.renderRange(radius)
        local player = Player()
        local centerX, centerY = player:getShipPosition(name)
        local renderer = UIRenderer()
        local map = GalaxyMap()
        local color = ColorInt(0xffff0000)

        -- Borrowed from GalaxyMapQOL
        local side = map:getCoordinatesScreenPosition(ivec2(0, 0))
        side = map:getCoordinatesScreenPosition(ivec2(1, 0)) - side
        local ex = math.floor(radius)
        local bx, by = centerX - ex, centerY
        local sx, sy = map:getCoordinatesScreenPosition(ivec2(bx, by))
        local cx1, cy1, cx2, cy2, tcy1, tcy2
        local y, k
        local x1, y1, ak = centerX - ex, centerY, centerX
        local x2, y2 = centerX - ex, centerY
        local py = 0
        for x = centerX - ex, centerX + 1 do
            y = math.floor(math.sqrt(radius * radius - x * x))
            k = x ~= centerX and y / x or centerX
            if k == ak and x <= centerX then -- set new ending coordinates
                x2, y2 = x, y
            elseif py ~= y or x >= centerX then -- draw line
                if x1 ~= x2 or y1 ~= y2 then
                    cx1 = sx + (x1 - bx) * side
                    cy1 = sy + (by - y1) * side
                    cx2 = sx + (x2 - bx) * side
                    cy2 = sy + (by - y2) * side
                    tcy1 = cy1
                    tcy2 = cy2
                    -- top left
                    renderer:renderLine(vec2(cx1, cy1), vec2(cx2, cy2), color, 1)
                    -- bottom left
                    cy1 = sy + (by + y1) * side
                    cy2 = sy + (by + y2) * side
                    renderer:renderLine(vec2(cx1, cy1), vec2(cx2, cy2), color, 1)
                    -- bottom right
                    cx1 = sx + (-x1 - bx) * side
                    cx2 = sx + (-x2 - bx) * side
                    renderer:renderLine(vec2(cx1, cy1), vec2(cx2, cy2), color, 1)
                    -- top right
                    cy1 = tcy1
                    cy2 = tcy2
                    renderer:renderLine(vec2(cx1, cy1), vec2(cx2, cy2), color, 1)
                end
                x1, y1 = x2, y2
                x2, y2 = x, y
                ak = k
            end
            py = y
        end
        -- end borrowing

    end
end

if onServer() then
    local function sectorComparer(a, b)
        return a.x == b.x and a.y == b.y
    end

    local toLoadSectors = Queue(sectorComparer)
    local sectorLoadDelay = CONFIG_sectorLoadDelay

    function TradeBeacon.initialize()
        Player():registerCallback("onRestoredFromDisk", "onRestoredFromDisk")
    end

    function TradeBeacon.onRestoredFromDisk(time)
        TradeBeacon.updateKnownBeacons(time)
    end

    function TradeBeacon.getUpdateInterval()
        return 10
    end

    function TradeBeacon.updateServer(timeStep)
        sectorLoadDelay = sectorLoadDelay - timeStep
        TradeBeacon.updateKnownBeacons(timeStep)
        if sectorLoadDelay <= 0 and not toLoadSectors:isEmpty() then
            TradeBeacon.loadNextSector()
        end
    end

    function TradeBeacon.loadNextSector()
        while true do
            local beaconData = toLoadSectors:next()
            if beaconData ~= nil and not Galaxy():sectorLoaded(beaconData.x, beaconData.y) then
                print ("Loading Sector:     ", beaconData.x, beaconData.y)
                Galaxy():loadSector(beaconData.x, beaconData.y)
                sectorLoadDelay = CONFIG_sectorLoadDelay
                break
            end
        end
    end

    function TradeBeacon.updateKnownBeacons(timeStep)
        for beaconId, beaconData in pairs(knownBeacons) do
            beaconData.burnOutTime = beaconData.burnOutTime - timeStep
            beaconData.lastSeen = beaconData.lastSeen + timeStep

            if beaconData.burnOutTime < CONFIG_maxBurnOutUntilRemove then
                knownBeacons[beaconId] = nil
                goto CONTINUE_TradeBeacon_updateKnownBeacons
            end

            if toLoadSectors:contains(beaconData) then
                goto CONTINUE_TradeBeacon_updateKnownBeacons
            end

            local isBeaconBurnedOut = beaconData.burnOutTime <= 0
            local isBeaconStale = beaconData.lastSeen > CONFIG_maxBeaconStaleTime


            if (isBeaconBurnedOut or isBeaconStale) and not Galaxy():sectorLoaded(beaconData.x, beaconData.y) then
                print ("Queuing Sector:     ", beaconData.x, beaconData.y)
                toLoadSectors:insert(beaconData)
            end

            -- if beacon is over a minute old, and has not deregistered itself, force it out of the cache
            ::CONTINUE_TradeBeacon_updateKnownBeacons::
        end
    end

    function TradeBeacon.registerTradeBeacon(x, y, beaconId, sectorDataString, burnOutTime)
        local sectorData = TradeBeaconSerializer.deserializeSectorData(sectorDataString)
        knownBeacons[beaconId] = {
            x = x,
            y = y,
            sectorData = sectorData,
            burnOutTime = burnOutTime,
            lastSeen = 0
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

