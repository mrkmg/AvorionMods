-- OrderPausing
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

MapCommands.registerModdedMapCommand('pause', {
    tooltip = "Pause",
    icon = "data/textures/icons/cancel.png",
    callback = "pause",
    shouldHideCallback = "hidePauseButton"
})

MapCommands.registerModdedMapCommand('resume', {
    tooltip = "Resume",
    icon = "data/textures/icons/play.png",
    callback = "resume",
    shouldHideCallback = "hideResumeButton"
})

function MapCommands.pause()
    MapCommands.enqueueOrder("pause")
    MapCommands.updateButtonLocations()
end

function MapCommands.resume()
    MapCommands.enqueueOrder("resume")
    MapCommands.updateButtonLocations()
end

if onClient() then


    function MapCommands.hidePauseButton()
        for _, portrait in pairs(craftPortraits) do
            if portrait.portrait.selected and portrait.info.paused then
                return true
            end
        end

        return false
    end

    function MapCommands.hideResumeButton()
        for _, portrait in pairs(craftPortraits) do
            if portrait.portrait.selected and not portrait.info.paused then
                return true
            end
        end

        return false
    end
end