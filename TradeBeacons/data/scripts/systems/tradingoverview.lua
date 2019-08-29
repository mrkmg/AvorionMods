local SimpleBuffer = include ("simplebuffer")
local TradeBeaconSerializer = include ("tradebeaconserializer")

local lastSellable = {}
local lastBuyable = {}

-- overrides

-- not needed anymore, as we no longer collect the sector data from jumps
function collectSectorData() end
function onSectorChanged() end

function onInstalled(seed, rarity, permanent)
    historySize = getTradeBeaconScanRange(seed, rarity)

    if onServer() then
        tradingData = SimpleBuffer()
    end
end

function getData()
    local sellable, buyable = gatherData()

    if onServer() then
        tradingData = SimpleBuffer()
    end

    if callingPlayer and historySize > 1 then
        lastSellable = sellable
        lastBuyable = buyable
        requestSectorsData(callingPlayer)
    end

    if tradingData then
        tradingData:insert({sellable = sellable, buyable = buyable})
        updateTradingRoutes()
    end

    if callingPlayer then
        invokeClientFunction(Player(callingPlayer), "setData", sellable, buyable, routes)
    end

    return sellable, buyable, routes or {}
end
callable(nil, "getData")

function getTooltipLines(seed, rarity, permanent)
    local lines = {}

    if seePrices(seed, rarity) then
        table.insert(lines, {ltext = "Display prices of goods"%_t, icon = "data/textures/icons/sell.png"})
    end
    if seePriceFactors(seed, rarity) then
        table.insert(lines, {ltext = "Display price ratios of goods"%_t, icon = "data/textures/icons/sell.png"})
    end

    local tradeBeaconRange = getTradeBeaconScanRange(seed, rarity)
    if tradeBeaconRange > 0 then
        table.insert(lines, {ltext = "Trade Beacon Range"%_t, rtext = tostring(tradeBeaconRange), icon = "data/textures/icons/sell.png"})
    end

    return lines
end

function getDescriptionLines(seed, rarity, permanent)
    local lines =
    {
        {ltext = "View trading offers of stations in sector"%_t}
    }

    local tradeBeaconRange = getTradeBeaconScanRange(seed, rarity)
    if tradeBeaconRange > 0 then
        table.insert(lines, {ltext = plural_t("Display trade routes in current sector", "Display trade routes in sectors with beacons within ${i} range", tradeBeaconRange)})
    end

    return lines
end

-- new functions

function getTradeBeaconScanRange(seed, rarity)
    if rarity.value == 2 then
        return 10
    elseif rarity.value >= 3 then
        math.randomseed(seed)

        if rarity.value == 5 then
            return getInt(61, 80)
        elseif rarity.value == 4 then
            return getInt(41, 60)
        elseif rarity.value == 3 then
            return getInt(21, 40)
        end
    end

    return 0
end

function requestSectorsData(caller)
    if not caller then
        return
    end

    local entityId = Entity().index.string
    local x, y = Sector():getCoordinates()
    local script = "tradebeacon.lua"

    Player(caller):invokeFunction(script, "requestSectorsData", x, y, historySize, entityId, caller)
end

function receiveTradingInfoFromPlayer(caller, sectorsDataString)
    if not caller then
        return
    end

    local sectorsData = TradeBeaconSerializer.deserializeSectorsData(sectorsDataString)

    for _, sectorData in ipairs(sectorsData) do
        tradingData:insert(sectorData)
    end

    updateTradingRoutes()
    invokeClientFunction(Player(caller), "setData", lastSellable, lastBuyable, routes)
end
