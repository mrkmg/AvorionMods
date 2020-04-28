-- CraftOrdersLib
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

local moddedMapRoutes = {}

function MapRoutes.registerModdedMapRoute(id, maprouteDef)
    if moddedMapRoutes[id] == nil then
        moddedMapRoutes[id] = maprouteDef
    end
end

if onClient() then

local MapRoutes_getOrderDescription_CraftOrdersLib_orig = MapRoutes.getOrderDescription
function MapRoutes.getOrderDescription(order, i, line)
    if moddedMapRoutes[order.action] ~= nil then
        MapRoutes[moddedMapRoutes[order.action].orderDescriptionFunction](order, i, line)
    else
        MapRoutes_getOrderDescription_CraftOrdersLib_orig(order, i, line)
    end
end

end
