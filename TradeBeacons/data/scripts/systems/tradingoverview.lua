-- TradeBeacons
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

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
    Entity():setValue("beaconScanRange", historySize)

    if onServer() then
        tradingData = SimpleBuffer()
        if historySize > 1 then
            local sellable, buyable = gatherData()
            tradingData:insert({sellable = sellable, buyable = buyable})
            requestSectorsData()
        end
    end
end

function getData()
    local sellable, buyable = gatherData()

    if historySize > 1 then
        lastSellable = sellable
        lastBuyable = buyable
        requestSectorsData(callingPlayer)
        -- by convention last element of tradingData is the current sector
        -- so let's update it
        tradingData[tradingData.last] = {sellable = sellable, buyable = buyable}
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
    local player
    if caller then
        -- triggered by player interaction so we can be specific
        player = Player(caller)
    elseif onServer() then
        local faction = getParentFaction()
        if faction.isPlayer then
            -- only one choice for the player
            player = Player(faction.index)
        elseif faction.isAlliance then
            -- TODO: maybe we can pick one in a more principled way?
            --  or maybe trade beacons should be registering themselves with
            --  trading systems instead of players?

            local alliance = Alliance(faction.index)
            local players = {Server():getOnlinePlayers()}
            for _, p in pairs(players) do
                if alliance:contains(p.index) then
                    player = p
                    break
                end
            end
            if not player then
                -- no player is logged in, so we don't have anywhere to get the
                -- data from, no-op
                return
            end
        else
            -- faction isn't a player or alliance, no-op
            return
        end
    else
        -- no caller and not on server, this is unexpected, so no-op
        return
    end

    local entityId = Entity().index.string
    local x, y = Sector():getCoordinates()
    local script = "tradebeacon.lua"

    player:invokeFunction(script, "requestSectorsData", x, y, historySize, entityId, caller)
end

function receiveTradingInfoFromPlayer(caller, sectorsDataString)
    local sectorsData = TradeBeaconSerializer.deserializeSectorsData(sectorsDataString)
    -- clear out tradingData and populate
    tradingData = SimpleBuffer()
    for _, sectorData in ipairs(sectorsData) do
        tradingData:insert(sectorData)
    end

    local sellable, buyable = gatherData()
    tradingData:insert({sellable = sellable, buyable = buyable})

    updateTradingRoutes()

    if caller then
        -- callback triggered by player interaction, so update their data
        invokeClientFunction(Player(caller), "setData", lastSellable, lastBuyable, routes)
    end
end
