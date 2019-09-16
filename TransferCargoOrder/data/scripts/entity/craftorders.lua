-- TransferCargoOrder
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

function CraftOrders.transferCargo(factionIndex, craftName)
    if onClient() then
        invokeServerFunction("transferCargo", factionIndex, craftName)
        ScriptUI():stopInteraction()
        return
    end

    if checkCaptain() then
      local entity = Entity()

      for index, name in pairs(entity:getScripts()) do
        local fixedName = string.gsub(name, "\\", "/")
        if string.match(fixedName, "data/scripts/entity/ai/") then
            entity:removeScript(index)
        end
      end
      
      Entity():addScript("ai/transferCargo.lua", factionIndex, craftName)
    end  
end
callable(CraftOrders, "transferCargo")