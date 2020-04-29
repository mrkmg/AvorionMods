package.path = package.path .. ";data/scripts/lib/?.lua"
include ("data/scripts/player/map/common")
include ("callable")
include ("utility")
include ("orderbook_tablecompare")
local Node = include ("gravyui/node")
local json = include("orderbook_json")

-- namespace OrderBook
OrderBook = {}

local savedChains = {}
local loadedChain = {}


if onClient() then -- START CLIENT
    ----@type Button
    local openWindowButton
    ----@type Window
    local mainWindow
    ----@type Window
    local editCommandWindow
    ---@type ValueComboBox
    local readComboBox
    ----@type TextBox
    local writeTextBox
    ----@type TextBox
    local editCommandTextBox
    ----@type Button
    local writeButton
    --- @type CheckBox
    local syncCheckbox

    local chainRowItems = {}
    local chainPage = 1
    ----@type Button
    local chainPreviousPageButton
    ----@type Button
    local chainNextPageButton
    ----@type Button
    local applyOrdersButton
    ----@type Button
    local loadOrdersButton
    ----@type Button
    local deleteButton

    local chainEditIndex
    local syncIgnoreNext = false
    local syncName = nil

    local lastLoadedIndex = 1

    --== CONFIG ==--
    local rowSize = 30
    local pageSize = 10

    function OrderBook.initialize()
        OrderBook.initUI()
        Player():registerCallback("onShipOrderInfoUpdated", "syncLoad")
    end
    
    function OrderBook.initUI()
        local galaxy = GalaxyMap()
        local res = getResolution()

        OrderBook.createGalaxyMapButton(galaxy, res)
        OrderBook.createMainWindow(galaxy, res)
        OrderBook.createdEditWindow(galaxy, res)

        OrderBook.syncGet()
    end

    function OrderBook.createGalaxyMapButton(galaxy, res)
        local buttonContainer = galaxy:createContainer()
        openWindowButton = buttonContainer:createButton(Rect(res.x - 50, res.y - 50, res.x, res.y), "", "openMainWindow")
        openWindowButton.icon = "data/textures/icons/open-book.png"
        openWindowButton.tooltip = "Open Order Book"
    end

    function OrderBook.createMainWindow(galaxy, res)
        local size = vec2(400, 420)

        local root = Node(size.x, size.y):pad(10)
        local top, middle, bottom = root:rows({60, 1, 35}, 10)
        top = {top:grid(2, 2, 5, 5)}
        local chainTable, chainNextPrev = middle:rows({1, 25}, 10)
        chainTable = {chainTable:grid(10, {3/5, 2/25, 2/25, 2/25, 2/25, 2/25}, 5, 2)}
        chainNextPrev = {chainNextPrev:cols(2, 1/4)}
        bottom = {bottom:pad(0, 12, 0, 0):cols({1/4, 3/8, 3/8}, 10)}

        mainWindow = galaxy:createWindow(Rect(res.x - size.x - 5, res.y/2 - size.y/2, res.x - 5, res.y/2 + size.y/2))
        readComboBox = mainWindow:createValueComboBox(top[1][1].rect, "loadGo")
        writeTextBox = mainWindow:createTextBox(top[1][2].rect, "renderMainWindow")
        deleteButton = mainWindow:createButton(top[2][1].rect, "Delete Book", "deleteGo")
        writeButton = mainWindow:createButton(top[2][2].rect, "Write Book", "writeGo")
        chainPreviousPageButton = mainWindow:createButton(chainNextPrev[1].rect, "Previous Page", "writePageBack")
        chainNextPageButton = mainWindow:createButton(chainNextPrev[2].rect, "Next Page", "writePageNext")
        syncCheckbox = mainWindow:createCheckBox(bottom[1].rect, "Sync", "syncChanged")
        loadOrdersButton = mainWindow:createButton(bottom[2].rect, "Load Orders", "loadFromSelected")
        applyOrdersButton = mainWindow:createButton(bottom[3].rect, "Replace Orders", "applyOrders")

        writeTextBox.forbiddenCharacters = "%+/#$@?{}[]><()"
        mainWindow.caption = "Order Chain Book Reader/Writer /* Order Window Caption Galaxy Map */"%_t
        mainWindow.showCloseButton = 1
        mainWindow.moveable = 1
        mainWindow.closeableWithEscape = 1

        for i = 1,pageSize do
            local lab = mainWindow:createLabel(chainTable[i][1].rect, "", 14)
            local rj = mainWindow:createCheckBox(chainTable[i][2].rect, "", "chainRelativeJumpChanged")
            local upBut = mainWindow:createButton(chainTable[i][3].rect, "", "chainMoveUpGo")
            local downBut = mainWindow:createButton(chainTable[i][4].rect, "", "chainMoveDownGo")
            local editBut = mainWindow:createButton(chainTable[i][5].rect, "", "chainEditShow")
            local delBut = mainWindow:createButton(chainTable[i][6].rect, "", "chainDeleteGo")

            lab:setLeftAligned()
            rj.tooltip = "Relative Jump"
            upBut.icon = "data/textures/icons/arrow-up.png"
            upBut.tooltip = "Move Up"
            downBut.icon = "data/textures/icons/arrow-down.png"
            downBut.tooltip = "Move Down"
            editBut.icon = "data/textures/icons/pencil.png"
            editBut.tooltip = "Edit Data"
            delBut.icon = "data/textures/icons/trash-can.png"
            delBut.tooltip = "Delete"

            chainRowItems[i] = {
                label = lab,
                relativeJumpCheckbox = rj,
                upButton = upBut,
                downButton = downBut,
                editButton = editBut,
                deleteButton = delBut
            }
        end
        
        mainWindow:hide()
    end

    function OrderBook.createdEditWindow(galaxy, res)
        local size = vec2(400, 300)
        local warningLabelNode, editBoxNode, bottomButtons = Node(size.x, size.y):pad(5):rows({30, 1, 30}, 5)
        local leftBut, rightBut = bottomButtons:cols(2, 10)

        editCommandWindow = galaxy:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
        local warningLabel = editCommandWindow:createLabel(warningLabelNode.rect, "Only the most experienced, or daring, pilots should edit their own orders.", 14)
        editCommandTextBox = editCommandWindow:createMultiLineTextBox(editBoxNode.rect)
        editCommandWindow:createButton(leftBut.rect, "Cancel", "cancelEditCommand")
        editCommandWindow:createButton(rightBut.rect, "Done", "finishEditCommand")

        warningLabel:setCenterAligned()
        warningLabel.color = ColorRGB(1, 0, 0)

        editCommandWindow:hide()
    end

    function OrderBook.hideOrderButtons()
        syncName = nil
        syncCheckbox:setCheckedNoCallback(false)
    end

    function OrderBook.onGalaxyMapKeyboardEvent(key, pressed)
        if mainWindow.visible and (key == KeyboardKey.LShift or key == KeyboardKey.RShift) then
            OrderBook.renderMainWindow()
        end
    end

    function OrderBook.getOrderDesc(i, order)
        if order.action == OrderType.Jump then
            if order.relative == true then
                return "[" .. i .. "] " .. order.name .. " to relative"
            else
                return "[" .. i .. "] " .. order.name .. " to " .. order.x .. " : " .. order.y
            end
        elseif order.action == OrderType.FlyThroughWormhole then
            return "[" .. i .. "] " .. order.name .. " to " .. order.x .. " : " .. order.y
        elseif order.action == OrderType.BuyGoods or order.action == OrderType.SellGoods then
            local goodName = order.args[1]
            local good = goods[goodName]
            local amount = order.args[3] or 0
            if good then
                good = good:good()
                if good then
                    goodName = good:displayName(amount)
                end
            end
            return "[" .. i .. "] " .. order.name .. " - (" .. amount .. ") " .. goodName
        elseif order.action == OrderType.Loop then
            return "[" .. i .. "] " .. "Loop to [" .. order.loopIndex .. "]"
        else
            return "[" .. i .. "] " .. order.name
        end
    end

    function OrderBook.syncChanged()
        if syncCheckbox.checked then
            local sp = MapCommands.getSelectedPortraits()

            if sp ~= nil and #sp == 1 then
                syncName = sp[1].name
            else
                OrderBook.sendError("Select only 1 craft")
                syncName = nil
            end
        else
            syncName = nil
        end
        
        OrderBook.renderMainWindow()
    end

    function OrderBook.syncApply()
        if syncName == nil then
            return
        end

        local selectedPorts = MapCommands.getSelectedPortraits()

        if not selectedPorts or #selectedPorts ~= 1 then
            return 
        end

        if selectedPorts[1].name ~= syncName then
            return
        end

        local chain = table.deepcopy(loadedChain)
        syncIgnoreNext = true
        MapCommands.enqueueOrder("OrderBook_setChain", chain, true, true)
    end

    function OrderBook.syncLoad(name, info)
        if syncName == name then
            if syncIgnoreNext then
                syncIgnoreNext = false
            else
                loadedChain = info.chain
                OrderBook.syncSet()
                OrderBook.renderMainWindow()
            end
        end
    end

    function OrderBook.writeGo()
        local bookName = writeTextBox.text
        if not bookName or bookName == "" then 
            OrderBook.sendError("Books must have a name.")
            return 
        end

        if #loadedChain == 0 then
            OrderBook.sendError("Can not write an empty book.")
            return
        end

        for i,c in pairs(savedChains) do
            if c.name == bookName then
                table.remove(savedChains, i)
                break
            end
        end

        table.insert(savedChains, {name = bookName, chain = table.deepcopy(loadedChain)})
        OrderBook.syncSet()
        OrderBook.renderMainWindow()
    end

    function OrderBook.applyOrders()
        local selectedPorts = MapCommands.getSelectedPortraits()
        if #selectedPorts == 0 then 
            OrderBook.sendWarning("No craft selected")
            return 
        end

        local chain = table.deepcopy(loadedChain)

        MapCommands.enqueueOrder("OrderBook_setChain", chain, not MapCommands.isEnqueueing(), false)
    end

    function OrderBook.loadGo()
        local bookName = readComboBox.selectedValue

        if lastLoadedIndex ~= 0 then
            loadedChain = {}
        end
        writeTextBox.text = ""
        for _, savedChain in pairs(savedChains) do
            if savedChain.name == bookName then
                loadedChain = table.deepcopy(savedChain.chain)
                writeTextBox.text = savedChain.name
                break
            end
        end

        OrderBook.syncSet()
        OrderBook.syncApply()
        OrderBook.renderMainWindow()
    end

    function OrderBook.deleteGo()
        local bookName = readComboBox.selectedValue
        if not bookName or bookName == "" then return end

        local chainIndex = nil
        for index, savedChain in pairs(savedChains) do
            if savedChain.name == bookName then
                chainIndex = index
                break
            end
        end
        if chainIndex == nil then return end

        table.remove(savedChains, chainIndex)

        OrderBook.renderMainWindow()
        OrderBook.syncSet()
    end


    function OrderBook.writePageNext()
        chainPage = chainPage + 1
        OrderBook.renderMainWindow()
    end

    function OrderBook.writePageBack()
        chainPage = chainPage - 1
        OrderBook.renderMainWindow()
    end

    function OrderBook.checkTargetIsLoop(order)
        if order and order.action == OrderType.Loop then
            OrderBook.sendError("Cannot move loop orders.")
            return true
        end
        return false
    end

    function OrderBook.chainMoveUpGo(but)
        local pageStartIndex = (chainPage - 1) * pageSize
        for rowIndex,row in pairs(chainRowItems) do
            if row.upButton.index == but.index then
                local targetIndex = pageStartIndex + rowIndex

                if OrderBook.checkTargetIsLoop(loadedChain[targetIndex]) then return end
                if OrderBook.checkTargetIsLoop(loadedChain[targetIndex - 1]) then return end

                local newChain = {}

                for index, order in pairs(loadedChain) do
                    if index == targetIndex - 1 then
                        table.insert(newChain, loadedChain[targetIndex])
                    elseif index == targetIndex then
                        table.insert(newChain, loadedChain[targetIndex - 1])
                    else
                        table.insert(newChain, order)
                    end
                end

                loadedChain = newChain
                OrderBook.syncSet()
                OrderBook.syncApply()
                OrderBook.renderMainWindow()
                return
            end
        end
    end

    function OrderBook.chainMoveDownGo(but)
        local pageStartIndex = (chainPage - 1) * pageSize
        for rowIndex,row in pairs(chainRowItems) do
            if row.downButton.index == but.index then
                local targetIndex = pageStartIndex + rowIndex

                if OrderBook.checkTargetIsLoop(loadedChain[targetIndex]) then return end
                if OrderBook.checkTargetIsLoop(loadedChain[targetIndex + 1]) then return end

                local newChain = {}

                local tempOrder
                for index, order in pairs(loadedChain) do
                    if index == targetIndex then
                        table.insert(newChain, loadedChain[targetIndex + 1])
                    elseif index == targetIndex + 1 then
                        table.insert(newChain, loadedChain[targetIndex])
                    else
                        table.insert(newChain, order)
                    end
                end

                loadedChain = newChain
                OrderBook.syncSet()
                OrderBook.syncApply()
                OrderBook.renderMainWindow()
                return
            end
        end
    end

    function OrderBook.chainEditShow(but)
        local pageStartIndex = (chainPage - 1) * pageSize
        for rowIndex,row in pairs(chainRowItems) do
            if row.editButton.index == but.index then
                chainEditIndex = pageStartIndex + rowIndex
                local editTbl = {}
                for k,v in pairs(loadedChain[chainEditIndex]) do
                    if k ~= "action" and k ~= "name" and k ~= "icon" and k ~= "pixelIcon" then
                        editTbl[k] = v
                    end
                end
                local editData = json.encode(editTbl, {indent = true})
                editCommandTextBox.text = editData
                editCommandWindow:show()
                mainWindow:hide()
            end
        end
    end

    function OrderBook.chainDeleteGo(but)
        local pageStartIndex = (chainPage - 1) * pageSize
        for rowIndex,row in pairs(chainRowItems) do
            if row.deleteButton.index == but.index then
                local targetIndex = pageStartIndex + rowIndex
                local newChain = {}
                local didRemove = false
                for chainIndex, order in pairs(loadedChain) do
                    if chainIndex ~= targetIndex then
                        if order.action == OrderType.Loop and order.loopIndex > targetIndex then
                            order.loopIndex = order.loopIndex - 1
                        end
                        table.insert(newChain, order)
                    end
                end

                loadedChain = newChain
                OrderBook.syncSet()
                OrderBook.syncApply()
                OrderBook.renderMainWindow()
                return
            end
        end
    end

    function OrderBook.chainRelativeJumpChanged(check)
        local pageStartIndex = (chainPage - 1) * pageSize
        for rowIndex,row in pairs(chainRowItems) do
            if row.relativeJumpCheckbox.index == check.index then
                local targetIndex = pageStartIndex + rowIndex
                local order = loadedChain[targetIndex]

                if order and order.action == OrderType.Jump then
                    order.relative = check.checked
                end

                OrderBook.syncSet()
                OrderBook.renderMainWindow()
                return
            end
        end
    end

    function OrderBook.cancelEditCommand()
        editCommandWindow:hide()
        OrderBook.renderMainWindow()
        mainWindow:show()
    end

    function OrderBook.finishEditCommand()
        local obj, pos, err = json.decode(editCommandTextBox.text, 1, nil)

        if not err then
            for k,v in pairs(obj) do
                loadedChain[chainEditIndex][k] = v
            end
            editCommandWindow:hide()
            OrderBook.syncApply()
            OrderBook.syncSet()
            OrderBook.renderMainWindow()
            mainWindow:show()
        else
            OrderBook.sendError("Order data is invalid")
        end
    end

    --=== Rendering ===--

    function OrderBook.renderMainWindow()
        -- Update Saved Books
        local comp = function(a, b) return a.name < b.name end
        table.sort(savedChains, comp)
        readComboBox:clear()
        local loadedIndex = 0
        readComboBox:addEntry("", "")
        deleteButton:hide()
        for index,savedChain in pairs(savedChains) do
            readComboBox:addEntry(savedChain.name, savedChain.name)
            if tablesEqual(loadedChain, savedChain.chain) then
                loadedIndex = index
                deleteButton:show()
            end
        end
        readComboBox:setSelectedIndexNoCallback(loadedIndex)
        lastLoadedIndex = loadedIndex

        -- Set write button
        local bookName = writeTextBox.text
        local isOverwrite = false
        if bookName ~= "" then
            for _,c in pairs(savedChains) do
                if c.name == bookName then
                    isOverwrite = true
                    break
                end
            end
        end

        if isOverwrite then
            writeButton.caption = "Overwrite Book"
        else
            writeButton.caption = "Write Book"
        end

        if syncName == nil then
            -- Set apply button
            if MapCommands.isEnqueueing() then
                applyOrdersButton.caption = "Append Orders"
            else
                applyOrdersButton.caption = "Replace Orders"
            end

            applyOrdersButton:show()
            loadOrdersButton:show()

            if #MapCommands.getSelectedPortraits() == 1 then
                syncCheckbox:show()
            else
                syncCheckbox:hide()
            end
        else
            applyOrdersButton:hide()
            loadOrdersButton:hide()
        end

        -- Write Chain
        local chainLength = #loadedChain
        local pageStartIndex = (chainPage - 1) * pageSize
        for rowIndex = 1, pageSize do
            local chainIndex = pageStartIndex + rowIndex
            local order = loadedChain[chainIndex]
            local row = chainRowItems[rowIndex]

            if order then
                for _, o in pairs(row) do o:show() end

                row.label.caption = OrderBook.getOrderDesc(chainIndex, order)
                
                if order.action == OrderType.Jump then
                    row.relativeJumpCheckbox:show()
                    if order.relative ~= row.relativeJumpCheckbox.checked then
                        if order.relative == true then
                            row.relativeJumpCheckbox.checked = true
                        else
                            row.relativeJumpCheckbox.checked = false
                        end
                    end
                else
                    row.relativeJumpCheckbox:hide()
                end

                if chainIndex == 1 then row.upButton:hide()
                else row.upButton:show() end

                if chainIndex == chainLength then row.downButton:hide()
                else row.downButton:show() end
            else
                for _, o in pairs(row) do o:hide() end
            end
        end

        if loadedChain[pageStartIndex + pageSize + 1] then chainNextPageButton:show() 
        else chainNextPageButton:hide() end

        if chainPage == 1 then chainPreviousPageButton:hide() 
        else chainPreviousPageButton:show() end
    end

    function OrderBook.openMainWindow()
        loadedChain = {}
        OrderBook.renderMainWindow()
        writeTextBox:clear()
        mainWindow:show()
    end

    function OrderBook.loadFromSelected()
        local selectedPorts = MapCommands.getSelectedPortraits()
        if #selectedPorts == 0 then 
            OrderBook.sendWarning("No craft selected")
            return 
        end

        local tblOfChains = {}
        for _,p in pairs(selectedPorts) do
            table.insert(tblOfChains, p.info.chain)
        end

        if allTablesEqual(tblOfChains) then
            local selectedPort = selectedPorts[1]
            if not selectedPort then return end
            loadedChain = table.deepcopy(selectedPort.info.chain)
            OrderBook.syncSet()
            OrderBook.renderMainWindow()
        else
            OrderBook.sendWarning("Selected crafts have different orders, not reading")
        end
    end

end -- END CLIENT

function OrderBook.sendError(msg)
    if onClient() then
        invokeServerFunction("sendError", msg)
    else
        if callingPlayer then
            Player(callingPlayer):sendChatMessage("", ChatMessageType.Error, msg)
        end
    end
end
callable(OrderBook, "sendError")

function OrderBook.sendWarning(msg)
    if onClient() then
        invokeServerFunction("sendWarning", msg)
    else
        if callingPlayer then
            Player(callingPlayer):sendChatMessage("", ChatMessageType.Warning, msg)
        end
    end
end
callable(OrderBook, "sendWarning")

function OrderBook.syncGet()
    if onClient() then
        invokeServerFunction("syncSet")
    else
        invokeClientFunction("syncSet")
    end
end

function OrderBook.syncSet(data)
    if data then 
        OrderBook.restore(data)
    else
        if onClient() then
            invokeServerFunction("syncSet", OrderBook.secure())
        else
            if callingPlayer then
                invokeClientFunction(Player(callingPlayer), "syncSet", OrderBook.secure())
            end
        end
    end
end
callable(OrderBook, "syncSet")

function OrderBook.secure()
    return {data = savedChains, loadedChain = loadedChain}
end

function OrderBook.restore(data)
    if data.loadedChain then
        loadedChain = loadedChain
    end
    if data.data then
        for i,c in pairs(data.data) do
            if c.name then
                table.insert(savedChains, c)
            end
        end
    end
end