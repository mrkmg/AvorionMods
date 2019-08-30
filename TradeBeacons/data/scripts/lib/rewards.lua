local UtilityGenerator = include ("utilitygenerator")

function Rewards.standard(player, faction, msg, money, reputation, turret, system)

    msg = msg or messages1[random():getInt(1, #messages1)] .. " " .. messages2[random():getInt(1, #messages2)]

    -- give payment to players who participated
    player:sendChatMessage(faction.name, 0, msg)
    player:receive("Received a reward of %1% credits."%_T, money)
    Galaxy():changeFactionRelations(player, faction, reputation)

    local x, y = Sector():getCoordinates()
    local object

    if system and random():getFloat() < 0.5 then
        if random():getFloat() < 0.75 then
            UpgradeGenerator.initialize(random():createSeed())
            object = UpgradeGenerator.generateSystem(Rarity(RarityType.Uncommon))
        else
            UtilityGenerator.initialize(random():createSeed())
            object = UtilityGenerator.generateUtility(Rarity(RarityType.Uncommon))
        end
    elseif turret then
        object = InventoryTurret(TurretGenerator.generate(Sector():getCoordinates()))
    end

    if object then player:getInventory():add(object) end

end
