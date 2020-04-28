local MapRoutes_fillOrderInfoTooltip_OrderPausing_orig = MapRoutes.fillOrderInfoTooltip
function MapRoutes.fillOrderInfoTooltip(tooltip, info)
    if not info then return end

    if info.paused then
        local line = TooltipLine(15, 14)
        line.ctext = "This craft is paused."%_t
        line.ccolor = ColorRGB(1.0, 1.0, 0.3)
        tooltip:addLine(line)
        tooltip:addLine(TooltipLine(15, 15))
    end

    MapRoutes_fillOrderInfoTooltip_OrderPausing_orig(tooltip, info)
end