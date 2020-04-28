-- TradeRouteTweaks
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

local routeStockLabels = {}
local routeProfitMarginLabels = {}
local routeBackButton
local routeForwardButton
function buildRoutesGui(window)
    local buttonCaption = "Show"%_t

    local buttonCallback = "onRouteShowStationPressed"
    local nextPageFunc = "onNextRoutesPage"
    local previousPageFunc = "onPreviousRoutesPage"

    local size = window.size

    window:createFrame(Rect(size))

    local fontSize = 12

    local priceX = 10
    local priceY = 0
    local stockX = 10 -- Modded
    local stockY = 12 -- Modded
    local stationLabelX = 80
    local stationLabelY = 0
    local coordLabelX = 80
    local coordLabelY = 12
    local onShipLabelX = 360
    local onShipLabelY = 0
    local profitMarginX = 360
    local profitMarginY = 12

    -- footer
    routeBackButton = window:createButton(Rect(10, size.y - 40, 60, size.y - 10), "<", previousPageFunc)
    routeForwardButton = window:createButton(Rect(size.x - 60, size.y - 40, size.x - 10, size.y - 10), ">", nextPageFunc)

    local y = 35
    for i = 1, 15 do
        local yText = y + 2

        local msplit = UIVerticalSplitter(Rect(10, y, size.x - 10, 30 + y), 10, 0, 0.5)
        msplit.leftSize = 25

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
        routeAmountOnShipLabels[i] = {} -- Modded
        routeProfitMarginLabels[i] = {}

        for j, rect in pairs({vsplit.left, vsplit.right}) do

            -- create UI for good + station where to get it
            local ssplit = UIVerticalSplitter(rect, 20, 0, 0.5)
            ssplit.rightSize = 30
            local x = ssplit.left.lower.x

            if i == 1 then
                -- header
                window:createLabel(vec2(x + priceX, priceY), "Cr"%_t, fontSize)
                window:createLabel(vec2(x + coordLabelX, coordLabelY), "Coord"%_t, fontSize)

                if j == 1 then
                    window:createLabel(vec2(x + stationLabelX, stationLabelY), "From"%_t, fontSize)
                    window:createLabel(vec2(x + stockX, stockY), "Stock"%_t, fontSize) -- Modded
                    window:createLabel(vec2(x + onShipLabelX, onShipLabelY), "Profit"%_t, fontSize) -- Modded
                    window:createLabel(vec2(x + profitMarginX, profitMarginY), "Margin"%_t, fontSize) -- Modded
                else
                    window:createLabel(vec2(x + stationLabelX, stationLabelY), "To"%_t, fontSize)
                    window:createLabel(vec2(x + stockX, stockX), "Wants"%_t, fontSize) -- Modded

                    window:createLabel(vec2(x + onShipLabelX, onShipLabelY), "On Hand"%_t, fontSize)
                    window:createLabel(vec2(x + profitMarginX, profitMarginY), "Afford"%_t, fontSize)
                end
            end

            local frame = window:createFrame(ssplit.left)

            local priceLabel = window:createLabel(vec2(x + priceX, yText + priceY), "", fontSize)
            local stationLabel = window:createLabel(vec2(x + stationLabelX, yText + stationLabelY), "", fontSize)
            local stockLabel = window:createLabel(vec2(x + stockX, yText + stockY), "", fontSize) -- Modded
            local coordLabel = window:createLabel(vec2(x + coordLabelX, yText + coordLabelY), "", fontSize)
            local onShipLabel = window:createLabel(vec2(x + onShipLabelX, yText + onShipLabelY), "", fontSize)
            local profitMarginLabel = window:createLabel(vec2(x + profitMarginX, yText + profitMarginY), "", fontSize)

            local button = window:createButton(ssplit.right, "", buttonCallback)
            button.icon = "data/textures/icons/position-marker.png"

            onShipLabel.font = FontType.Normal

            frame:hide()
            priceLabel:hide()
            stockLabel:hide() -- Modded
            coordLabel:hide()
            stationLabel:hide()
            button:hide()
            onShipLabel:hide()
            profitMarginLabel:hide()

            priceLabel.font = FontType.Normal
            coordLabel.font = FontType.Normal
            stockLabel.font = FontType.Normal -- Modded
            stationLabel.font = FontType.Normal
            profitMarginLabel.font = FontType.Normal

            table.insert(routeFrames[i], frame)
            table.insert(routePriceLabels[i], priceLabel)
            table.insert(routeCoordLabels[i], coordLabel)
            table.insert(routeStockLabels[i], stockLabel) -- Modded
            table.insert(routeStationLabels[i], stationLabel)
            table.insert(routeButtons[i], button)
            table.insert(routeAmountOnShipLabels[i], onShipLabel)
            table.insert(routeProfitMarginLabels[i], profitMarginLabel)
        end

        y = y + 32
    end
end

function refreshRoutesUI()
    if historySize == 0 then
        tabbedWindow:deactivateTab(routesTab)
        return
    end

    local cashOnHand = Player().money

    routeBackButton:hide()
    routeForwardButton:hide()

    for index = 1, 15 do
        for j = 1, 2 do
            routePriceLabels[index][j]:hide()
            routeStationLabels[index][j]:hide()
            routeCoordLabels[index][j]:hide()
            routeStockLabels[index][j]:hide() -- Modded
            routeFrames[index][j]:hide()
            routeButtons[index][j]:hide()
            routeIcons[index]:hide()
            routeAmountOnShipLabels[index][j]:hide()
            routeProfitMarginLabels[index][j]:hide()
        end
    end

    table.sort(routes, routesByProfit)

    if routesPage == nil or routesPage > 0 then
        routeBackButton:show()
    end

    local index = 0
    for i, route in pairs(routes) do

        if i > (routesPage + 1) * 15 then
            routeForwardButton:show()
        end

        if i > routesPage * 15 and i <= (routesPage + 1) * 15 then
            index = index + 1
            if index > 15 then break end

            local profit, prefix = getReadableNumber(routeProfit(route))
            local margin = math.floor(((route.sellable.price - route.buyable.price) / route.buyable.price) * 10000) / 100
            local maxPurchase = math.floor(math.min(route.buyable.stock, route.sellable.maxStock - route.sellable.stock, cashOnHand / route.buyable.price))

            for j, offer in pairs({route.buyable, route.sellable}) do
                routePriceLabels[index][j].caption = createMonetaryString(offer.price)
                routeStationLabels[index][j].caption = offer.station%_t % offer.titleArgs
                routeCoordLabels[index][j].caption = tostring(offer.coords)
                routeIcons[index].picture = offer.good.icon
                routeIcons[index].tooltip = offer.good:displayName(2)

                if j == 1 then
                    routeAmountOnShipLabels[index][j].caption = profit .. prefix
                    routeStockLabels[index][j].caption = math.floor(offer.stock)  -- Modded
                    routeProfitMarginLabels[index][j].caption = margin .. "%"
                else
                    routeProfitMarginLabels[index][j].caption = maxPurchase
                    routeStockLabels[index][j].caption = math.floor(offer.maxStock - offer.stock) -- Modded
                    if offer.amountOnShip > 0 then
                        routeAmountOnShipLabels[index][j].caption = offer.amountOnShip
                    else
                        routeAmountOnShipLabels[index][j].caption = "-"
                    end
                end

                routePriceLabels[index][j]:show()
                routeStationLabels[index][j]:show()
                routeCoordLabels[index][j]:show()
                routeStockLabels[index][j]:show() -- Modded
                routeFrames[index][j]:show()
                routeButtons[index][j]:show()
                routeAmountOnShipLabels[index][j]:show()
                routeProfitMarginLabels[index][j]:show()
                routeIcons[index]:show()
            end
        end

    end
end

function routeProfit(route)
    -- calculate route profit
    local maxTrade = 0
    local sellableStock = route.sellable.maxStock - route.sellable.stock
    if sellableStock > route.buyable.stock then
        maxTrade = route.buyable.stock
    else
        maxTrade = sellableStock
    end
    return (route.sellable.price - route.buyable.price) * maxTrade
end

function routesByProfit(a, b)
    -- calculate max profit
    local pa = routeProfit(a)
    local pb = routeProfit(b)
    return pa > pb
end
