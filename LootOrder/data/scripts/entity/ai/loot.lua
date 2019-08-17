-- LootOrder - by Kevin Gravier (MrKMG)

package.path = package.path .. ";data/scripts/lib/?.lua"

include ("stringutility")
include ("refineutility")

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

if onServer() then

print ("AILoot Init")

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

	if valid(targetLoot) and ai.isStuck then
    	stuckLoot[targetLoot.index.string] = true
    	AILoot.findLoot()
    end    

    if valid(targetLoot) then
        ai:setStatus("Collecting Loot /* ship AI status*/"%_T, {})
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
    local currentTargetDistance = nil
    local lootDistance

    targetLoot = nil

    for _, loot in pairs(loots) do
    	lootDistance = distance2(loot.translationf, ship.translationf)
    	if loot:isCollectable(ship) then
    		if stuckLoot[loot.index.string] ~= true then
    			if currentTargetDistance == nil or lootDistance < currentTargetDistance then
    				targetLoot = loot
    				lootDistance = currentTargetDistance
				end
			end
		end
    end
end

end