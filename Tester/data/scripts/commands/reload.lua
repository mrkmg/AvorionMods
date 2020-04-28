package.path = package.path .. ";data/scripts/lib/?.lua"

function execute(sender, commandName, type)
    if type == "ob" then
        local player = Player(sender)
        print("Reloading OrderBook")
        player:removeScript("data/scripts/player/map/orderbook.lua")
        player:addScript("data/scripts/player/map/orderbook.lua")
    elseif type == "mc" then
        local player = Player(sender)
        print("Reloading MapCommands")
        player:removeScript("data/scripts/player/map/mapcommands.lua")
        player:addScript("data/scripts/player/map/mapcommands.lua")
    end
    return 0, "", ""
end

function getDescription()
    return "Reloads a script"
end

function getHelp()
    return "Reloads a script. /reload (mc,oc)"
end
