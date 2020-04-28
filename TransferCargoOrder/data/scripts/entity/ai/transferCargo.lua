-- TransferCargoOrder
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

package.path = package.path .. ";data/scripts/lib/?.lua"

include("stringutility")
include("refineutility")
include("utility")

--namespace TransferCargo
TransferCargo = {}

local targetEntity
local didInit = false
local States = {
    Init = 1,
    Flying = 2,
    Closing = 3,
    Transferring = 4,
    Stuck = 5,
    Finished = 6,
}
local state = States.Init

function TransferCargo.initialize(targetIndex)
    if targetIndex == nil then return end
    targetEntity = Entity(targetIndex)
    didInit = true

    TransferCargo.updateServer()
end

function TransferCargo.getUpdateInterval()
    return 5
end

function TransferCargo.announceError(chatMessage, alertMessage)
    local faction = Faction(Entity().factionIndex)
    if faction then
        local x, y = Sector():getCoordinates()
        local coords = tostring(x) .. ":" .. tostring(y)
        local shipName = Entity().name or ""
        faction:sendChatMessage(shipName, ChatMessageType.Error, alertMessage, coords)
        faction:sendChatMessage(shipName, ChatMessageType.Normal, chatMessage, coords)
    end
end

function TransferCargo.hasCaptain()
    local ship = Entity()

    if ship.hasPilot or ((ship.playerOwned or ship.allianceOwned) and ship:getCrewMembers(CrewProfessionType.Captain) == 0) then
        return false
    end

    return true
end

local stuckCounter = 0
function TransferCargo.setState()
    if state == States.Finished then
        terminiate()
        return
    end

    local ai = ShipAI();

    if ai.isStuck then
        stuckCounter = stuckCounter + 1
        if stuckCounter >= 3 then
            state = States.Stuck
        end
    else
        stuckCounter = 0
        local dist = Entity():getNearestDistance(targetEntity)
        if dist < 50 then
            state = States.Transferring
            return
        elseif dist < 200 then
            state = States.Closing
        else
            state = States.Flying
        end
    end
end

function TransferCargo.run()
    local ai = ShipAI()
    local entity = Entity()

    if state == States.Flying then
        ai:setStatus("Flying to ${name} /* ship AI status*/" % _T % { name = targetEntity.name }, {})
        ai:setFly(targetEntity.translationf, 0)
    end

    if state == States.Closing then
        ai:setStatus("Closing distance to ${name} /* ship AI status*/" % _T % { name = targetEntity.name }, {})
        local targetPos = (entity.translationf + targetEntity.translationf) / 2
        ai:setFlyLinear(targetPos, 0, false)
    end

    if state == States.Transferring then
        ai:setStatus("Transferring Cargo to ${name} /* ship AI status*/" % _T % { name = targetEntity.name }, {})
        ai:setPassive()

        local cargos = entity:getCargos()

        for good, count in pairs(cargos) do
            local transferVolume = math.min(count * good.size, targetEntity.freeCargoSpace)
            local transferAmount = math.floor(transferVolume / good.size)
            if transferAmount < 1 then
                return
            end

            targetEntity:addCargo(good, transferAmount)
            entity:removeCargo(good, transferAmount)
        end
        state = States.Finished
        terminate()
    end
end

function TransferCargo.checkQuitConditions()
    local ai = ShipAI()

    if not TransferCargo.hasCaptain() then
        ai:setPassive()
        return true
    end

    if not valid(targetEntity) then
        TransferCargo.announceError("Sir, we can not find the target craft in %s" % _T, "Your craft in %s can not find their target to transfer their cargo" % _T)
        ai:setStatus("Idle", {})
        ai:setPassive()
        return true
    end

    local entity = Entity()

    if entity.maxCargoSpace - entity.freeCargoSpace < 1 then
        ai:setStatus("Idle", {})
        ai:setPassive()
        return true
    end

    if targetEntity.freeCargoSpace < 1 then
        TransferCargo.announceError("Sir, there is no free space on the target in %s" % _T, "No cargo space to transfer to in %s." % _T)
        ai:setStatus("Idle", {})
        ai:setPassive()
        return true
    end

    if state == States.Stuck then
        TransferCargo.announceError("Sir, we can not reach the target in %s" % _T, "Your craft in %s can not reach their target" % _T)
        ai:setStatus("Idle", {})
        ai:setPassive()
        return true
    end

    if state == States.Finished then
        return true
    end

    return false
end

function TransferCargo.updateServer(timeStep)
    if didInit == false then return end

    if TransferCargo.checkQuitConditions() then
        terminate()
        return
    end

    TransferCargo.setState()
    TransferCargo.run()
end









