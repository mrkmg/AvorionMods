-- CraftOrdersLib
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

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
    if not checkCaptain() then return false end

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
        OrderChain.sendError("Can't enchain anything after a ${name} order"%_T {name = last.action})
        return false
    end

    return true
end

local OrderChain_ActivateOrder_COL_Orig = OrderChain.activateOrder

function OrderChain.activateOrder()
    if OrderChain.activeOrder == 0 or not OrderChain.running then return end
    local order = OrderChain.chain[OrderChain.activeOrder]
    print (order.name)
    if moddedOrderChains[order.action] ~= nil then
        OrderChain[moddedOrderChains[order.action].onActivateFunction](order)
        return
    end

    OrderChain_ActivateOrder_COL_Orig()
end

local OrderChain_UpdateServer_COL_Orig = OrderChain.updateServer



function OrderChain.updateServer(timeStep)
    OrderChain_UpdateServer_COL_Orig(timeStep);

    if OrderChain.activeOrder == 0 then return end

    local currentOrder = OrderChain.chain[OrderChain.activeOrder]
    local orderFinished = false

    if moddedOrderChains[currentOrder.action] ~= nil then
        if OrderChain[moddedOrderChains[currentOrder.action].isFinishedFunction](currentOrder) then
            orderFinished = true
        end
    end

    if orderFinished then
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
        return
    end

end
