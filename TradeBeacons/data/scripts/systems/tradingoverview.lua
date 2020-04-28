-- TradeBeacons
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

local SimpleBuffer = include ("simplebuffer")
local TradeBeaconSerializer = include ("tradebeaconserializer")

local lastSellable = {}
local lastBuyable = {}

-- overrides

function TradeBeacons_TradeMappingCompat_collectSectorData()
    local sellable, buyable = gatherData()
    -- don't run while the server is still starting up
    if not Galaxy().sectorLoaded or not Galaxy():sectorLoaded(Sector():getCoordinates()) then return end
    
    local sellkeys, buykeys = {}, {} -- indices for sorting the goods
    local selling,  buying  = {}, {}

    local coords = vec2(Sector():getCoordinates())
    
    for i, good in pairs(buyable) do
        -- good.good.price holds the base price
        local g = good.good.name
        local gdn = good.good:displayName(2)
        local data = selling[g]
        
        if (not data) then
            sellkeys[#sellkeys + 1] = g
            data = {
                name = gdn,
                stations = 0,
                avg_price = 0,
                best_price = 99999999,
            }
        end
        
        local avg = data.avg_price * data.stations
        data.stations = data.stations + 1
        data.avg_price = (avg + good.price) / data.stations
        data.best_price = math.min(good.price, data.best_price)
        selling[g] = data
    end
    
    for i, good in pairs(sellable) do
        local g = good.good.name
        local gdn = good.good:displayName(2)
        local data = buying[g]
        
        if (not data) then
            buykeys[#buykeys + 1] = g
            data = {
                name = gdn,
                stations = 0,
                avg_price = 0,
                best_price = 0,
            }
        end
        
        local avg = data.avg_price * data.stations
        data.stations = data.stations + 1
        data.avg_price = (avg + good.price) / data.stations
        data.best_price = math.max(good.price, data.best_price)
        buying[g] = data
    end
    
    local goods_data = {
        entity  = Entity().name, -- name of the ship which collected the data
        sector  = coords, -- sector where it collected the data
        buying  = buying,
        selling = selling,
    }
    
    invokeFactionFunction(Player(callingPlayer).index, true, "data/scripts/player/trade_mapping.lua", "setData", goods_data)
end

function collectSectorData()
    local TradeMappingMod = ModManager():findEnabled("2063603296")
    if TradeMappingMod then TradeBeacons_TradeMappingCompat_collectSectorData() return end
end

function onInstalled(seed, rarity, permanent)
    historySize = getTradeBeaconScanRange(seed, rarity)
    economyRange = getEconomyRange(seed, rarity, permanent)
    Entity():setValue("beaconScanRange", historySize)

    if onServer() then
        tradingData = SimpleBuffer()
        collectSectorData()
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
    local bonuses = {}

    local tradeBeaconRange = getTradeBeaconScanRange(seed, rarity)
    local economyRange = getEconomyRange(seed, rarity, true)

    local toYesNo = function(line, value)
        if value then
            line.rtext = "Yes"%_t
            line.rcolor = ColorRGB(0.3, 1.0, 0.3)
        else
            line.rtext = "No"%_t
            line.rcolor = ColorRGB(1.0, 0.3, 0.3)
        end
    end

    table.insert(lines, {ltext = "Prices of Goods"%_t, icon = "data/textures/icons/sell.png"})
    toYesNo(lines[#lines], seePrices(seed, rarity))

    table.insert(lines, {ltext = "Price Deviations"%_t, icon = "data/textures/icons/sell.png"})
    toYesNo(lines[#lines], seePriceFactors(seed, rarity))

    table.insert(lines, {ltext = "Trade Route Detection"%_t, icon = "data/textures/icons/sell.png"})
    toYesNo(lines[#lines], tradeBeaconRange > 0)

    if economyRange > 1 then
        table.insert(lines, {ltext = "Economy Overview (Galaxy Map)"%_t, icon = "data/textures/icons/histogram.png", boosted = (permanent and economyRange > 0)})
        toYesNo(lines[#lines], permanent and economyRange > 1)
    elseif economyRange == 1 then
        table.insert(lines, {ltext = "Economy Overview (local)"%_t, icon = "data/textures/icons/histogram.png", boosted = (permanent and economyRange > 0)})
        toYesNo(lines[#lines], permanent and economyRange > 0)
    elseif economyRange == 0 then
        table.insert(lines, {ltext = "Economy Overview"%_t, icon = "data/textures/icons/histogram.png", boosted = (permanent and economyRange > 0)})
        toYesNo(lines[#lines], permanent and economyRange > 0)
    end

    if economyRange > 0 or tradeBeaconRange > 0 then
        table.insert(lines, {})
    end

    if economyRange > 0 then
        if permanent then
            table.insert(lines, {ltext = "Economy Scan Range"%_t, rtext = tostring(economyRange), icon = "data/textures/icons/histogram.png", boosted = permanent})
        else

            if economyRange > 1 then
                table.insert(bonuses, {ltext = "Economy Overview (Galaxy Map)"%_t, rtext = "Yes"%_t, icon = "data/textures/icons/histogram.png"})
            else
                table.insert(bonuses, {ltext = "Economy Overview (local)"%_t, rtext = "Yes"%_t, icon = "data/textures/icons/histogram.png"})
            end

            table.insert(bonuses, {ltext = "Economy Scan Range"%_t, rtext = tostring(economyRange), icon = "data/textures/icons/histogram.png"})
        end
    end

    if tradeBeaconRange > 0 then
        table.insert(lines, {ltext = "Trade Beacon Range"%_t, rtext = tostring(tradeBeaconRange), icon = "data/textures/icons/sell.png"})
    end

    if not permanent and #bonuses == 0 then bonuses = nil end

    return lines, bonuses
end

function getDescriptionLines(seed, rarity, permanent)
    local lines = {}

    local economyRange = getEconomyRange(seed, rarity, true)
    if economyRange > 0 then
        if economyRange == 1 then
            table.insert(lines, {ltext = "Shows supply & demand of current sector"%_t})
        else
            table.insert(lines, {ltext = "Shows supply & demand of nearby sectors"%_t})
        end
    end

    local tradeBeaconRange = getTradeBeaconScanRange(seed, rarity)
    if tradeBeaconRange > 0 then
        table.insert(lines, {ltext = plural_t("Display trade routes in current sector", "Display trade routes in sectors with beacons within ${i} range", tradeBeaconRange)})
    end

    if seePrices(seed, rarity) or seePriceFactors(seed, rarity) then
        table.insert(lines, {ltext = "Shows prices of all stations in sector"%_t})
    else
        table.insert(lines, {ltext = "Shows goods of all stations in sector"%_t})
    end

    return lines
end
-- new functions

function getTradeBeaconScanRange(seed, rarity)
    math.randomseed(seed)

    if rarity.value == 5 then
        return getInt(61, 80)
    elseif rarity.value == 4 then
        return getInt(41, 60)
    elseif rarity.value == 3 then
        return getInt(21, 40)
    elseif rarity.value == 2 then
        return getInt(10, 20)
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
