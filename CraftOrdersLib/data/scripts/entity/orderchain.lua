-- CraftOrdersLib - by Kevin Gravier (MrKMG)

local moddedOrderChains = {};

function OrderChain.registerModdedOrderChain(id, orderChainDef)
    if moddedOrderChains[id] == nil then
        moddedOrderChains[id] = orderChainDef
    end
end

function OrderChain.canEnchainAfter(id, order)
    if moddedOrderChains[id] == nil then
        return true
    end

    if moddedOrderChains[id].canEnchainAfter == nil then
        return true
    end

    return OrderChain[moddedOrderChains[id].canEnchainAfterCheck](order)
end

function OrderChain.canEnchain(order)
    local last = OrderChain.chain[#OrderChain.chain]
    if not last then return true end

    if last.action == OrderType.Loop then
        OrderChain.sendError("Can't enchain anything after a loop."%_T)
        return false
    elseif last.action == OrderType.Patrol then
        OrderChain.sendError("Can't enchain anything after a patrol order."%_T)
        return false
    elseif last.action == OrderType.Escort then
        OrderChain.sendError("Can't enchain anything after an escort order."%_T)
        return false
    elseif last.action == OrderType.FlyToPosition then
        OrderChain.sendError("Can't enchain anything after a fly order."%_T)
        return false
    elseif last.action == OrderType.GuardPosition then
        OrderChain.sendError("Can't enchain anything after a guard order."%_T)
        return false
    elseif last.action == OrderType.Mine and last.persistent then
        OrderChain.sendError("Can't enchain anything after a persistent mine order."%_T)
        return false
    elseif last.action == OrderType.Salvage and last.persistent then
        OrderChain.sendError("Can't enchain anything after a persistent salvage order."%_T)
        return false
    elseif not OrderChain.canEnchainAfter(last.action, last) then
        OrderChain.sendError("Can enchain anything after a ${name} order"%_T {name = last.action})
        return false
    end

    return true
end

function OrderChain.activateOrder(order)
    if order.action == OrderType.Jump then
        OrderChain.activateJump(order.x, order.y)
    elseif order.action == OrderType.Mine then
        OrderChain.activateMine()
    elseif order.action == OrderType.Salvage then
        OrderChain.activateSalvage()
    elseif order.action == OrderType.Loop then
        OrderChain.activateLoop(order.loopIndex)
    elseif order.action == OrderType.Aggressive then
        OrderChain.activateAggressive(order.attackCivilShips, order.canFinish)
    elseif order.action == OrderType.Patrol then
        OrderChain.activatePatrol()
    elseif order.action == OrderType.Escort then
        OrderChain.activateEscort(order.craftId)
    elseif order.action == OrderType.BuyGoods then
        OrderChain.activateBuyGoods(unpack(order.args))
    elseif order.action == OrderType.SellGoods then
        OrderChain.activateSellGoods(unpack(order.args))
    elseif order.action == OrderType.AttackCraft then
        OrderChain.activateAttackCraft(order.targetId)
    elseif order.action == OrderType.FlyThroughWormhole then
        OrderChain.activateFlyThroughWormhole(order.targetId)
    elseif order.action == OrderType.FlyToPosition then
        OrderChain.activateFlyToPosition(order.px, order.py, order.pz)
    elseif order.action == OrderType.GuardPosition then
        OrderChain.activateGuardPosition(order.px, order.py, order.pz)
    elseif order.action == OrderType.RefineOres then
        OrderChain.activateRefineOres()
    elseif order.action == OrderType.Board then
        OrderChain.activateBoarding(order.targetId)
    elseif moddedOrderChains[order.action] ~= nil then
        OrderChain[moddedOrderChains[order.action].onActivateFunction](order)
    end
end

function OrderChain.updateServer(timeStep)
    local entity = Entity()
    if entity:getPilotIndices() then
        ShipAI():setStatus("Player /* ship AI status*/"%_T, {})
        return
    end

    if OrderChain.activeOrder == 0 then
        -- setting this every tick is a safeguard against other potential issues
        -- setting the status is efficient enough to not send updates if nothing changed
        ShipAI():setStatus("Idle /* ship AI status */"%_T, {})
        return
    end

    local currentOrder = OrderChain.chain[OrderChain.activeOrder]
    local orderFinished = false

    if currentOrder.action == OrderType.Jump then
        if OrderChain.jumpOrderFinished(currentOrder.x, currentOrder.y) then
            orderFinished = true
        end
    elseif currentOrder.action == OrderType.Mine then
        if OrderChain.mineOrderFinished(currentOrder.persistent) then
            orderFinished = true
        end
    elseif currentOrder.action == OrderType.Salvage then
        if OrderChain.salvageOrderFinished(currentOrder.persistent) then
            orderFinished = true
        end
    elseif currentOrder.action == OrderType.Loop then
        orderFinished = true
    elseif currentOrder.action == OrderType.Aggressive then
        if OrderChain.aggressiveOrderFinished() then
            orderFinished = true
        end
    elseif currentOrder.action == OrderType.BuyGoods then
        if OrderChain.buyGoodsOrderFinished() then
            orderFinished = true
        end
    elseif currentOrder.action == OrderType.SellGoods then
        if OrderChain.sellGoodsOrderFinished() then
            orderFinished = true
        end
    elseif currentOrder.action == OrderType.AttackCraft then
        if OrderChain.attackCraftOrderFinished(currentOrder.targetId) then
            orderFinished = true
        end
    elseif currentOrder.action == OrderType.FlyThroughWormhole then
        if OrderChain.flyThroughWormholeOrderFinished(currentOrder.x, currentOrder.y) then
            orderFinished = true
        end
    elseif currentOrder.action == OrderType.RefineOres then
        if OrderChain.refineOresOrderFinished(currentOrder.x, currentOrder.y) then
            orderFinished = true
        end
    elseif currentOrder.action == OrderType.Board then
        if OrderChain.boardingOrderFinished() then
            orderFinished = true
        end
    elseif moddedOrderChains[currentOrder.action] ~= nil then
        if OrderChain[moddedOrderChains[currentOrder.action].isFinishedFunction](currentOrder) then
            orderFinished = true
        end
    end

    if orderFinished then
        OrderChain.activeOrder = OrderChain.activeOrder + 1

        if #OrderChain.chain >= OrderChain.activeOrder then
            -- activate next order
            OrderChain.activateOrder(OrderChain.chain[OrderChain.activeOrder])
        else
            -- end of chain reached
            OrderChain.activeOrder = 0

            ShipAI():setStatus("Idle /* ship AI status */"%_T, {})
        end

        OrderChain.updateShipOrderInfo()
    end
end