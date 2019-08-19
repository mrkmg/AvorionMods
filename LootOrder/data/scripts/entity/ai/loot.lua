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
LootComponentLevels[ComponentType.SystemUpgradeLoot] = "System"
LootComponentLevels[ComponentType.TurretLoot] = "Turret"
LootComponentLevels[ComponentType.MoneyLoot] = "Credits"
LootComponentLevels[ComponentType.ColorLoot] = "Color"
LootComponentLevels[ComponentType.CargoLoot] = "Cargo"
LootComponentLevels[ComponentType.ResourceLoot] = "Resource"
LootComponentLevels[ComponentType.CrewLoot] = "Crew"

local LootComponentNeedsCargo = {}
LootComponentLevels[ComponentType.SystemUpgradeLoot] = false
LootComponentLevels[ComponentType.TurretLoot] = false
LootComponentLevels[ComponentType.MoneyLoot] = false
LootComponentLevels[ComponentType.ColorLoot] = false
LootComponentLevels[ComponentType.CargoLoot] = true
LootComponentLevels[ComponentType.ResourceLoot] = true
LootComponentLevels[ComponentType.CrewLoot] = false

local isLootLeft = false
local hasCargoSpace = false
local stuckLoot = {}
local targetLoot = nil
local collectAttemptCounter = 0
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
    if not isLootLeft then return 15 end
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

    AILoot.updateLooting(timeStep)

    wasInited = true

    if not isLootLeft then
        noLootLeftTimer = noLootLeftTimer - timeStep
    end

end

function AILoot.updateLooting(timeStep)
    local ship = Entity()
    isLootLeft = true

    if (ship.freeCargoSpace < 1 and hasCargoSpace) then
        hasCargoSpace = false
    else
        hasCargoSpace = true
    end

    if not valid(targetLoot) then
        AILoot.findLoot()
    end

    local ai = ShipAI()

    if valid(targetLoot) then
        collectAttemptCounter = collectAttemptCounter + timeStep

        if collectAttemptCounter > 3 then
            collectAttemptCounter = collectAttemptCounter - 3
            if ai.isStuck then
                stuckLoot[targetLoot.index.string] = true
                AILoot.findLoot()
            end
        end
    end

    if valid(targetLoot) then
        local lootName = AILoot.getLootName(AILoot.getLootType(targetLoot));

        ai:setStatus("Looting ${name} /* ship AI status*/"%_T%{name = lootName}, {})
        ai:setFly(targetLoot.translationf, 0)
    else
        ai:setStatus("Looting - No Loot Left /* ship AI status*/"%_T, {})
        if isLootLeft or noLootLeftTimer <= 0 then
            isLootLeft = false
            noLootLeftTimer = 10 * 60 -- ten minutes

            local faction = Faction(Entity().factionIndex)
            if faction then
                local x, y = Sector():getCoordinates()
                local coords = tostring(x) .. ":" .. tostring(y)
                faction:sendChatMessage(ship.name or "", ChatMessageType.Error, "Your ship in sector %s can't find any more collectable loot."%_T, coords)
                faction:sendChatMessage(ship.name or "", ChatMessageType.Normal, "Sir, we can't find any more collectable loot in \\s(%s)!"%_T, coords)
            end
        end
    end
end

function AILoot.findLoot(skipMyTeam)
    if skipMyTeam == nil then skipMyTeam = false end

    local loots = {Sector():getEntitiesByType(EntityType.Loot)}
    local ship = Entity()
    local isBetterLoot = false
    local isEqualLoot = false
    local isCloserLoot = false
    local fitsOnShip = false
    local isTooCloseToTeammate = false
    local isStuck = false

    local currentBestDistance = nil
    local currentBestLootLevel = LootLevels.None

    local currentLootLevel = nil
    local currentLootDistance

    local currentLootNeedsCargoSpace = true
    local currentLootType = nil

    local didSkipForMyTeam = false

    targetLoot = nil

    local teamsLoots

    if skipMyTeam then
        teamsLoots = {}
    else
         teamLoots = AILoot.getTeamsLoots()
     end

    for _, loot in pairs(loots) do
        if loot:isCollectable(ship) then
            currentLootType = AILoot.getLootType(loot)

            currentLootNeedsCargoSpace = AILoot.getLootNeedsCargoSpace(currentLootType)
            if currentLootNeedsCargoSpace and not hasCargoSpace then
                goto continue
            end

            currentLootLevel = AILoot.getLootLevel(currentLootType)
            if currentLootLevel < currentBestLootLevel then
                goto continue
            end

            currentLootDistance = distance(loot.translationf, ship.translationf)
            if currentLootLevel == currentBestLootLevel and currentLootDistance > currentBestDistance then
                goto continue
            end

            if not skipMyTeam and AILoot.isLootCloseTo(teamLoots, loot) then
                didSkipForMyTeam = true
                goto continue
            end

            -- Is better loot, or equal and closer, fits on ship, and (if checked) not being collected by a teammate
            targetLoot = loot
            currentBestDistance = currentLootDistance
            currentBestLootLevel = currentLootLevel

            ::continue::
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
            calculatedDistance = distance(loot.translationf, lootToCheck, translationf)

            if calculatedDistance < 500 then
                return true
            end
        end
    end
    return false
end

function AILoot.getLootType(loot)
    local lootType = nil

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
    if lootType = nil then return "Loot" end

    if LootComponentNames[lootType] ~= nil then
        return LootComponentNames[lootType]
    else
        return "Loot"
    end
end

function AILoot.getLootLevel(lootType)
    if lootType = nil then return LootLevels.Low end

    if LootComponentLevels[lootType] ~= nil then
        return LootComponentLevels[lootType]
    else
        return LootLevels.Low
    end
end

function AILoot.getLootNeedsCargoSpace(lootType)
    if lootType = nil then return true end

    if LootComponentLevels[lootType] ~= nil then
        return LootComponentLevels[lootType]
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
            for index, name in pairs(ship:getScripts()) do
                --Fix for path issues on windows
                local fixedName = string.gsub(name, "\\", "/")
                if string.match(fixedName, "data/scripts/entity/ai/loot.lua") then
                    local ret, result = ship:invokeFunction("data/scripts/entity/ai/loot.lua", "getCurrentLootTarget")
                    if ret == 0 and valid(result) then 
                        teamsLoots[teamsLootsNum] = result
                        teamsLootsNum = teamsLootsNum + 1
                    end
                end
            end

        end
    end

    return teamsLoots
end