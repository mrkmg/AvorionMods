
-- Adjust change the data source to use the new satellite
function onInstalled(seed, rarity, permanent)
    historySize = getMaxTradeBeacons(seed, rarity)
    tradingData = RingBuffer(math.max(historySize, 1))
    collectSectorData()
end

function initalizationFinished()
    collectSectorData()
end

function getMaxTradeBeacons(seed, rarity)
    if rarity.value == 2 then
        return 4
    elseif rarity.value >= 3 then
        math.randomseed(seed)

        if rarity.value == 5 then
            return getInt(21, 40)
        elseif rarity.value == 4 then
            return getInt(11, 20)
        elseif rarity.value == 3 then
            return getInt(5, 10)
        end
    end

    return 0
end

function getTooltipLines(seed, rarity, permanent)
    local lines = {}

    if seePrices(seed, rarity) then
        table.insert(lines, {ltext = "Display prices of goods"%_t, icon = "data/textures/icons/sell.png"})
    end
    if seePriceFactors(seed, rarity) then
        table.insert(lines, {ltext = "Display price ratios of goods"%_t, icon = "data/textures/icons/sell.png"})
    end

    local maxBeacons = getMaxTradeBeacons(seed, rarity)
    if maxBeacons > 0 then
        table.insert(lines, {ltext = "Trade Route Sectors"%_t, rtext = tostring(maxBeacons), icon = "data/textures/icons/sell.png"})
    end

    return lines
end

function getDescriptionLines(seed, rarity, permanent)
    local lines =
    {
        {ltext = "View trading offers of stations in sector"%_t}
    }

    local maxBeacons = getMaxTradeBeacons(seed, rarity)
    if maxBeacons > 0 then
        table.insert(lines, {ltext = plural_t("Display trade routes in current sector", "Display trade routes in ${i} sectors with beacons", history)})
    end

    return lines
end

originalSectorDataCollectorFunc = collectSectorData
function collectSectorData()
    local entityId = Entity().index
    local x, y = Sector():getCoordinates()
    Player():invokeFunction("data/scripts/player/tradebeacon.lua", "getTradingData", x, y, entityId)
    originalSectorDataCollectorFunc()
end

function receiveTradingInfoFromBeacon(data)
    local semiUnserializedData = loadstring(data)()

    for _, d in pairs(semiUnserializedData.sellable) do
        d.stationIndex = Uuid(d.stationIndex)
        d.good = TradingGood(d.good.name, d.good.plural, d.good.description, d.good.icon, d.good.price, d.good.size)
        d.coords = vec2(d.coors.x, d.coords.y)
    end
    for _, d in pairs(semiUnserializedData.buyable) do
        d.stationIndex = Uuid(d.stationIndex)
        d.good = TradingGood(d.good.name, d.good.plural, d.good.description, d.good.icon, d.good.price, d.good.size)
        d.coords = vec2(d.coors.x, d.coords.y)
    end
    tradingData:insert(semiUnserializedData)
end
callable(nil, "receiveTradingInfoFromBeacon")
