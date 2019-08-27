package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include ("stringutility")
include ("sync")
local TradingUtility = include ("tradingutility")
local TradeBeaconSerializer = include ("tradebeaconserializer")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace TradeBeacon
TradeBeacon = {}

local burnOutTime

defineSyncFunction("data", TradeBeacon)

function TradeBeacon.getUpdateInterval()
    if didSendInfoOnce then
        return 60
    else
        return 1
    end
end

function TradeBeacon.interactionPossible()
    return true
end

function TradeBeacon.initialize()
    if onServer() then
        burnOutTime = Entity():getValue("lifespan") * 60 * 60
    end
end

function TradeBeacon.initUI()
    ScriptUI():registerInteraction("Close"%_t, "")
end

function TradeBeacon.registerWithPlayer()
    local entityId = Entity().index.string
    local x, y = Sector():getCoordinates()
    local tradeData = TradeBeacon.getTradeData()
    local script = "tradebeacon.lua"
    Player(getParentFaction().index):invokeFunction(script, "registerTradeBeacon", x, y, entityId, tradeData)
end

function TradeBeacon.unregisterWithPlayer()
    local entityId = Entity().index.string
    local script = "tradebeacon.lua"
    Player(getParentFaction().index):invokeFunction(script, "deregisterTradeBeacon", entityId)
end

function TradeBeacon.getTradeData()
    local sellable, buyable = TradingUtility.detectBuyableAndSellableGoods()

    return TradeBeaconSerializer.serializeSectorData({sellable = sellable, buyable = buyable})
end

function TradeBeacon.updateServer(timeStep)
    if burnOutTime == nil then
        return
    end

    burnOutTime = burnOutTime - timeStep

    local x, y = Sector():getCoordinates()
    if burnOutTime <= 0 then
        getParentFaction():sendChatMessage("Trade Beacon"%_T, ChatMessageType.Normal, [[Your trade beacon in sector \s(%1%:%2%) burnt out!]]%_T, x, y)
        getParentFaction():sendChatMessage("Trade Beacon"%_T, ChatMessageType.Warning, [[Your trade beacon in sector \s(%1%:%2%) burnt out!]]%_T, x, y)
        TradeBeacon.unregisterWithPlayer()
        Entity():destroy(Entity().index, DamageType.Decay)
        terminate()
    else
        TradeBeacon.registerWithPlayer()
        didSendInfoOnce = true
    end
end

function TradeBeacon.updateClient(timeStep)
    if burnOutTime == nil then
        return
    end

    burnOutTime = burnOutTime - timeStep
    TradeBeacon.sync()
end

function TradeBeacon.secure()
    return {burnOutTime = burnOutTime}
end

function TradeBeacon.restore(data)
    data = data or {}
    if data.burnOutTime ~= nil then
        burnOutTime = data.burnOutTime
    end
end

function TradeBeacon.onSync()

end
