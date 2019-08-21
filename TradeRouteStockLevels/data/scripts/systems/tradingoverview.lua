
local routeStockLabels = {}

function buildRoutesGui(window)
    local buttonCaption = "Show"%_t

    local buttonCallback = "onRouteShowStationPressed"
    local nextPageFunc = "onNextRoutesPage"
    local previousPageFunc = "onPreviousRoutesPage"

    local size = window.size

    window:createFrame(Rect(size))

    local priceX = 10
    local stockX = 80 -- Modded
    local stationLabelX = 170
    local coordLabelX = 80
    local onShipLabelX = 360

    -- footer
    window:createButton(Rect(10, size.y - 40, 60, size.y - 10), "<", previousPageFunc)
    window:createButton(Rect(size.x - 60, size.y - 40, size.x - 10, size.y - 10), ">", nextPageFunc)

    local y = 35
    for i = 1, 15 do

        local yText = y + 6

        local msplit = UIVerticalSplitter(Rect(10, y, size.x - 10, 30 + y), 10, 0, 0.5)
        msplit.leftSize = 30

        local icon = window:createPicture(msplit.left, "")
        icon.isIcon = 1
        icon.picture = "data/textures/icons/circuitry.png"
        icon:hide()

        local vsplit = UIVerticalSplitter(msplit.right, 10, 0, 0.5)

        routeIcons[i] = icon
        routeFrames[i] = {}
        routePriceLabels[i] = {}
        routeCoordLabels[i] = {}
        routeStockLabels[i] = {} -- Modded
        routeStationLabels[i] = {}
        routeButtons[i] = {}
        routeAmountOnShipLabels[i] = nil

        for j, rect in pairs({vsplit.left, vsplit.right}) do

            -- create UI for good + station where to get it
            local ssplit = UIVerticalSplitter(rect, 10, 0, 0.5)
            ssplit.rightSize = 30
            local x = ssplit.left.lower.x

            if i == 1 then
                -- header
                window:createLabel(vec2(x + priceX, 10), "Cr"%_t, 15)
                window:createLabel(vec2(x + coordLabelX, 10), "Coord"%_t, 15)

                if j == 1 then
                    window:createLabel(vec2(x + stationLabelX, 10), "From"%_t, 15)
                    window:createLabel(vec2(x + stockX, 10), "Stock"%_t, 15) -- Modded
                else
                    window:createLabel(vec2(x + stationLabelX, 10), "To"%_t, 15)
                    window:createLabel(vec2(x + stockX, 10), "Stock"%_t, 15) -- Modded

                    window:createLabel(vec2(x + onShipLabelX, 10), "You"%_t, 15)
                end
            end

            local frame = window:createFrame(ssplit.left)

            local priceLabel = window:createLabel(vec2(x + priceX, yText), "", 15)
            local stationLabel = window:createLabel(vec2(x + stationLabelX, yText), "", 15)
            local stockLabel = window:createLabel(vec2(x + stockX, yText), "", 15) -- Modded
            local coordLabel = window:createLabel(vec2(x + coordLabelX, yText), "", 15)

            local button = window:createButton(ssplit.right, "", buttonCallback)
            button.icon = "data/textures/icons/position-marker.png"

            if j == 2 then
                local onShipLabel = window:createLabel(vec2(x + onShipLabelX, yText), "", 15)
                onShipLabel.font = FontType.Normal
                onShipLabel:hide()
                routeAmountOnShipLabels[i] = onShipLabel
            end

            frame:hide();
            priceLabel:hide();
            stockLabel:hide() -- Modded
            coordLabel:hide();
            stationLabel:hide();
            button:hide();

            priceLabel.font = FontType.Normal
            coordLabel.font = FontType.Normal
            stockLabel.fond = FontType.Normal -- Modded
            stationLabel.font = FontType.Normal

            table.insert(routeFrames[i], frame)
            table.insert(routePriceLabels[i], priceLabel)
            table.insert(routeCoordLabels[i], coordLabel)
            table.insert(routeStockLabels[i], stockLabel) -- Modded
            table.insert(routeStationLabels[i], stationLabel)
            table.insert(routeButtons[i], button)
        end


        y = y + 35
    end

end


function refreshRoutesUI()
    if historySize == 0 then
        tabbedWindow:deactivateTab(routesTab)
        return
    end

    for index = 1, 15 do
        for j = 1, 2 do
            routePriceLabels[index][j]:hide()
            routeStationLabels[index][j]:hide()
            routeCoordLabels[index][j]:hide()
            routeStockLabels[index]:hide() -- Modded
            routeFrames[index][j]:hide()
            routeButtons[index][j]:hide()
            routeIcons[index]:hide()
            routeAmountOnShipLabels[index]:hide()
        end
    end

    table.sort(routes, routesByPriceMargin)

    local index = 0
    for i, route in pairs(routes) do

        if i > routesPage * 15 and i <= (routesPage + 1) * 15 then
            index = index + 1
            if index > 15 then break end

            for j, offer in pairs({route.buyable, route.sellable}) do

                routePriceLabels[index][j].caption = createMonetaryString(offer.price)
                routeStationLabels[index][j].caption = offer.station%_t % offer.titleArgs
                routeStockLabels[index][j].caption = math.floor(offer.stock) .. " / " .. math.floor(offer.maxStock) -- Modded
                routeCoordLabels[index][j].caption = tostring(offer.coords)
                routeIcons[index].picture = offer.good.icon
                routeIcons[index].tooltip = offer.good:displayName(2)
                if j == 2 then
                    if offer.amountOnShip > 0 then
                        routeAmountOnShipLabels[index].caption = offer.amountOnShip
                    else
                        routeAmountOnShipLabels[index].caption = "-"
                    end
                    routeAmountOnShipLabels[index]:show()
                end

                routePriceLabels[index][j]:show()
                routeStationLabels[index][j]:show()
                routeCoordLabels[index][j]:show()
                routeStockLabels[index][j]:show() -- Modded
                routeFrames[index][j]:show()
                routeButtons[index][j]:show()
                routeIcons[index]:show()
            end
        end
    end
end
