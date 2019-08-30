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
local didSendInfoOnce = false

defineSyncFunction("data", TradeBeacon)

function TradeBeacon.getUpdateInterval()
    if didSendInfoOnce then
        return 120
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
        Sector():registerCallback("onRestoredFromDisk", "onRestoredFromDisk")
    end
end

function TradeBeacon.onRestoredFromDisk(time)
    TradeBeacon.updateServer(time)
end

function TradeBeacon.onEntityEnteredSector(index)
    local entity = Entity(index)
    if valid(entity) and entity:hasScript("travellingmerchant.lua") then
        getParentFaction():sendChatMessage("Trade Beacon"%_T, ChatMessageType.Normal, [[Your trade beacon in sector \s(%1%:%2%) detected a travelling merchant!]]%_T, x, y)
        getParentFaction():sendChatMessage("Trade Beacon"%_T, ChatMessageType.Warning, [[Your trade beacon in sector \s(%1%:%2%) detected a travelling merchant!]]%_T, x, y)
    end
end
callable(TradeBeacon, "onEntityEnteredSector")

function TradeBeacon.initUI()
    ScriptUI():registerInteraction("Close"%_t, "")
end

function TradeBeacon.getPlayersToNotify()
    local faction = getParentFaction()
    local playersToAlert = {}
    if faction.isPlayer then
        table.insert(playersToAlert, Player(faction.index))
    elseif faction.isAlliance then
        local alliance = Alliance(faction.index)
        local players = {Server():getOnlinePlayers()}
        for _, player in pairs(players) do
            if alliance:contains(player.index) then
                table.insert(playersToAlert, player)
            end
        end
    end
    return playersToAlert
end

function TradeBeacon.registerWithPlayer()
    local entityId = Entity().index.string
    local x, y = Sector():getCoordinates()
    local tradeData = TradeBeacon.getTradeData()
    local script = "tradebeacon.lua"
    for _, player in ipairs(TradeBeacon.getPlayersToNotify()) do
        player:invokeFunction(script, "registerTradeBeacon", x, y, entityId, tradeData, burnOutTime)
    end
    didSendInfoOnce = true
end

function TradeBeacon.unregisterWithPlayer()
    local entityId = Entity().index.string
    local script = "tradebeacon.lua"
    for _, player in ipairs(TradeBeacon.getPlayersToNotify()) do
        player:invokeFunction(script, "deregisterTradeBeacon", entityId)
    end
end

function TradeBeacon.getTradeData()
    local sellable, buyable = TradingUtility.detectBuyableAndSellableGoods()

    return TradeBeaconSerializer.serializeSectorData({sellable = sellable, buyable = buyable})
end

function TradeBeacon.updateTitle()
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
    TradeBeacon.updateTitle()
    TradeBeacon.registerWithPlayer()

    if traderAffinity > 0 and random():getFloat() < traderAffinity then
        Sector():addScriptOnce("data/scripts/player/spawntravellingmerchant.lua")
    end
end

function TradeBeacon.updateServer(timeStep)
    if burnOutTime == nil then
        burnOutTime = 0
    end

    burnOutTime = burnOutTime - timeStep
    local x, y = Sector():getCoordinates()
    print ("Beacon updated:   ", x, y, timeStep)
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
