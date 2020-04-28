
local OrderBook_delayUpdateChain = false
function OrderChain.OrderBook_setChain(chain, replace, keepActive)
    if onClient() then
        invokeServerFunction("OrderBook_setChain", chain, replace, keepActive)
    else
        if not checkCaptain() then 
            OrderChain.sendError("Craft has no captain")
            return 
        end

        local entity = Entity()
        if entity:getPilotIndices() then 
            OrderChain.sendError("Can not assign orders to the craft you are piloting");
            return
        end

        local nextChain = #OrderChain.chain or 0

        if replace then
            nextChain = 0
        end

        local ox, oy = Sector():getCoordinates()

        if not replace then
            for i, order in pairs(chain) do
                if order.action == OrderType.Jump and order.relative == true then
                    order.x = ox
                    order.y = oy
                end
            end
        end

        local cx = ox
        local cy = oy
        for i, order in pairs(OrderChain.chain) do
            if i > OrderChain.activeOrder then
                if order.action == OrderType.Jump or order.action == OrderType.FlyThroughWormhole then
                    cx = order.x
                    cy = order.y
                end
            end
        end

        for _, order in pairs(chain) do
            if order.action == OrderType.Jump then
                local jumpValid, error = entity:isJumpRouteValid(cx, cy, order.x, order.y)
                if not jumpValid then
                    OrderChain.sendError("Order chain is not compatible with this ship. A jump would not be possible.")
                    return
                end

                cx = order.x
                cy = order.y
            end

            if order.action == OrderType.FlyThroughWormhole then
                cx = order.x
                cy = order.y
            end

            if order.action == OrderType.Loop then
                order.loopIndex = order.loopIndex + nextChain
            end
        end

        OrderBook_delayUpdateChain = true
        local resetActiveOrder = 0
        if replace then
            if keepActive then
                resetActiveOrder = math.max(0, OrderChain.activeOrder - 1)
            end
            OrderChain.clearAllOrders(true)
        end
        for _, order in pairs(chain) do
            if OrderChain.canEnchain(order) then
                OrderChain.enchain(order)
            end
        end
        OrderBook_delayUpdateChain = false
        if replace then
            OrderChain.activeOrder = resetActiveOrder
        end
        OrderChain.runOrders()
    end
end
callable(OrderChain, "OrderBook_setChain")

local OrderChain_updateChain_OrderBook_orig = OrderChain.updateChain
function OrderChain.updateChain()
    if not OrderBook_delayUpdateChain then
        OrderChain_updateChain_OrderBook_orig()
    end
end