local UtilityGenerator = include ("utilitygenerator")

function receiveUtility(faction)

    local rarity = Rarity(RarityType.Uncommon)

    if random():getFloat() < 0.3 then
        rarity = Rarity(RarityType.Exceptional)
    elseif random():getFloat() < 0.7 then
        rarity = Rarity(RarityType.Rare)
    end

    local x, y = Sector():getCoordinates()

    UtilityGenerator.initialize(random():createSeed())
    local utility = UpgradeGenerator.generateUtility(rarity)
    faction:getInventory():add(utility)
end

function claim()

    local receiver, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.AddItems, AlliancePrivilege.AddResources)
    if not receiver then return end

    local dist = ship:getNearestDistance(Entity())
    if dist > 20.0 then
        player:sendChatMessage("", ChatMessageType.Error, "You're not close enough to open the object."%_t)
        return
    end

    terminate()

    receiveMoney(receiver)

    if random():getFloat() < 0.5 then
        receiveTurret(receiver)
    else
        receiveUpgrade(receiver)
    end

    if random():getFloat() < 0.5 then
        if random():getFloat() < 0.5 then
            receiveTurret(receiver)
        else
            receiveUpgrade(receiver)
        end
    end

    if random():getFloat() < 0.5 then
        receiveUtility(receiver)
    end

    if random():getFloat() < 0.05 then
        receiver:getInventory():add(UsableInventoryItem("unbrandedreconstructiontoken.lua", Rarity(RarityType.Legendary)))
    end
end
callable(nil, "claim")
