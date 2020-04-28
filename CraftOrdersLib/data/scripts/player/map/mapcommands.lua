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

MapCommands.markedX = nil
MapCommands.markedY = nil

local moddedOrders = {}
local moddedOrderButtons = {}

---@type UIContainer
local markedButtonContainer
----@type Picture
local markedSectorIcon

local MapCommands_initUI_CraftOrdersLib_orig = MapCommands.initUI
function MapCommands.initUI()
    MapCommands_initUI_CraftOrdersLib_orig()
    
    for name, details in pairs(moddedMapCommands) do
        table.insert(moddedOrders, {tooltip = details.tooltip, icon = details.icon, callback = details.callback, type = name})
        
        local button = ordersContainer:createRoundButton(Rect(), details.icon, details.callback)
        button.tooltip = details.tooltip
        table.insert(moddedOrderButtons, button)
    end
    
    markedButtonContainer = GalaxyMap():createContainer()
    local rect = Rect()
    local res = getResolution()
    rect.position = vec2(res.x - 120, 20)
    rect.size = vec2(200, 40)
    markedButtonContainer:createButton(rect, "Mark Sector", "onMarkSectorButton")
    -- markedSectorIcon = markedButtonContainer:createRect(Rect(0, 0, 10, 10), ColorRGB(0.5, 0, 1))
    markedSectorIcon = markedButtonContainer:createPicture(Rect(0, 0, 20, 20), "data/textures/icons/checkmark.png")
    markedSectorIcon.color = ColorRGB(0.2, 1, 0.2)
    markedSectorIcon.isIcon = true
end

local MapCommands_updateButtonLocations_CraftOrdersLib_orig = MapCommands.updateButtonLocations
function MapCommands.updateButtonLocations()
    MapCommands_updateButtonLocations_CraftOrdersLib_orig()
    MapCommands.updateButtonLocations_CraftOrdersLib()
    MapCommands.renderMarkedSector()
end

local MapCommands_hideOrderButtons_CraftOrdersLib_orig = MapCommands.hideOrderButtons
function MapCommands.hideOrderButtons()
    MapCommands_hideOrderButtons_CraftOrdersLib_orig()
    for _, button in pairs(moddedOrderButtons) do
        button:hide()
    end
end

function MapCommands.updateButtonLocations_CraftOrdersLib()
    local selected = MapCommands.getSelectedPortraits()

    if #craftPortraits == 0 or #selected == 0 then
        return
    end

    local visibleButtons = {}
    local numButtons = 0

    for i = 1, #moddedOrderButtons do
        local button = moddedOrderButtons[i]
        local order = moddedOrders[i]
        local command = moddedMapCommands[order.type]

        if command.shouldHideCallback ~= nil and command.shouldHideCallback ~= "" and MapCommands[command.shouldHideCallback](selected) then
            button:hide()
        else
            table.insert(visibleButtons, button)
        end
    end

    ----@param a Button
    ----@param b Button
    local comp = function(a, b)
            return a.tooltip < b.tooltip
        end
    table.sort(visibleButtons, comp)

    local enqueueing = MapCommands.isEnqueueing()
    local sx, sy = GalaxyMap():getSelectedCoordinatesScreenPosition()
    
    local usedPortraits = craftPortraits
    if enqueueing then
        usedPortraits = selected
        local x, y = MapCommands.getLastLocationFromInfo(selected[1].info)
        if x and y then
            sx, sy = GalaxyMap():getCoordinatesScreenPosition(ivec2(x, y))
        end
    end

    local columns = math.min(#usedPortraits, math.max(4, round(math.sqrt(#usedPortraits))))
    local padding = 10
    local oDiameter = 35
    local showAbove = Keyboard():keyPressed(KeyboardKey.LControl) or Keyboard():keyPressed(KeyboardKey.RControl)
    local offset = vec2(#visibleButtons * oDiameter + (#visibleButtons - 1) * padding, padding * 5)
    local x = 0
    local y = 1 + math.ceil(#usedPortraits / columns)

    offset.x = -offset.x / 2
    offset = offset + vec2(sx, sy)

    for i = 1, #visibleButtons do
        local button = visibleButtons[i]
        local rect = Rect()
        rect.lower = vec2(x * (oDiameter + padding), y * (oDiameter + padding) + (padding * (y - 1))) + offset
        rect.upper = rect.lower + vec2(oDiameter, oDiameter)
        button.rect = rect

        if showAbove then
            MapCommands.mirrorUIElementY(button, sy)
        end

        button:show()

        x = x + 1
    end
end

function MapCommands.onMarkSectorButton()
    local x, y = GalaxyMap():getSelectedCoordinates()
    if MapCommands.markedX == x and MapCommands.markedY == y then
        MapCommands.markedX = nil
        MapCommands.markedY = nil
    else
        MapCommands.markedX = x
        MapCommands.markedY = y
    end
    MapCommands.renderMarkedSector()
end

function MapCommands.renderMarkedSector()
    if MapCommands.markedX == nil or MapCommands.markedY == nil then
        markedSectorIcon:hide()
        return
    end

    local sx, sy = GalaxyMap():getCoordinatesScreenPosition(ivec2(MapCommands.markedX, MapCommands.markedY))
    markedSectorIcon.position = vec2(sx - 10, sy - 10)
    markedSectorIcon:show()
end

end