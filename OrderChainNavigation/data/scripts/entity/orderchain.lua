function OrderChain.OCN_gotoNext()
    if onClient() then
        invokeServerFunction("OCN_gotoNext")
    else
        Entity():invokeFunction("data/scripts/entity/craftorders.lua", "removeSpecialOrders")
        if OrderChain.executableOrders > OrderChain.activeOrder then
            -- activate next order
            OrderChain.activeOrder = OrderChain.activeOrder + 1
            OrderChain.activateOrder()
        elseif #OrderChain.chain > OrderChain.activeOrder then
            -- set running back to false when no executable order is in the chain
            OrderChain.running = false
        else
            -- end of chain reached
            OrderChain.activeOrder = 0
            OrderChain.finished = true

            ShipAI():setStatus("Idle /* ship AI status */"%_T, {})
        end

        OrderChain.updateShipOrderInfo()
    end
end
callable(OrderChain, "OCN_gotoNext")

function OrderChain.OCN_gotoPrev()
    if onClient() then
        invokeServerFunction("OCN_gotoPrev")
    else
        if OrderChain.activeOrder > 1 then
            Entity():invokeFunction("data/scripts/entity/craftorders.lua", "removeSpecialOrders")
            OrderChain.activeOrder = OrderChain.activeOrder - 1
            OrderChain.activateOrder()
        end

        OrderChain.updateShipOrderInfo()
    end
end
callable(OrderChain, "OCN_gotoPrev")