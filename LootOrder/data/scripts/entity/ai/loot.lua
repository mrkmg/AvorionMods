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

if onServer() then

function AILoot.getUpdateInterval()
    if not isLootLeft then return 15 end
    return 1
end


function AILoot.updateServer(timeStep)
    local ship = Entity()

    if ship.hasPilot or ((ship.playerOwned or ship.allianceOwned) and ship:getCrewMembers(CrewProfessionType.Captain) == 0) then
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

function AILoot.canContinueLooting()
    -- prevent terminating script before it even started
    if not wasInited then return true end

    return isLootLeft
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

function AILoot.findLoot()
	local loots = {Sector():getEntitiesByType(EntityType.Loot)}
    local ship = Entity()
    local isBetterLoot = false
    local isEqualLoot = false
    local isCloserLoot = false
    local fitsOnShip = false

    local currentBestDistance = nil
    local currentBestLootLevel = LootLevels.None

    local currentLootLevel = nil
    local currentLootDistance

    local currentLootNeedsCargoSpace = true
    local currentLootType = nil

    targetLoot = nil

    for _, loot in pairs(loots) do
    	if loot:isCollectable(ship) then
            currentLootDistance = distance2(loot.translationf, ship.translationf)
            currentLootType = AILoot.getLootType(loot)
            currentLootNeedsCargoSpace = AILoot.getLootNeedsCargoSpace(currentLootType)
            currentLootLevel = AILoot.getLootLevel(currentLootType)

            fitsOnShip = currentLootNeedsCargoSpace == false or hasCargoSpace
            isBetterLoot = currentLootLevel > currentBestLootLevel
            isEqualLoot = currentLootLevel == currentBestLootLevel
            isCloserLoot = currentBestDistance == nil or currentLootDistance < currentBestDistance

            if fitsOnShip and (isBetterLoot or (isEqualLoot and isCloser)) then
                targetLoot = loot
                currentBestDistance = currentLootDistance
                currentBestLootLevel = currentLootLevel
            end
		end
    end
end

function AILoot.getLootType(loot)
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
    else
        return nil
    end
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

end