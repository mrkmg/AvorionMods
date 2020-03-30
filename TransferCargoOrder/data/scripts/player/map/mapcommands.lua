-- TransferCargoOrder
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

include ("ordertypes")

MapCommands.registerModdedMapCommand(OrderType.TransferCargo, {
    tooltip = "Transfer Cargo",
    icon = "data/textures/icons/cargo-hold.png",
    callback = "onTransferCargoPressed",
})

if onClient() then
local transferCargoWindow
local transferCargoCombo
local transferCargoButton
local transferCargoData

local TransferCargoOrder_MapCommands_initUI_original = MapCommands.initUI
function MapCommands.initUI() 
    TransferCargoOrder_MapCommands_initUI_original()
    
    local TCSize = vec2(550, 50)
    local res = getResolution()
    transferCargoWindow = GalaxyMap():createWindow(Rect(res * 0.5 - TCSize * 0.5, res * 0.5 + TCSize * 0.5))
    transferCargoWindow.caption = "Transfer Cargo to: /* Order Window Caption Galaxy Map */"%_t

    local vsplit = UIVerticalSplitter(Rect(transferCargoWindow.size), 10, 10, 0.6)
    transferCargoCombo = transferCargoWindow:createValueComboBox(vsplit.left, "")
    transferCargoButton = transferCargoWindow:createButton(vsplit.right, "Transfer /* Start escort order button caption */"%_t, "onTransferCargoWindowOKButtonPressed")
    
    transferCargoWindow:hide()
end

local TransferCargoOrder_MapCommands_hideOrderButtons_original = MapCommands.hideOrderButtons
function MapCommands.hideOrderButtons()
    TransferCargoOrder_MapCommands_hideOrderButtons_original()
    transferCargoWindow:hide()
end

function MapCommands.onTransferCargoPressed()
    enqueueNextOrder = MapCommands.isEnqueueing()

    MapCommands.fillTransferCargoCombo()

    buyWindow:hide()
    sellWindow:hide()
    escortWindow:hide()
    transferCargoWindow:show()
end

function MapCommands.fillTransferCargoCombo()
    transferCargoCombo:clear()
    transferCargoData = {}

    local x, y = GalaxyMap():getSelectedCoordinates()
    local player = Player()
    local portraits = MapCommands.getSelectedPortraits()

    MapCommands.addTransferCargoComboEntries(player, portraits, player.index, {player:getNamesOfShipsInSector(x, y)}, ColorRGB(0.875, 0.875, 0.875))

    if player.alliance then
        MapCommands.addTransferCargoComboEntries(player, portraits, player.allianceIndex, {player.alliance:getNamesOfShipsInSector(x, y)}, ColorRGB(1, 0, 1))
    end
end

function MapCommands.addTransferCargoComboEntries(player, portraits, factionIndex, crafts, color)
    for _, name in pairs(crafts) do
        local canAdd = true
        for _, portrait in pairs(portraits) do
            if portrait.owner == factionIndex and portrait.name == name then
                canAdd = false
            end
        end

        if canAdd then
            local line = name
            local type
            if factionIndex == player.index then
                type = player:getShipType(name)
            elseif factionIndex == player.allianceIndex then
                type = player.alliance:getShipType(name)
            end

            if type == EntityType.Ship then
                line = string.format("%s (Ship)"%_t, name)
            elseif type == EntityType.Station then
                line = string.format("%s (Station)"%_t, name)
            end

            transferCargoData[line] = name
            transferCargoCombo:addEntry(factionIndex, line, color)
        end
    end
end


function MapCommands.onTransferCargoWindowOKButtonPressed()
    local player = Player()

    local factionIndex = transferCargoCombo.selectedValue
    local craftLine = transferCargoCombo.selectedEntry
    local craftName = transferCargoData[craftLine]

    MapCommands.clearOrdersIfNecessary(not enqueueNextOrder) -- clear if not enqueueing
    MapCommands.enqueueOrder("addTransferCargoOrder", factionIndex, craftName)
    if not enqueueNextOrder then MapCommands.runOrders() end

    transferCargoWindow:hide()
end

end