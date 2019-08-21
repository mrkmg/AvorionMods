-- LootOrder - by Kevin Gravier (MrKMG)

package.path = package.path .. ";data/scripts/lib/?.lua"

include ("stringutility")
include ("refineutility")
include ("utility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AILoot
AILoot = {}

local LootLevels = {
    None = 0,
    Low = 1,
    Medium = 2,
    High = 3,
}

local LootComponentLevels = {}
LootComponentLevels[ComponentType.SystemUpgradeLoot] = LootLevels.High
LootComponentLevels[ComponentType.TurretLoot] = LootLevels.High
LootComponentLevels[ComponentType.MoneyLoot] = LootLevels.Medium
LootComponentLevels[ComponentType.ColorLoot] = LootLevels.Medium
LootComponentLevels[ComponentType.CargoLoot] = LootLevels.Low
LootComponentLevels[ComponentType.ResourceLoot] = LootLevels.Low
LootComponentLevels[ComponentType.CrewLoot] = LootLevels.Low

local LootComponentNames = {}
LootComponentNames[ComponentType.SystemUpgradeLoot] = "System"
LootComponentNames[ComponentType.TurretLoot] = "Turret"
LootComponentNames[ComponentType.MoneyLoot] = "Credits"
LootComponentNames[ComponentType.ColorLoot] = "Color"
LootComponentNames[ComponentType.CargoLoot] = "Cargo"
LootComponentNames[ComponentType.ResourceLoot] = "Resource"
LootComponentNames[ComponentType.CrewLoot] = "Crew"

local LootComponentNeedsCargo = {}
LootComponentNeedsCargo[ComponentType.SystemUpgradeLoot] = false
LootComponentNeedsCargo[ComponentType.TurretLoot] = false
LootComponentNeedsCargo[ComponentType.MoneyLoot] = false
LootComponentNeedsCargo[ComponentType.ColorLoot] = false
LootComponentNeedsCargo[ComponentType.CargoLoot] = true
LootComponentNeedsCargo[ComponentType.ResourceLoot] = true
LootComponentNeedsCargo[ComponentType.CrewLoot] = false

local isLootLeft = false
local hasCargoSpace = false
local stuckLoot = {}
local targetLoot
local noLootLeftTimer = 0
local wasInited = false

function AILoot.canContinueLooting()
    -- prevent terminating script before it even started
    if not wasInited then return true end

    return isLootLeft
end

function AILoot.getCurrentLootTarget()
    return targetLoot
end
callable(AILoot, "getCurrentLootTarget")

function AILoot.getUpdateInterval()
    if wasInited and not isLootLeft then return 15 end
    return 1
end

function AILoot.hasCaptain()
    local ship = Entity()

    if ship.hasPilot or ((ship.playerOwned or ship.allianceOwned) and ship:getCrewMembers(CrewProfessionType.Captain) == 0) then
        return false
    end

    return true
end

function AILoot.updateServer(timeStep)
    if not AILoot.hasCaptain() then
        ShipAI():setPassive()
        terminate()
        return
    end

    AILoot.checkCargo()
    AILoot.checkLoot()

    if valid(targetLoot) then
        AILoot.approachLoot()
    else
        AILoot.announceNoLootLeft(timeStep)
    end

    wasInited = true
end

function AILoot.approachLoot()
    local lootName = AILoot.getLootName(AILoot.getLootType(targetLoot));
    ShipAI():setStatus("Looting ${name} /* ship AI status*/"%_T%{name = lootName}, {})
    ShipAI():setFly(targetLoot.translationf, 0)
end

function AILoot.announceNoLootLeft(timeStep)
    ShipAI():setStatus("Looting - No Loot Left /* ship AI status*/"%_T, {})
    if isLootLeft or noLootLeftTimer <= 0 then
        isLootLeft = false
        noLootLeftTimer = 10 * 60 -- ten minutes
        local faction = Faction(Entity().factionIndex)
        if faction then
            local x, y = Sector():getCoordinates()
            local coords = tostring(x) .. ":" .. tostring(y)
            local shipName = Entity().name or ""
            local errorMessage = "Your ship in sector %s can't find any more collectable loot."%_T
            local chatMessage = "Sir, we can't find any more collectable loot in \\s(%s)!"%_T
            faction:sendChatMessage(shipName, ChatMessageType.Error, errorMessage, coords)
            faction:sendChatMessage(shipName, ChatMessageType.Normal, chatMessage, coords)
        end
    else
        noLootLeftTimer = noLootLeftTimer + timeStep
    end
end

function AILoot.checkCargo()
    if (Entity().freeCargoSpace < 1 and hasCargoSpace) then
        hasCargoSpace = false
    else
        hasCargoSpace = true
    end
end

function AILoot.checkLoot()
    if valid(targetLoot) and ShipAI().isStuck then
        stuckLoot[targetLoot.index.string] = true
        targetLoot = nil
    end

    if not valid(targetLoot) then
        AILoot.findLoot()
    end

    if valid(targetLoot) then
        isLootLeft = true
    end
end

function AILoot.findLoot(skipMyTeam)
    if skipMyTeam == nil then skipMyTeam = false end

    local loots = {Sector():getEntitiesByType(EntityType.Loot)}
    local ship = Entity()

    local currentBestDistance
    local currentBestLootLevel = LootLevels.None

    local currentLootLevel
    local currentLootDistance
    local currentLootNeedsCargoSpace
    local currentLootType

    local didSkipForMyTeam = false
    targetLoot = nil

    local teamsLoots
    if skipMyTeam then
        teamsLoots = {}
    else
        teamsLoots = AILoot.getTeamsLoots()
    end


    for _, loot in pairs(loots) do
        if loot:isCollectable(ship) then
            currentLootType = AILoot.getLootType(loot)

            if stuckLoot[loot.index.string] == true then
                goto findLootContinue
            end

            currentLootNeedsCargoSpace = AILoot.getLootNeedsCargoSpace(currentLootType)
            if currentLootNeedsCargoSpace and not hasCargoSpace then
                goto findLootContinue
            end

            currentLootLevel = AILoot.getLootLevel(currentLootType)
            if currentLootLevel < currentBestLootLevel then
                goto findLootContinue
            end

            currentLootDistance = distance(loot.translationf, ship.translationf)
            if currentLootLevel == currentBestLootLevel and (currentLootDistance == nil or currentLootDistance > currentBestDistance) then
                goto findLootContinue
            end

            if not skipMyTeam and AILoot.isLootCloseTo(teamsLoots, loot) then
                didSkipForMyTeam = true
                goto findLootContinue
            end

            -- Is better loot, or equal and closer, fits on ship, and (if checked) not being collected by a teammate
            targetLoot = loot
            currentBestDistance = currentLootDistance
            currentBestLootLevel = currentLootLevel

            ::findLootContinue::
        end
    end

    if not valid(targetLoot) and didSkipForMyTeam then
        AILoot.findLoot(true)
    end
end

function AILoot.isLootCloseTo(lootList, lootToCheck)
    local calculatedDistance 
    for _,loot in pairs(lootList) do
        if valid(loot) and valid(lootToCheck) then
            calculatedDistance = distance(loot.translationf, lootToCheck.translationf)

            if calculatedDistance < 500 then
                return true
            end
        end
    end
    return false
end

function AILoot.getLootType(loot)
    local lootType

    if loot:hasComponent(ComponentType.SystemUpgradeLoot) then
        lootType = ComponentType.SystemUpgradeLoot
    elseif loot:hasComponent(ComponentType.TurretLoot) then
        lootType = ComponentType.TurretLoot
    elseif loot:hasComponent(ComponentType.CargoLoot) then
        lootType = ComponentType.CargoLoot
    elseif loot:hasComponent(ComponentType.MoneyLoot) then
        lootType = ComponentType.MoneyLoot
    elseif loot:hasComponent(ComponentType.ColorLoot) then
        lootType = ComponentType.ColorLoot
    elseif loot:hasComponent(ComponentType.ResourceLoot) then
        lootType = ComponentType.ResourceLoot
    elseif loot:hasComponent(ComponentType.CrewLoot) then
        lootType = ComponentType.CrewLoot
    end

    return lootType
end

function AILoot.getLootName(lootType)
    if lootType == nil then return "Loot" end

    if LootComponentNames[lootType] ~= nil then
        return LootComponentNames[lootType]
    else
        return "Loot"
    end
end

function AILoot.getLootLevel(lootType)
    if lootType == nil then return LootLevels.Low end

    if LootComponentLevels[lootType] ~= nil then
        return LootComponentLevels[lootType]
    else
        return LootLevels.Low
    end
end

function AILoot.getLootNeedsCargoSpace(lootType)
    if lootType == nil then return true end

    if LootComponentNeedsCargo[lootType] ~= nil then
        return LootComponentNeedsCargo[lootType]
    else
        return true
    end
end

function AILoot.getTeamsLoots()
    local teamsLoots = {}
    local teamsLootsNum = 1

    local myShip = Entity()
    local ships = {Sector():getEntitiesByType(EntityType.Ship)}

    for _,ship in pairs(ships) do
        if (ship.playerOwned or ship.allianceOwned) and myShip.factionIndex == ship.factionIndex then
            for _, name in pairs(ship:getScripts()) do
                --Fix for path issues on windows
                local fixedName = string.gsub(name, "\\", "/")
                if string.match(fixedName, "data/scripts/entity/ai/loot.lua") then
                    local ret, result = ship:invokeFunction("data/scripts/entity/ai/loot.lua", "getCurrentLootTarget")

                    if ret == 0 and result ~= nil and valid(result) then 
                        teamsLoots[teamsLootsNum] = result
                        teamsLootsNum = teamsLootsNum + 1
                    end
                end
            end

        end
    end

    return teamsLoots
end
