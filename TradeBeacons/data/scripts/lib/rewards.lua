-- TradeBeacons
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

local UtilityGenerator = include ("utilitygenerator")

local Reward_standard__orig_TradeBeacons = Rewards.standard

function Rewards.standard(player, faction, msg, money, reputation, turret, system)
    if system and random():getFloat() < 0.125 then
        UtilityGenerator.initialize(random():createSeed())
        object = UtilityGenerator.generateUtility(Rarity(RarityType.Uncommon))

        if object then player:getInventory():add(object) end
    else
        Reward_standard__orig_TradeBeacons(player, faction, msg, money, reputation, turret, system)
    end
end
