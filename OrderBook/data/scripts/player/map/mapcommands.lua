
if onServer() then
    local MapCommands_intialize_OrderBook_orig = MapCommands.initialize
    function MapCommands.initialize()
        MapCommands_intialize_OrderBook_orig()
        Player():addScriptOnce("data/scripts/player/map/orderbook.lua")
    end
end

local MapCommands_hideOrderbuttons_OrderBook_orig = MapCommands.hideOrderButtons
function MapCommands.hideOrderButtons()
    MapCommands_hideOrderbuttons_OrderBook_orig()
    OrderBook.hideOrderButtons()
end