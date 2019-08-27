package.path = package.path .. ";data/scripts/lib/?.lua"
include ("extutils")

local TradeBeaconSerializer = {}

local function serializeTradeGood(tradeGood)
    return {
        name = tradeGood.name,
        plural = tradeGood.plural,
        description = tradeGood.description,
        icon = tradeGood.icon,
        price = tradeGood.price,
        size = tradeGood.size,
    }
end

local function deserializeTradeGood(tradeGood)
    return TradingGood(
            tradeGood.name,
            tradeGood.plural,
            tradeGood.description,
            tradeGood.icon,
            tradeGood.price,
            tradeGood.size)
end

local function serializeItem(item)
    item.good = serializeTradeGood(item.good)
    item.coords = {x = item.coords.x, y = item.coords.y}
    item.stationIndex = item.stationIndex.string
end

local function deserializeItem(item)

    item.stationIndex = Uuid(item.stationIndex)
    item.good = deserializeTradeGood(item.good)
    item.coords = vec2(item.coords.x, item.coords.y)
end

local function serializeSectorData(sectorData)
    for _, data in pairs(sectorData.sellable) do serializeItem(data) end
    for _, data in pairs(sectorData.buyable) do serializeItem(data) end
end

local function deserializeSectorData(sectorData)
    for _, data in pairs(sectorData.sellable) do deserializeItem(data) end
    for _, data in pairs(sectorData.buyable) do deserializeItem(data) end
end

function TradeBeaconSerializer.serializeSectorData(sectorData)
    serializeSectorData(sectorData)
    return serialize(sectorData)
end

function TradeBeaconSerializer.deserializeSectorData(sectorDataString)
    local sectorData = loadstring(sectorDataString)()
    deserializeSectorData(sectorData)
    return sectorData
end

function TradeBeaconSerializer.serializeSectorsData(sectorsData)
    for _, sectorData in ipairs(sectorsData) do
        serializeSectorData(sectorData)
    end
    return serialize(sectorsData)
end

function TradeBeaconSerializer.deserializeSectorsData(sectorsDataString)
    local sectorsData = loadstring(sectorsDataString)()
    for _, sectorData in ipairs(sectorsData) do
        deserializeSectorData(sectorData)
    end
    return sectorsData
end

return TradeBeaconSerializer
