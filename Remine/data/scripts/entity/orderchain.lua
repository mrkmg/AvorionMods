function OrderChain.addRemine(rx, ry)
    if onClient() then
        invokeServerFunction("addRemine", rx, ry)
    else
        local cx, cy = Sector():getCoordinates()
        for _, action in pairs(OrderChain.chain) do
            if action.action == OrderType.Jump or action.action == OrderType.FlyThroughWormhole then
                cx = action.x
                cy = action.y
            end
        end
        
        if not OrderChain.canRemine(cx, cy, rx, ry) then return end

        local isOwnSector = cx == rx and cy == ry
        local nextOrder = #OrderChain.chain + 1

        OrderChain.addMineOrder(false)
        if not isOwnSector then OrderChain.addJumpOrder(rx, ry) end
        OrderChain.addRefineOresOrder()
        if not isOwnSector then OrderChain.addJumpOrder(cx, cy) end
        OrderChain.addLoop(nextOrder)
    end
end
callable(OrderChain, "addRemine")

function OrderChain.canRemine(cx, cy, rx, ry)
    if rx == nil or ry == nil then
        Faction(Player().index):sendChatMessage("", ChatMessageType.Error, "No refine sector marked."%_t, 1)
        return false
    end
    
    if cx == rx and cy == ry then return true end

    local jumpValid, error = Entity():isJumpRouteValid(cx, cy, rx, ry)

    if not jumpValid then
        Faction(Player().index):sendChatMessage("", ChatMessageType.Error, "Refine sector is out of reach."%_t, 1)
        return false
    end

    return true
end