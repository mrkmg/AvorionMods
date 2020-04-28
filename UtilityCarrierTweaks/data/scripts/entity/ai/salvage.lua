function AISalvage.updateSalvaging(timeStep)
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
                    ShipAI():setStatus("Salvaging - No Cargo Space"%_T, {})
                    if faction then faction:sendChatMessage(ship.name or "", ChatMessageType.Normal, "Commander, we can't salvage in \\s(%s) - we have no space in our cargo bay!"%_T, coords) end
                    noCargoSpace = true
                else
                    local ret, moreOrders = ship:invokeFunction("data/scripts/entity/orderchain.lua", "hasMoreOrders")
                    if ret == 0 and moreOrders == true then
                        -- salvage order fulfilled, another order is queued
                        -- don't send a message
                        terminate()
                        return
                    end

                    -- salvage order fulfilled, no other order is queued
                    if faction then faction:sendChatMessage(ship.name or "", ChatMessageType.Normal, "Commander, we can't continue salvaging in \\s(%s) - we have no more space left in our cargo bay!"%_T, coords) end
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
    if not valid(minedWreckage) and not valid(minedLoot) then

        -- first, check if there is loot to collect
        AISalvage.findMinedLoot()

        -- then, if there's no loot, check if there is a wreckage to mine
        if not valid(minedLoot) then
            AISalvage.findMinedWreckage()
        end

    end

    local ai = ShipAI()

    if valid(minedLoot) then
        ai:setStatus("Collecting Salvaged Loot /* ship AI status*/"%_T, {})

        -- there is loot to collect, fly there
        collectCounter = collectCounter + timeStep
        if collectCounter > 3 then
            collectCounter = collectCounter - 3

            if ai.isStuck then
                stuckLoot[minedLoot.index.string] = true
                AISalvage.findMinedLoot()
                collectCounter = collectCounter + 2
            end

            if valid(minedLoot) then
                ai:setFly(minedLoot.translationf, 0)
            end
        end

    elseif valid(minedWreckage) then
        ai:setStatus("Salvaging /* ship AI status*/"%_T, {})

        local distanceToAsteroid = distance(ship.position.pos, minedWreckage.position.pos)

        if distanceToAsteroid > 500 then
            if AISalvage.UCT_areFightersDeployed() then
                ai:setPassive()
            else
                ai:setFly(minedWreckage.position.pos, 0)
            end
        else
            ai:setHarvest(minedWreckage)
            stuckLoot = {}
        end
    else
        ai:setStatus("Salvaging - No Wreckages Left /* ship AI status*/"%_T, {})
    end

end

function AISalvage.UCT_areFightersDeployed()
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