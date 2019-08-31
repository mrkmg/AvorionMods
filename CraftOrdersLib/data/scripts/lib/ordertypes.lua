-- CraftOrdersLib
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

function registerModdedOrderType(name, definition)
    if OrderType[name] == nil then
        OrderTypes[OrderType.NumActions] = definition
        OrderType[name] = OrderType.NumActions
        OrderType.NumActions = OrderType.NumActions + 1
    end
end
