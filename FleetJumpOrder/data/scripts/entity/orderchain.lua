-- Fleet Jump through Gate Command Mod by MassCraxx
-- v3
-- Modified by
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

function OrderChain.replaceCurrent(order)
    if OrderChain.activeOrder == 0 then
        OrderChain.clear()
        table.insert(OrderChain.chain, order)
    else
        OrderChain.chain[OrderChain.activeOrder] = order
        if not (#OrderChain.chain == 1) then
            OrderChain.activateOrder(order)
        end
    end

    OrderChain.updateChain()
end

function OrderChain.addJumpOrder(x, y)
    if onClient() then
        invokeServerFunction("addJumpOrder", x, y)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then
            local player = Player(callingPlayer)
            player:sendChatMessage("", ChatMessageType.Error, "You don't have permission to do that."%_T)
            return
        end
    end

    local shipX, shipY = Sector():getCoordinates()

    for _, action in pairs(OrderChain.chain) do
        if action.action == OrderType.Jump or action.action == OrderType.FlyThroughWormhole then
            shipX = action.x
            shipY = action.y
        end
    end

    local jumpValid, error = Entity():isJumpRouteValid(shipX, shipY, x, y)

    local order = {action = OrderType.Jump, x = x, y = y}

    if OrderChain.canEnchain(order) then
        OrderChain.enchain(order)
    end
    if not jumpValid and callingPlayer then
        local player = Player(callingPlayer)
        player:sendChatMessage("", ChatMessageType.Error, "Jump order may not be possible!")
    end
end
callable(OrderChain, "addJumpOrder")

function OrderChain.addLoop(a, b)
    if onClient() then
        invokeServerFunction("addLoop", a, b)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end

--    print ("addLoop " .. tostring(a) .. " " .. tostring(b))

    local loopIndex
    if a and not b then
        -- interpret as action index
        loopIndex = a
    elseif a and b then
        -- interpret as coordinates
        local x, y = a, b
        local cx, cy = Sector():getCoordinates()
        local i = OrderChain.activeOrder
        local chain = OrderChain.chain

        while i > 0 and i <= #chain do
            local current = chain[i]

            if cx == x and cy == y then
                loopIndex = i
                break
            end

            if current.action == OrderType.Jump or current.action == OrderType.FlyThroughWormhole then
                cx, cy = current.x, current.y
            end

            i = i + 1
        end

        if not loopIndex then
            OrderChain.sendError("Could not find any orders at %i:%i!"%_T, x, y)
        end
    end

    if not loopIndex or loopIndex == 0 or loopIndex > #OrderChain.chain then return end

    local order = {action = OrderType.Loop, loopIndex = loopIndex}

    if OrderChain.canEnchain(order) then
        OrderChain.enchain(order)
    end
end
callable(OrderChain, "addLoop")

function OrderChain.addWormholeOrder()
    if onClient() then
        invokeServerFunction("addWormholeOrder")
        return
    end

    local gates = {Sector():getEntitiesByComponent(ComponentType.WormHole)}
    for _, entity in pairs(gates) do
        if entity:getPlan() == nil then
            local sx, sy = entity:getWormholeComponent():getTargetCoordinates()
            OrderChain.addFlyThroughWormholeOrder(entity.id, sx , sy, false);

            if OrderChain.canEnchain(order) then
                OrderChain.enchain(order)
                return
            end
        end
    end

    local x, y = Sector():getCoordinates()
    OrderChain.sendError("No Wormhole found in Sector %i:%i!"%_T, x, y)
end
callable(OrderChain, "addWormholeOrder")

function OrderChain.addFlyThroughWormholeOrder(targetId, sx , sy, replace)
    if onClient() then
        invokeServerFunction("addFlyThroughWormholeOrder", targetId)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end

    if (sx == nil or sy == nil) and valid(Entity(targetId)) then
        sx, sy = Entity(targetId):getWormholeComponent():getTargetCoordinates()
    end

    local order = {action = OrderType.FlyThroughWormhole, targetId = targetId.string, x = sx, y = sy}

    if replace then
        OrderChain.replaceCurrent(order)
    elseif OrderChain.canEnchain(order) then
        OrderChain.enchain(order)
    end
end
callable(OrderChain, "addFlyThroughWormholeOrder")

function OrderChain.activateJump(x, y)
    local shipX, shipY = Sector():getCoordinates()
    local jumpValid, error = Entity():isJumpRouteValid(shipX, shipY, x, y)

    --print("activated jump to sector " .. x .. ":" .. y)
    if jumpValid then
        local ai = ShipAI()
        ai:setStatus("Jumping to ${x}:${y} /* ship AI status */"%_T, {x=x, y=y})
        ai:setJump(x, y)
    else
        local gates = {Sector():getEntitiesByComponent(ComponentType.WormHole)}
        for _, entity in pairs(gates) do
            local wh = entity:getWormholeComponent()
            local whX, whY = wh:getTargetCoordinates()
            if whX == x and whY == y then
                --print("replacing jump with wormhole order");
                OrderChain.addFlyThroughWormholeOrder(entity.id, x, y, true)
                return
            end
        end

        ShipAI():setStatus("Unable to jump /* ship AI status */"%_T, {x=x, y=y})
        OrderChain.chain[OrderChain.activeOrder].invalid = true
        OrderChain.updateShipOrderInfo()
        -- TODO Not translatable
        local text = error.." Standing by."
        print(text)

        OrderChain.sendError(text)
    end
end

function OrderChain.activateFlyThroughWormhole(targetId)
    ShipAI():setStatus("Jumping to ${x}:${y} /* ship AI status */"%_T, {x=x, y=y})

    Entity():invokeFunction("data/scripts/entity/craftorders.lua", "flyThroughWormhole", targetId)
--    print("activated fly through wormhole")
end
