SimpleBuffer = include ("simplebuffer")

local isReceivingMany = false

-- Adjust change the data source to use the new satellite
function onInstalled(seed, rarity, permanent)
    historySize = getMaxTradeBeacons(seed, rarity)
    tradingData = SimpleBuffer()
end

-- not needed anymore
function collectSectorData()
    return
end


function getData()
    if callingPlayer then
        tradingData = SimpleBuffer()
        registerWithPlayer(callingPlayer)
    end

    local sellable, buyable = gatherData()

    if tradingData then
        tradingData.data[tradingData.index] = {sellable = sellable, buyable = buyable}
        updateTradingRoutes()
    end

    if callingPlayer then
        invokeClientFunction(Player(callingPlayer), "setData", sellable, buyable, routes)
    end

    return sellable, buyable, routes or {}
end
callable(nil, "getData")

function registerWithPlayer(caller)
    local entityId = Entity().index.string
    local x, y = Sector():getCoordinates()
    local script = "tradebeacon.lua"
    Player(getParentFaction().index):invokeFunction(script, "registerTradingShip", x, y, historySize, entityId, caller)
end

function unregisterWithPlayer()
    local entityId = Entity().index.string
    local script = "tradebeacon.lua"
    Player(getParentFaction().index):invokeFunction(script, "deregisterTradingShip", entityId)
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

    local tradeBeaconRange = getMaxTradeBeacons(seed, rarity)
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

    local tradeBeaconRange = getMaxTradeBeacons(seed, rarity)
    if tradeBeaconRange > 0 then
        table.insert(lines, {ltext = plural_t("Display trade routes in current sector", "Display trade routes in sectors with beacons within ${i} range", tradeBeaconRange)})
    end

    return lines
end

function onSectorChanged()
end

function receiveTradingInfoFromBeacon(caller, data)
    local semiUnserializedData = loadstring(data)()

    for _, d in pairs(semiUnserializedData.sellable) do
        d.stationIndex = Uuid(d.stationIndex)
        d.good = TradingGood(d.good.name, d.good.plural, d.good.description, d.good.icon, d.good.price, d.good.size)
        d.coords = vec2(d.coords.x, d.coords.y)
    end
    for _, d in pairs(semiUnserializedData.buyable) do
        d.stationIndex = Uuid(d.stationIndex)
        d.good = TradingGood(d.good.name, d.good.plural, d.good.description, d.good.icon, d.good.price, d.good.size)
        d.coords = vec2(d.coords.x, d.coords.y)
    end

    tradingData:insert(semiUnserializedData)


end
callable(nil, "receiveTradingInfoFromBeacon")
