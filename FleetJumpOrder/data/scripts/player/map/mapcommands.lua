-- Fleet Jump through Gate Command Mod by MassCraxx
-- v3
-- made compatible with CraftOrdersLib by Kevin Gravier (MrKMG)

include ("OrderTypes")

MapCommands.registerModdedMapCommand(OrderType.FlyThroughWormhole, {
    tooltip = "Wormhole"%_t,
    icon = "data/textures/icons/wormhole.png",
    callback = "onWormholePressed",
    shouldHideCallback = "shouldHideWormholeCallback"
})

if onClient() then

function MapCommands.onWormholePressed()
    MapCommands.clearOrdersIfNecessary()
    MapCommands.enqueueOrder("addWormholeOrder")
end

function MapCommands.shouldHideWormholeCallback(selected)
    return MapCommands.isEnqueueing()
end

function MapCommands.getCommandsFromInfo(info, x, y)
    if not info then return {} end
    if not info.chain then return {} end
    if not info.coordinates then return {} end

    local cx, cy = info.coordinates.x, info.coordinates.y
    local i = info.currentIndex

    local result = {}
    while i > 0 and i <= #info.chain do
        local current = info.chain[i]

        if cx == x and cy == y then
            table.insert(result, current)
        end

        if current.action == OrderType.Jump or current.action == OrderType.FlyThroughWormhole then
            cx, cy = current.x, current.y
        end

        i = i + 1
    end

    return result
end

end -- onClient()
