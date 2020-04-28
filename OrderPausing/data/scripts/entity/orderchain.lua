-- OrderPausing
-- by Kevin Gravier (MrKMG)
-- MIT License 2020

local isPaused = false

function OrderChain.pause()
    isPaused = true
    if onClient() then
        invokeServerFunction("pause")
    else
        OrderChain.updateShipOrderInfo()
        Entity():invokeFunction("data/scripts/entity/craftorders.lua", "removeSpecialOrders")
        ShipAI():setPassive()
    end
    -- TODO add more info
end
callable(OrderChain, "pause")

function OrderChain.resume()
    isPaused = false
    if onClient() then
        invokeServerFunction("resume")
    else
        OrderChain.activateOrder()
    end
end
callable(OrderChain, "resume")

local OrderChain_getOrderInfo_OrderPausing_orig = OrderChain.getOrderInfo
function OrderChain.getOrderInfo()
    local info = OrderChain_getOrderInfo_OrderPausing_orig()
    info.paused = isPaused
    return info
end

local OrderChain_ActivateOrder_OrderPausing_Orig = OrderChain.activateOrder
function OrderChain.activateOrder()
    if isPaused then
        return
    end

    OrderChain_ActivateOrder_OrderPausing_Orig()
end

local OrderChain_secure_OrderPausing_orig = OrderChain.secure
function OrderChain.secure()
    local orig = OrderChain_secure_OrderPausing_orig()
    orig.isPaused = isPaused
    return orig
end

local OrderChain_restore_OrderPausing_orig = OrderChain.restore
function OrderChain.restore(data)
    isPaused = data.isPaused
    OrderChain_restore_OrderPausing_orig(data)
end

local OrderChain_updateServer_OrderPausing_orig = OrderChain.updateServer
function OrderChain.updateServer(timeStep)
    if isPaused then
        return
    end
    OrderChain_updateServer_OrderPausing_orig(timeStep)
end