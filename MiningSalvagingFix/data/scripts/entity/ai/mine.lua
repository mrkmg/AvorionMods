-- MiningSalvagingFix
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

function AIMine.canContinueMining()
    -- prevent terminating script before it even started
    if not miningMaterial then return true end

    return minedLoot ~= nil or minedAsteroid ~= nil
end