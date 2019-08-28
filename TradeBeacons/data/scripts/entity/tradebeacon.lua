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
local traderAffinity = 0
local didWarnOfBurnOut = false

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

        Sector():registerCallback("onEntityEntered", "onEntityEnteredSector")
    end
end

function TradeBeacon.onEntityEnteredSector(index)
    local entity = Entity(index)
    if not valid(entity) then
        return
    end

    local scripts = entity:getScripts()
    local isTrader = false
    for _, name in pairs(scripts) do
        --Fix for path issues on windows
        local fixedName = string.gsub(name, "\\", "/")
        if string.match(fixedName, "data/scripts/entity/merchants/travellingmerchant.lua") then
            isTrader = true
            break
        end
    end

    if isTrader then
        getParentFaction():sendChatMessage("Trade Beacon"%_T, ChatMessageType.Normal, [[Your trade beacon in sector \s(%1%:%2%) detected a travelling merchant!]]%_T, x, y)
        getParentFaction():sendChatMessage("Trade Beacon"%_T, ChatMessageType.Warning, [[Your trade beacon in sector \s(%1%:%2%) detected a travelling merchant!]]%_T, x, y)
    end
end
callable(TradeBeacon, "onEntityEnteredSector")

function TradeBeacon.initUI()
    ScriptUI():registerInteraction("Close"%_t, "")
end

function TradeBeacon.registerWithPlayer()
    local entityId = Entity().index.string
    local x, y = Sector():getCoordinates()
    local tradeData = TradeBeacon.getTradeData()
    local script = "tradebeacon.lua"
    Player(getParentFaction().index):invokeFunction(script, "registerTradeBeacon", x, y, entityId, tradeData, burnOutTime)
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

function TradeBeacon.updateServerDischarged()
    local x, y = Sector():getCoordinates()
    getParentFaction():sendChatMessage("Trade Beacon"%_T, ChatMessageType.Normal, [[Your trade beacon in sector \s(%1%:%2%) burnt out!]]%_T, x, y)
    getParentFaction():sendChatMessage("Trade Beacon"%_T, ChatMessageType.Warning, [[Your trade beacon in sector \s(%1%:%2%) burnt out!]]%_T, x, y)
    TradeBeacon.unregisterWithPlayer()
    Entity():destroy(Entity().index, DamageType.Decay)
    terminate()

end

function TradeBeacon.updateServerCharged()
    TradeBeacon.registerWithPlayer()
    didSendInfoOnce = true

    local timeReminaingHours = math.floor(burnOutTime / 60 / 60)
    if timeReminaingHours > 0 then
        Entity().title = "Trade Beacon (${timeReminaingHours}h)"%_T%{timeReminaingHours = timeReminaingHours }
    else
        local timeRemainingMinutes = math.floor(burnOutTime / 60)
        Entity().title = "Trade Beacon (${timeRemainingMinutes}m)"%_T%{timeRemainingMinutes = timeRemainingMinutes }

        if not didWarnOfBurnOut and timeRemainingMinutes < 10 then
            local x, y = Sector():getCoordinates()
            getParentFaction():sendChatMessage("Trade Beacon"%_T, ChatMessageType.Normal, [[Your trade beacon in sector \s(%1%:%2%) will burn out in %3% minutes]]%_T, x, y, timeRemainingMinutes)
            getParentFaction():sendChatMessage("Trade Beacon"%_T, ChatMessageType.Warning, [[Your trade beacon in sector \s(%1%:%2%) will burn out in %3% minutes]]%_T, x, y, timeRemainingMinutes)
        end
    end

    if traderAffinity > 0 and random():getFloat() < traderAffinity then
        Sector():addScriptOnce("data/scripts/player/spawntravellingmerchant.lua")
    end
end

function TradeBeacon.updateServer(timeStep)
    if burnOutTime == nil then
        return
    end

    burnOutTime = burnOutTime - timeStep

    if burnOutTime <= 0 then
        TradeBeacon.updateServerDischarged()
    else
        TradeBeacon.updateServerCharged()
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
    return {
        burnOutTime = burnOutTime,
        traderAffinity = traderAffinity,
        didWarnOfBurnOut = didWarnOfBurnOut,
    }
end

function TradeBeacon.restore(data)
    data = data or {}
    if data.burnOutTime ~= nil then
        burnOutTime = data.burnOutTime
    end
    if data.traderAffinity then
        traderAffinity = data.traderAffinity
    end
    if data.didWarnOfBurnOut then
        didWarnOfBurnOut = didWarnOfBurnOut
    end
end

function TradeBeacon.onSync()

end
