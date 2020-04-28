function MapRoutes.renderTooltips()
    local portraits = MapCommands.getSelectedPortraits()
    if #portraits == 0 then return end

    local tooltip = Tooltip()

    if #portraits == 1 then
        local portrait = portraits[1]
        local info = portrait.info

        MapRoutes.fillOrderInfoTooltip(tooltip, info)
    end

    local ship = Player().craft
    if ship then
        for _, portrait in pairs(portraits) do
            if portrait.name == ship.name and portrait.owner == ship.factionIndex then
                local line = TooltipLine(15, 14)
                line.ctext = "You can't command the craft you're steering."%_t
                line.ccolor = ColorRGB(1, 0.3, 0.3)
                tooltip:addLine(line)

                tooltip:addLine(TooltipLine(15, 15))
            end
        end
    end

    local line = TooltipLine(15, 14)
    line.ltext = "Ctrl:"%_t
    line.lcolor = ColorRGB(0, 1, 1)
    line.rtext = "Move icons"%_t
    line.rcolor = ColorRGB(0, 1, 1)
    tooltip:addLine(line)

    tooltip:addLine(TooltipLine(10, 10))

    local line = TooltipLine(15, 14)
    line.ltext = "Shift (Tap):"%_t
    line.lcolor = ColorRGB(0, 1, 1)
    if MapCommands.isEnqueueing() then
        line.ctext = "On"%_t
        line.ccolor = ColorRGB(0, 1, 0)
    else
        line.ctext = "Off"%_t
        line.ccolor = ColorRGB(1, 0, 0)
    end
    line.rtext = "Enchain commands"%_t
    line.rcolor = ColorRGB(0, 1, 1)
    tooltip:addLine(line)

    local renderer = TooltipRenderer(tooltip)

    local resolution = getResolution()
    renderer:draw(vec2(10, resolution.y))
end