-- LootOrder - by Kevin Gravier (MrKMG)

package.path = package.path .. ";data/scripts/lib/?.lua"

include ("stringutility")
include ("refineutility")
include ("utility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AILoot
AILoot = {}

local noLootLeft = false
local noCargoSpace = false
local stuckLoot = {}
local targetLoot = nil
local collectAttemptCounter = 0
local noLootLeftTimer = 0
local wasInited = false

local LootLevels = {
    None = 0,
    Low = 1,
    Medium = 2,
    High = 3,
}

if onServer() then

function AILoot.getUpdateInterval()
    if noLootLeft or noCargoSpace then return 15 end
    return 1
end


function AILoot.updateServer(timeStep)
    if onClient() then 
        print ("updateServer on client")
        terminate() 
    end

    local ship = Entity()

    if ship.hasPilot or ((ship.playerOwned or ship.allianceOwned) and ship:getCrewMembers(CrewProfessionType.Captain) == 0) then
        ShipAI():setPassive()
        terminate()
        return
    end

    AILoot.updateLooting(timeStep)

    wasInited = true

    if noLootLeft == true then
        noLootLeftTimer = noLootLeftTimer - timeStep
    end

end

function AILoot.canContinueLooting()
    -- prevent terminating script before it even started
    if not wasInited then return true end

    return not noLootLeft and not noCargoSpace
end

function AILoot.updateLooting(timeStep)
	local ship = Entity()
    noLootLeft = false

	if (ship.freeCargoSpace < 1 and not noCargoSpace) then
		noCargoSpace = true

        local faction = Faction(ship.factionIndex)
        local x, y = Sector():getCoordinates()
        local coords = tostring(x) .. ":" .. tostring(y)
        if faction then faction:sendChatMessage(ship.name or "", ChatMessageType.Error, "Your ship's cargo bay in sector %s is full."%_T, coords) end

        ShipAI():setPassive()

        local ores, totalOres = getOreAmountsOnShip(ship)
        local scraps, totalScraps = getScrapAmountsOnShip(ship)
        if totalOres + totalScraps == 0 then
            ShipAI():setStatus("Looting - No Cargo Space"%_T, {})
            if faction then faction:sendChatMessage(ship.name or "", ChatMessageType.Normal, "Sir, we can't loot in \\s(%s), we have no space in our cargo bay!"%_T, coords) end
            noCargoSpace = true
        else
            if faction then faction:sendChatMessage(ship.name or "", ChatMessageType.Normal, "Sir, we can't continue loot in \\s(%s), we have no more space left in our cargo bay!"%_T, coords) end
            terminate()
        end
		return
    else
        noCargoSpace = false
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
        local lootName = AILoot.getLootsName(targetLoot);

        ai:setStatus("Looting ${name} /* ship AI status*/"%_T%{name = lootName}, {})
        ai:setFly(targetLoot.translationf, 0)
    else
        ai:setStatus("Looting - No Loot Left /* ship AI status*/"%_T, {})
        if noLootLeft == false or noLootLeftTimer <= 0 then
            noLootLeft = true
            noLootLeftTimer = 10 * 60 -- ten minutes

            local faction = Faction(Entity().factionIndex)
            if faction then
                local x, y = Sector():getCoordinates()
                local coords = tostring(x) .. ":" .. tostring(y)
                faction:sendChatMessage(ship.name or "", ChatMessageType.Error, "Your ship in sector %s can't find any more loot."%_T, coords)
                faction:sendChatMessage(ship.name or "", ChatMessageType.Normal, "Sir, we can't find any more loot in \\s(%s)!"%_T, coords)
            end
        end
    end
end

function AILoot.findLoot()
	local loots = {Sector():getEntitiesByType(EntityType.Loot)}
    local ship = Entity()
    local isBetterLoot = false
    local isEqualLoot = false
    local isCloserLoot = false

    local currentBestDistance = nil
    local currentBestLootLevel = LootLevels.None

    local currentLootLevel = nil
    local currentLootDistance

    targetLoot = nil

    for _, loot in pairs(loots) do
    	if loot:isCollectable(ship) then
            currentLootDistance = distance2(loot.translationf, ship.translationf)
            currentLootLevel = AILoot.getLootsLevel(loot)

            isBetterLoot = currentLootLevel > currentBestLootLevel
            isEqualLoot = currentLootLevel == currentBestLootLevel
            isCloserLoot = currentBestDistance == nil or currentLootDistance < currentBestDistance

            if isBetterLoot or (isEqualLoot and isCloser) then
                targetLoot = loot
                currentBestDistance = currentLootDistance
                currentBestLootLevel = currentLootLevel
            end
		end
    end
end

function AILoot.getLootsType(loot)
    if loot:hasComponent(ComponentType.SystemUpgradeLoot) then
        return ComponentType.SystemUpgradeLoot
    elseif loot:hasComponent(ComponentType.TurretLoot) then
        return ComponentType.TurretLoot
    elseif loot:hasComponent(ComponentType.CargoLoot) then
        return ComponentType.CargoLoot
    elseif loot:hasComponent(ComponentType.MoneyLoot) then
        return ComponentType.MoneyLoot
    elseif loot:hasComponent(ComponentType.ColorLoot) then
        return ComponentType.ColorLoot
    elseif loot:hasComponent(ComponentType.ResourceLoot) then
        return ComponentType.ResourceLoot
    elseif loot:hasComponent(ComponentType.CrewLoot) then
        return ComponentType.CrewLoot
    end
end

function AILoot.getLootsName(loot)
    local lootType = AILoot.getLootsType(loot)
    if lootType == ComponentType.SystemUpgradeLoot then
        return "System Upgrade"
    elseif lootType == ComponentType.TurretLoot then
        return "Turret"
    elseif lootType == ComponentType.CargoLoot then
        return "Cargo"
    elseif lootType == ComponentType.MoneyLoot then
        return "Money"
    elseif lootType == ComponentType.ColorLoot then
        return "Color Sample"
    elseif lootType == ComponentType.ResourceLoot then
        return "Resource"
    elseif lootType == ComponentType.CrewLoot then
        return "Crew"
    end
end

function AILoot.getLootsLevel(loot)
    local lootType = AILoot.getLootsType(loot)
    if lootType == ComponentType.SystemUpgradeLoot then
        return LootLevels.High
    elseif lootType == ComponentType.TurretLoot then
        return LootLevels.High
    elseif lootType == ComponentType.CargoLoot then
        return LootLevels.Low
    elseif lootType == ComponentType.MoneyLoot then
        return LootLevels.Medium
    elseif lootType == ComponentType.ColorLoot then
        return LootLevels.Medium
    elseif lootType == ComponentType.ResourceLoot then
        return LootLevels.Low
    elseif lootType == ComponentType.CrewLoot then
        return LootLevels.Low
    end
end

end