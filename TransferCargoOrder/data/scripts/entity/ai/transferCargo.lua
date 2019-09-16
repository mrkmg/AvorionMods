-- TransferCargoOrder
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

package.path = package.path .. ";data/scripts/lib/?.lua"

include ("stringutility")
include ("refineutility")
include ("utility")

--namespace TransferCargo
TransferCargo = {}

local targetEntity
local didInit = false

function TransferCargo.initialize(targetIndex)
    if targetIndex == nil then return end
    targetEntity = Entity(targetIndex)
    didInit = true
    
    if not valid(targetEntity) then
      terminate()
    end
end

function TransferCargo.getUpdateInterval()
    return 1
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

function TransferCargo.updateServer(timeStep)
    if didInit == false then return end
    
    print ("TCAI.updateServer", targetEntity)
    
    if not TransferCargo.hasCaptain() then
        ShipAI():setPassive()
        terminate()
        return
    end

    if not valid(targetEntity) then
      TransferCargo.announceError("Sir, we can not find the target craft in %s"%_T, "Your craft in %s can not find their target to transfer their cargo"%_T)
        ShipAI():setPassive()
        terminate()
      return
    end
    
    local entity = Entity()
    
    if entity.maxCargoSpace - entity.freeCargoSpace < 1 then
      ShipAI():setStatus("Idle", {})
      ShipAI():setPassive()
      terminate()
    end
    
    if targetEntity.freeCargoSpace < 1 then
      TransferCargo.announceError("Sir, there is no free space on the target in %s"%_T, "Your craft in %s can not transfer their cargo because our target has no cargo space left"%_T)
      ShipAI():setStatus("Idle", {})
      ShipAI():setPassive()
      terminate()
      return
    end
    
    if entity:getNearestDistance(targetEntity) > 40 then
      ShipAI():setStatus("Flying to ${name} /* ship AI status*/"%_T%{name = targetEntity.name}, {})
      ShipAI():setFly(targetEntity.translationf, 0)
      return 
    end
    
    ShipAI():setStatus("Transferring Cargo to ${name} /* ship AI status*/"%_T%{name = targetEntity.name}, {})
    ShipAI():setPassive()
    
    local cargos = entity:getCargos()
    
    for good,count in pairs(cargos) do
      print (good.name, count)
      local transferVolume = math.min(count * good.size, targetEntity.freeCargoSpace)
      local transferAmount = math.floor(transferVolume / good.size)
      if transferAmount < 1 then
        return
      end
      
      targetEntity:addCargo(good, transferAmount)
      entity:removeCargo(good, transferAmount)
    end
end









