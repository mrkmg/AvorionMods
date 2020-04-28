MapCommands.registerModdedMapCommand("OCN_gotoNextCommand", {
    tooltip = "Goto Next",
    icon = "data/textures/icons/flatarrowdown.png",
    callback = "OCN_gotoNextCommand",
    shouldHideCallback = "OCN_hideGotoNextCommand"
})

MapCommands.registerModdedMapCommand("OCN_gotoPrevCommand", {
    tooltip = "Goto Previous",
    icon = "data/textures/icons/flatarrowup.png",
    callback = "OCN_gotoPrevCommand",
    shouldHideCallback = "OCN_hideGotoPrevCommand"
})

function MapCommands.OCN_gotoPrevCommand()
    MapCommands.enqueueOrder("OCN_gotoPrev")
end

function MapCommands.OCN_gotoNextCommand()
    MapCommands.enqueueOrder("OCN_gotoNext")
end

function MapCommands.OCN_hideGotoNextCommand()
    for _, portrait in pairs(craftPortraits) do
        if portrait.portrait.selected and portrait.info.currentIndex >= #portrait.info.chain then
            return true
        end
    end

    return false
end

function MapCommands.OCN_hideGotoPrevCommand()
    for _, portrait in pairs(craftPortraits) do
        if portrait.portrait.selected and portrait.info.currentIndex <= 1 then
            return true
        end
    end

    return false
end
