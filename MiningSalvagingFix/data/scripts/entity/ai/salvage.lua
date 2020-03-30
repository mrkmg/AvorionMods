-- MiningSalvagingFix
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

function AISalvage.canContinueSalvaging()
    -- prevent terminating script before it even started
    if not salvagingMaterial then return true end

    return minedLoot ~= nil or minedWreckage ~= nil
end