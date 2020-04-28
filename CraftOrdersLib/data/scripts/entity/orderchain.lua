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

local OrderChain_canEnchain_CraftOrdersLib_orig = OrderChain.canEnchain
function OrderChain.canEnchain(order)
    if not OrderChain_canEnchain_CraftOrdersLib_orig() then
        return false
    end
    
    local last = OrderChain.chain[#OrderChain.chain]
    if not last then 
        return true 
    end

    if not OrderChain.canEnchainAfter(last.action, last) then
        OrderChain.sendError("Can't enchain anything after a ${name} order"%_T {name = last.action})
        return false
    end

    return true
end

local OrderChain_ActivateOrder_CraftOrdersLib_Orig = OrderChain.activateOrder
function OrderChain.activateOrder()
    if OrderChain.activeOrder == 0 or not OrderChain.running then return end
    local order = OrderChain.chain[OrderChain.activeOrder]
    if moddedOrderChains[order.action] ~= nil then
        OrderChain[moddedOrderChains[order.action].onActivateFunction](order)
        return
    end

    OrderChain_ActivateOrder_CraftOrdersLib_Orig()
end

local OrderChain_UpdateServer_CraftOrdersLib_Orig = OrderChain.updateServer
function OrderChain.updateServer(timeStep)
    OrderChain_UpdateServer_CraftOrdersLib_Orig(timeStep);

    if OrderChain.activeOrder == 0 then return end

    local currentOrder = OrderChain.chain[OrderChain.activeOrder]

    if currentOrder == nil then
        return
    end

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
