-- CraftOrdersLib
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

local moddedMapCommands = {}

function MapCommands.registerModdedMapCommand(id, commandInfo)
    if moddedMapCommands[id] == nil then
        moddedMapCommands[id] = commandInfo
    end
end

if onClient() then

MapCommands.windows = {}
MapCommands.lockedWindows = {}

function MapCommands.addWindow(window)
	MapCommands.windows[window.index] = window
end

function MapCommands.lockWindow(window)
	MapCommands.lockedWindows[window.index] = window
end

function MapCommands.unlockWindow(window)
	MapCommands.lockedWindows[window.index] = nil
end

function MapCommands.hideWindows()
	for idx, window in pairs(MapCommands.windows) do
		if not MapCommands.lockedWindows[idx] then
			window:hide()
		end
	end
end

function MapCommands.initUI()

    shipsContainer = GalaxyMap():createContainer()
    ordersContainer = GalaxyMap():createContainer()

    -- buttons for orders
    orderButtons = {}
    orders = {}
    table.insert(orders, {tooltip = "Undo"%_t,              icon = "data/textures/icons/undo.png",              callback = "onUndoPressed",         type = OrderButtonType.Undo})
    table.insert(orders, {tooltip = "Patrol Sector"%_t,     icon = "data/textures/icons/back-forth.png",        callback = "onPatrolPressed",       type = OrderButtonType.Patrol})
    table.insert(orders, {tooltip = "Attack Enemies"%_t,    icon = "data/textures/icons/crossed-rifles.png",    callback = "onAggressivePressed",   type = OrderButtonType.Attack})
    table.insert(orders, {tooltip = "Escort"%_t,            icon = "data/textures/icons/escort.png",            callback = "onEscortPressed",       type = OrderButtonType.Escort})
    table.insert(orders, {tooltip = "Mine"%_t,              icon = "data/textures/icons/mining.png",            callback = "onMinePressed",         type = OrderButtonType.Mine})
    table.insert(orders, {tooltip = "Salvage"%_t,           icon = "data/textures/icons/scrap-metal.png",       callback = "onSalvagePressed",      type = OrderButtonType.Salvage})
    table.insert(orders, {tooltip = "Refine Ores"%_t,       icon = "data/textures/icons/metal-bar.png",         callback = "onRefineOresPressed",   type = OrderButtonType.RefineOres})
    table.insert(orders, {tooltip = "Buy Goods"%_t,         icon = "data/textures/icons/bag.png",               callback = "onBuyGoodsPressed",     type = OrderButtonType.BuyGoods})
    table.insert(orders, {tooltip = "Sell Goods"%_t,        icon = "data/textures/icons/sell.png",              callback = "onSellGoodsPressed",    type = OrderButtonType.SellGoods})
    table.insert(orders, {tooltip = "Loop"%_t,              icon = "data/textures/icons/loop.png",              callback = "onLoopPressed",         type = OrderButtonType.Loop})
    table.insert(orders, {tooltip = "Stop"%_t,              icon = "data/textures/icons/halt.png",              callback = "onStopPressed",         type = OrderButtonType.Stop})

    for name,details in pairs(moddedMapCommands) do
        table.insert(orders, {tooltip = details.tooltip, icon = details.icon, callback = details.callback, type = name})
    end

    for i, order in pairs(orders) do
        local button = ordersContainer:createRoundButton(Rect(), order.icon, order.callback)
        button.tooltip = order.tooltip

        table.insert(orderButtons, button)
    end

    local res = getResolution()
    local size = vec2(600, 170)
    local unmatchable = "%+/#$@?{}[]><()"

    -- windows for choosing goods
    -- selling
    sellWindow = GalaxyMap():createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    sellWindow.caption = "Sell Goods /* Order Window Caption Galaxy Map */"%_t

    local hsplit = UIHorizontalMultiSplitter(Rect(sellWindow.size), 10, 10, 3)
    local vsplit = UIVerticalMultiSplitter(hsplit.top, 10, 0, 1)

    sellCombo = sellWindow:createValueComboBox(vsplit.left, "")

    sellFilterTextBox = sellWindow:createTextBox(vsplit.right, "onSellFilterTextChanged")
    sellFilterTextBox.backgroundText = "Filter /* Filter Goods */"%_t
    sellFilterTextBox.forbiddenCharacters = unmatchable

    local vsplit = UIVerticalSplitter(hsplit:partition(1), 10, 0, 0.7)
    sellWindow:createLabel(vsplit.left, "Amount to remain on ship: "%_t, 14)

    sellAmountTextBox = sellWindow:createTextBox(vsplit.right, "")
    sellAmountTextBox.backgroundText = "Amount /* of goods to buy */"%_t

    local vsplit = UIVerticalSplitter(hsplit:partition(2), 10, 0, 0.7)
    sellWindow:createLabel(vsplit.left, "Sell for at least X% of average price:"%_t, 14)
    sellMarginCombo = sellWindow:createValueComboBox(vsplit.right, "")

    local vsplit = UIVerticalSplitter(hsplit.bottom, 10, 0, 0.5)
    preferOwnStationsCheck = sellWindow:createCheckBox(vsplit.left, "Prefer Own Stations /* Checkbox caption for ship behavior */"%_t, "")
    preferOwnStationsCheck.captionLeft = false
    preferOwnStationsCheck.tooltip = "If checked, the ship will prefer your own stations for delivering the goods."%_t

    sellWindow:createButton(vsplit.right, "Sell /* Start sell order button caption */"%_t, "onSellWindowOKButtonPressed")


    -- buying
    buyWindow = GalaxyMap():createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    buyWindow.caption = "Buy Goods /* Order Window Caption Galaxy Map */"%_t

    local hsplit = UIHorizontalMultiSplitter(Rect(buyWindow.size), 10, 10, 3)
    local vsplit = UIVerticalMultiSplitter(hsplit.top, 10, 0, 1)

    buyCombo = buyWindow:createValueComboBox(vsplit.left, "")

    buyFilterTextBox = buyWindow:createTextBox(vsplit.right, "onBuyFilterTextChanged")
    buyFilterTextBox.backgroundText = "Filter /* Filter Goods */"%_t
    buyFilterTextBox.forbiddenCharacters = unmatchable

    local vsplit = UIVerticalSplitter(hsplit:partition(1), 10, 0, 0.7)
    buyWindow:createLabel(vsplit.left, "Amount to have on ship:"%_t, 14)

    buyAmountTextBox = buyWindow:createTextBox(vsplit.right, "")
    buyAmountTextBox.backgroundText = "Amount /* of goods to buy */"%_t

    local vsplit = UIVerticalSplitter(hsplit:partition(2), 10, 0, 0.7)
    buyWindow:createLabel(vsplit.left, "Buy for at least X% of average price:"%_t, 14)
    buyMarginCombo = buyWindow:createValueComboBox(vsplit.right, "")

    local vsplit = UIVerticalSplitter(hsplit.bottom, 10, 0, 0.5)
    buyWindow:createButton(vsplit.right, "Buy /* Start buy order button caption */"%_t, "onBuyWindowOKButtonPressed")


    -- both
    for _, combo in pairs({buyMarginCombo, sellMarginCombo}) do
        combo:addEntry(false, "Any"%_t)
        for i = 50, 150, 5 do
            combo:addEntry(i / 100, string.format("%i %%", i))
        end
    end

    -- escort window
    local escortSize = vec2(550, 50)
    escortWindow = GalaxyMap():createWindow(Rect(res * 0.5 - escortSize * 0.5, res * 0.5 + escortSize * 0.5))
    escortWindow.caption = "Escort Craft /* Order Window Caption Galaxy Map */"%_t

    local vsplit = UIVerticalSplitter(Rect(escortWindow.size), 10, 10, 0.6)
    escortCombo = escortWindow:createValueComboBox(vsplit.left, "")
    escortButton = escortWindow:createButton(vsplit.right, "Escort /* Start escort order button caption */"%_t, "onEscortWindowOKButtonPressed")


    -- all windows
	windows = { buyWindow, sellWindow, escortWindow }
	for _, window in pairs(windows) do
        window.showCloseButton = 1
        window.moveable = 1
		MapCommands.addWindow(window)
	end
	
	MapCommands.hideWindows()
end

function MapCommands.hideOrderButtons()
	for _, button in pairs(orderButtons) do
		button:hide()
	end
	MapCommands.hideWindows()
end

function MapCommands.onEscortPressed()
	enqueueNextOrder = MapCommands.isEnqueueing()
	
	MapCommands.fillEscortCombo()
	
	MapCommands.hideWindows()
	escortWindow:show()
end

function MapCommands.onBuyGoodsPressed()
	enqueueNextOrder = MapCommands.isEnqueueing()
	
	buyFilterTextBox:clear()
	buyAmountTextBox:clear()
	MapCommands.fillTradeCombo(buyCombo)
	
	MapCommands.hideWindows()
	buyWindow:show()
end

function MapCommands.onSellGoodsPressed()
	enqueueNextOrder = MapCommands.isEnqueueing()
	
	sellFilterTextBox:clear()
	sellAmountTextBox:clear()
	MapCommands.fillTradeCombo(sellCombo)
	
	MapCommands.hideWindows()
	sellWindow:show()
end

function MapCommands.updateButtonLocations()
    if #craftPortraits == 0 then
        MapCommands.hideOrderButtons()
        return
    end

    MapCommands.enchainCoordinates = nil

    local enqueueing = MapCommands.isEnqueueing()
    local sx, sy = GalaxyMap():getSelectedCoordinatesScreenPosition()
    local cx, cy = GalaxyMap():getSelectedCoordinates()
    local selected = MapCommands.getSelectedPortraits()

    local usedPortraits
    if #selected > 0 and enqueueing then
        usedPortraits = selected

        local x, y = MapCommands.getLastLocationFromInfo(selected[1].info)
        if x and y then
            sx, sy = GalaxyMap():getCoordinatesScreenPosition(ivec2(x, y))
            cx, cy = x, y
            MapCommands.enchainCoordinates = {x=x, y=y}
        else
            MapCommands.enchainCoordinates = {x=cx, y=cy}
        end
    else
        usedPortraits = craftPortraits
    end


    for _, portrait in pairs(craftPortraits) do
        if enqueueing and not portrait.portrait.selected then
            portrait.portrait:hide()
            portrait.icon:hide()
        end
    end

    local showAbove = Keyboard():keyPressed(KeyboardKey.LControl) or Keyboard():keyPressed(KeyboardKey.RControl)

    -- portraits
    local diameter = 50
    local padding = 10

    local columns = math.min(#usedPortraits, math.max(4, round(math.sqrt(#usedPortraits))))

    local offset = vec2(columns * diameter + (columns - 1) * padding, padding * 3)
    offset.x = -offset.x / 2
    offset = offset + vec2(sx, sy)

    local x = 0
    local y = 0
    for _, portrait in pairs(usedPortraits) do
        local rect = Rect()
        rect.lower = vec2(x * (diameter + padding), y * (diameter + padding)) + offset
        rect.upper = rect.lower + vec2(diameter, diameter)
        portrait.portrait.rect = rect
        portrait.portrait:show()

        if portrait.picture and portrait.picture ~= "" then
            portrait.icon.rect = Rect(rect.topRight - vec2(8, 8), rect.topRight + vec2(8, 8))
            portrait.icon:show()
            portrait.icon.picture = portrait.picture
        end

        if showAbove then
            MapCommands.mirrorUIElementY(portrait.portrait, sy)
            MapCommands.mirrorUIElementY(portrait.icon, sy)
        end

        x = x + 1
        if x >= columns then
            x = 0
            y = y + 1
        end

        ::continue::
    end


    -- buttons
    if #selected > 0 then
        if x ~= 0 then
            y = y + 1
        end

        local visibleButtons = {}
        for i, button in pairs(orderButtons) do
            local add = true

            if orders[i].type == OrderButtonType.Stop and MapCommands.isEnqueueing() then
                -- cannot enqueue a "stop"
                add = false
            elseif orders[i].type == OrderButtonType.Undo then

                -- cannot undo if there is nothing to undo
                local hasCommands = false

                for _, portrait in pairs(selected) do
                    if MapCommands.hasCommandToUndo(portrait.info) then
                        hasCommands = true
                        break
                    end
                end

                if not hasCommands then
                    add = false
                end

            elseif orders[i].type == OrderButtonType.Loop then
                -- cannot loop if there are no commands based in the selected sector
                local hasCommands = false

                if MapCommands.isEnqueueing() then
                    for _, portrait in pairs(selected) do
                        local commands = MapCommands.getCommandsFromInfo(portrait.info, cx, cy)
                        if #commands > 0 then
                            hasCommands = true
                            break
                        end
                    end
                end

                if not hasCommands then
                    add = false
                end
            end

            if moddedMapCommands[orders[i].type] ~= nil and moddedMapCommands[orders[i].type].shouldHideCallback and moddedMapCommands[orders[i].type].shouldHideCallback ~= "" then
                if MapCommands[moddedMapCommands[orders[i].type].shouldHideCallback](selected) then
                    add = false
                end
            end

            if add then
                table.insert(visibleButtons, button)
            else
                button:hide()
            end
        end


        local oDiameter = 35

        local offset = vec2(#visibleButtons * oDiameter + (#visibleButtons - 1) * padding, padding * 5)
        offset.x = -offset.x / 2
        offset = offset + vec2(sx, sy)

        for _, button in pairs(visibleButtons) do
            local rect = Rect()
            rect.lower = vec2(x * (oDiameter + padding), y * (oDiameter + padding)) + offset
            rect.upper = rect.lower + vec2(oDiameter, oDiameter)
            button.rect = rect

            if showAbove then
                MapCommands.mirrorUIElementY(button, sy)
            end

            button:show()

            x = x + 1
        end
    else
        MapCommands.hideOrderButtons()
    end
end

end
