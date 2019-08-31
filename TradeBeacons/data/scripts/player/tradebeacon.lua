package.path = package.path .. ";data/scripts/lib/?.lua"

include ("utility")
local TradeBeaconSerializer = include ("tradebeaconserializer")
local Queue = include ("queue")
local CONFIG_maxBeaconStaleTime = 5 * 60 -- 5 minute

--namespace TradeBeacon
TradeBeacon = {}

local knownBeacons = {}

function TradeBeacon.debug(...)
    if Player():getValue("tradebeacons_debug") then
        print (...)
    end
end

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
    if onClient() then return {} end

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
    function TradeBeacon.initialize()
        local player = Player()
        player:registerCallback("onShowGalaxyMap", "onShowGalaxyMap")
        player:registerCallback("onMapRenderAfterLayers", "onMapRenderAfterLayers")
        player:registerCallback("onMapRenderAfterUI", "onMapRenderAfterUI")
    end

    function TradeBeacon.onShowGalaxyMap()
        TradeBeacon.sync()
    end

    function TradeBeacon.onMapRenderAfterUI()
        local map = GalaxyMap()
        local x, y = map:getHoveredCoordinates()
        local tooltip = Tooltip()

        local titleLine = TooltipLine(25, 15)
        titleLine.ctext = "Trade Beacons"%_t
        tooltip:addLine(titleLine)

        local emptyLine = TooltipLine(20, 12)
        tooltip:addLine(emptyLine)

        local isBeacon = false
        for _, beaconData in pairs(knownBeacons) do
            if beaconData.x == x and beaconData.y == y then
                isBeacon = true
                local line = TooltipLine(20, 12)
                line.ltext = "Time Left:"%_t
                local timeReminaingHours = math.floor(beaconData.burnOutTime / 60 / 60)
                if timeReminaingHours > 0 then
                    line.rtext = "${hoursLeft} Hours"%_t%{hoursLeft = timeReminaingHours}
                else
                    local timeRemainingMinutes = math.floor(beaconData.burnOutTime / 60)
                    line.rtext = "${minsLeft} Minutes"%_t%{minsLeft = timeRemainingMinutes}
                end
                tooltip:addLine(line)
            end
        end
        if isBeacon then
            local sx, sy = map:getCoordinatesScreenPosition(ivec2(x, y))
            local renderer = TooltipRenderer(tooltip)
            renderer:draw(vec2(sx - 310, sy + 35))
        end
    end

    function TradeBeacon.onMapRenderAfterLayers()
        local player = Player()
        local craft = player.craft

        if valid(craft) and craft:hasScript("tradingoverview.lua") then
            local beaconScanRange = tonumber(craft:getValue("beaconScanRange"))
            if beaconScanRange ~= nil and beaconScanRange > 0 then
                local renderer = UIRenderer()
                local map = GalaxyMap()
                local centerX, centerY = player:getShipPosition(craft.name)
                local color = ColorInt(0x44FF9999)
                TradeBeacon.renderRange(map, renderer, beaconScanRange, centerX, centerY, color)
                TradeBeacon.renderConnections(map, renderer, beaconScanRange, centerX, centerY, color)
                renderer:display()
            end
        end
    end

    function TradeBeacon.renderConnections(map, renderer, radius, centerX, centerY, color)
        local centerVec = vec2(centerX, centerY)
        local function getScreenPos(x, y)
            local xx, yy = map:getCoordinatesScreenPosition(ivec2(x, y))
            return vec2(xx, yy)
        end
        local screenCenterVec = getScreenPos(centerX, centerY)
        for _, beaconData in pairs(knownBeacons) do
            local dist = distance(centerVec, vec2(beaconData.x, beaconData.y))
            if dist <= radius then
                renderer:renderLine(screenCenterVec, getScreenPos(beaconData.x, beaconData.y), color, 1)
            end
        end
    end

    function TradeBeacon.renderRange(map, renderer, radius, centerX, centerY, color)

        -- Borrowed from GalaxyMapQOL
        local side = map:getCoordinatesScreenPosition(ivec2(0, 0))
        side = map:getCoordinatesScreenPosition(ivec2(1, 0)) - side
        local ex = math.floor(radius)
        local bx, by = 0 - ex, 0
        local sx, sy = map:getCoordinatesScreenPosition(ivec2(bx + centerX, by + centerY))
        local cx1, cy1, cx2, cy2, tcy1, tcy2
        local y, k
        local x1, y1, ak = -ex, 0, 0
        local x2, y2 = -ex, 0
        local py = 0
        for x = -ex, 1 do
            y = math.floor(math.sqrt(radius * radius - x * x))
            k = x ~= 0 and y / x or 0
            if k == ak and x <= 0 then -- set new ending coordinates
                x2, y2 = x, y
            elseif py ~= y or x >= 0 then -- draw line
                if x1 ~= x2 or y1 ~= y2 then
                    cx1 = sx + (x1 - bx) * side
                    cy1 = sy + (by - y1) * side
                    cx2 = sx + (x2 - bx) * side
                    cy2 = sy + (by - y2) * side
                    tcy1 = cy1
                    tcy2 = cy2
                    -- top left
                    renderer:renderLine(vec2(cx1, cy1), vec2(cx2, cy2), color, layer)
                    -- bottom left
                    cy1 = sy + (by + y1) * side
                    cy2 = sy + (by + y2) * side
                    renderer:renderLine(vec2(cx1, cy1), vec2(cx2, cy2), color, layer)
                    -- bottom right
                    cx1 = sx + (-x1 - bx) * side
                    cx2 = sx + (-x2 - bx) * side
                    renderer:renderLine(vec2(cx1, cy1), vec2(cx2, cy2), color, layer)
                    -- top right
                    cy1 = tcy1
                    cy2 = tcy2
                    renderer:renderLine(vec2(cx1, cy1), vec2(cx2, cy2), color, layer)
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

    function TradeBeacon.initialize()
        Player():registerCallback("onRestoredFromDisk", "onRestoredFromDisk")
    end

    function TradeBeacon.onRestoredFromDisk(time)
        TradeBeacon.updateKnownBeacons(time)
    end

    function TradeBeacon.getUpdateInterval()
        return 15
    end

    function TradeBeacon.updateServer(timeStep)
        TradeBeacon.updateKnownBeacons(timeStep)
        TradeBeacon.loadNextSector()
    end

    function TradeBeacon.loadNextSector()
        TradeBeacon.debug("TradeBeacons:", "Sector Loads Pending", toLoadSectors:length())
        while not toLoadSectors:isEmpty() do
            local beaconData = toLoadSectors:next()
            if beaconData ~= nil and not Galaxy():sectorLoaded(beaconData.x, beaconData.y) then
                TradeBeacon.debug("TradeBeacons:", "Loading a sector", beaconData.x, beaconData.y)
                Galaxy():loadSector(beaconData.x, beaconData.y)
                return
            end
        end
    end

    function TradeBeacon.updateKnownBeacons(timeStep)
        for beaconId, beaconData in pairs(knownBeacons) do
            TradeBeacon.updateKnownBeacon(timeStep, beaconId, beaconData)
        end
    end

    function TradeBeacon.updateKnownBeacon(timeStep, beaconId, beaconData)
        beaconData.burnOutTime = beaconData.burnOutTime - timeStep
        beaconData.lastSeen = beaconData.lastSeen + timeStep

        if beaconData.lastSeen > 600 then -- 10 min
            knownBeacons[beaconId] = nil
            return
        end

        if toLoadSectors:contains(beaconData) then
            return
        end

        local isBeaconBurnedOut = beaconData.burnOutTime <= 0
        local isBeaconStale = beaconData.lastSeen > CONFIG_maxBeaconStaleTime


        if (isBeaconBurnedOut or isBeaconStale) and not Galaxy():sectorLoaded(beaconData.x, beaconData.y) then
            TradeBeacon.debug("TradeBeacons:", "Queueing Load of Sector", beaconData.x, beaconData.y)
            toLoadSectors:insert(beaconData)
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

