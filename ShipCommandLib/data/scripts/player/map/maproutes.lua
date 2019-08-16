-- ShipCommandsLib - by Kevin Gravier (MrKMG)

local moddedMapRoutes = {}

function MapRoutes.registerModdedMapRoute(id, maprouteDef)
    if moddedMapRoutes[id] ~= nil then
        moddedMapRoutes[id] = maprouteDef
    end
end

if onClient() then

function MapRoutes.getOrderDescription(order, i, line)
    print ("[ShipCommandsLib] MapRoutes.getOrderDescription")
    print ("[ShipCommandsLib] " .. order.action)
    if order.action == OrderType.Jump then
        line.ltext = "[${i}] Jump"%_t % {i=i}
        line.ctext = " >>> "
        line.rtext = order.x .. " : " .. order.y
    elseif order.action == OrderType.Mine then
        line.ltext = "[${i}] Mine Asteroids"%_t % {i=i}
    elseif order.action == OrderType.Salvage then
        line.ltext = "[${i}] Salvage Wreckages"%_t % {i=i}
    elseif order.action == OrderType.Loop then
        line.ltext = "[${i}] Loop"%_t % {i=i}
        line.ctext = " >>> "
        line.rtext = order.loopIndex
    elseif order.action == OrderType.Aggressive then
        line.ltext = "[${i}] Attack Enemies"%_t % {i=i}
    elseif order.action == OrderType.Patrol then
        line.ltext = "[${i}] Patrol Sector"%_t % {i=i}
    elseif order.action == OrderType.BuyGoods then
        line.ltext = "[${i}] Buy '${good}'"%_t % {i = i, good = order.args[1]}
        line.rtext = "Until ${amount} units"%_t % {amount = order.args[3]}
    elseif order.action == OrderType.SellGoods then
        line.ltext = "[${i}] Sell '${good}'"%_t % {i = i, good = order.args[1]}
        line.rtext = "Until ${amount} units"%_t % {amount = order.args[3]}
    elseif order.action == OrderType.RefineOres then
        line.ltext = "[${i}] Refine Ores"%_t % {i = i}
    elseif moddedMapRoutes[order.action] ~= nil then
        MapRoutes[moddedMapRoutes[order.action].orderDescriptionFunction](order, i, line)
    end
end

function MapRoutes.renderIcons()
    print ("[ShipCommandsLib] MapRoutes.renderIcons")
    local map = GalaxyMap()
    local renderer = UIRenderer()

    for name, route in pairs(routesByShip) do
        local info = route.info
        if not info then goto continue end

        local i = info.currentIndex
        local cx, cy = route.start.x, route.start.y
        while i <= #info.chain do

            local current = info.chain[i]
            if not current then break end

            if current.action == OrderType.Jump then
                cx, cy = current.x, current.y
            end

            if current.action then
                local sx, sy = GalaxyMap():getCoordinatesScreenPosition(ivec2(cx, cy))

                local orderType = OrderTypes[current.action]
                if orderType and orderType.pixelIcon and orderType.pixelIcon ~= "" then
                    renderer:renderCenteredPixelIcon(vec2(sx, sy), ColorRGB(1, 1, 1), orderType.pixelIcon)
                elseif moddedMapRoutes[current.action] ~= nil and moddedMapRoutes[current.action].pixelIcon then
                    renderer:renderCenteredPixelIcon(vec2(sx, sy), ColorRGB(1, 1, 1), moddedMapRoutes[current.action].pixelIcon)
                end
            end

            i = i + 1
        end

        ::continue::
    end

    renderer:display()
end

end