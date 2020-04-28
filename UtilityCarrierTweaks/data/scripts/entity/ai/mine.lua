function AIMine.updateMining(timeStep)
    local ship = Entity()

    if hasRawLasers == true then
        if ship.freeCargoSpace < 1 then
            if noCargoSpace == false then
                ShipAI():setPassive()

                local faction = Faction(ship.factionIndex)
                local x, y = Sector():getCoordinates()
                local coords = tostring(x) .. ":" .. tostring(y)

                local ores, totalOres = getOreAmountsOnShip(ship)
                local scraps, totalScraps = getScrapAmountsOnShip(ship)
                if totalOres + totalScraps == 0 then
                    ShipAI():setStatus("Mining - No Cargo Space"%_T, {})
                    if faction then faction:sendChatMessage(ship.name or "", ChatMessageType.Normal, "Commander, we can't mine in \\s(%s) - we have no space in our cargo bay!"%_T, coords) end
                    noCargoSpace = true
                else
                    local ret, moreOrders = ship:invokeFunction("data/scripts/entity/orderchain.lua", "hasMoreOrders")
                    if ret == 0 and moreOrders == true then
                        -- mine order fulfilled, another order is queued
                        -- don't send a message
                        terminate()
                        return
                    end

                    -- mine order fulfilled, no other order is queued
                    if faction then faction:sendChatMessage(ship.name or "", ChatMessageType.Normal, "Commander, we can't continue mining in \\s(%s) - we have no more space left in our cargo bay!"%_T, coords) end
                    terminate()
                end

                if faction then faction:sendChatMessage(ship.name or "", ChatMessageType.Error, "Your ship's cargo bay in sector %s is full."%_T, coords) end
            end

            return
        else
            noCargoSpace = false
        end
    end

    -- highest priority is collecting the resources
    if not valid(minedAsteroid) and not valid(minedLoot) then

        -- first, check if there is loot to collect
        AIMine.findMinedLoot()

        -- then, if there's no loot, check if there is an asteroid to mine
        if not valid(minedLoot) then
            AIMine.findMinedAsteroid()
        end

    end

    local ai = ShipAI()

    if valid(minedLoot) then
        ai:setStatus("Collecting Mined Loot /* ship AI status*/"%_T, {})

        -- there is loot to collect, fly there
        collectCounter = collectCounter + timeStep
        if collectCounter > 3 then
            collectCounter = collectCounter - 3

            if ai.isStuck then
                stuckLoot[minedLoot.index.string] = true
                AIMine.findMinedLoot()
                collectCounter = collectCounter + 2
            end

            if valid(minedLoot) then                
                ai:setFly(minedLoot.translationf, 0)
            end
        end

    elseif valid(minedAsteroid) then
        ai:setStatus("Mining /* ship AI status*/"%_T, {})

        -- if there is an asteroid to collect, harvest it
        if ship.selectedObject == nil
            or ship.selectedObject.index ~= minedAsteroid.index
            or ai.state ~= AIState.Harvest then

            local distanceToAsteroid = distance(ship.position.pos, minedAsteroid.position.pos)

            if distanceToAsteroid > 500 then
                if AIMine.UCT_areFightersDeployed() then
                    ai:setPassive()
                else
                    ai:setFly(minedAsteroid.position.pos, 0)
                end
            else
                ai:setHarvest(minedAsteroid)
                stuckLoot = {}
            end
        end
    else
--        print("no asteroids")
        ai:setStatus("Mining - No Asteroids Left /* ship AI status*/"%_T, {})
    end

end

function AIMine.UCT_areFightersDeployed()
    local fc = FighterController(Entity().index)
    local hangar = Hangar()
    local squads = {hangar:getSquads()}

    for _, index in pairs(squads) do
        local fighters = {fc:getDeployedFighters(index)}
        if #fighters > 0 then 
            return true
        end
    end

    return false
end