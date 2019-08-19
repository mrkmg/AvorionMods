
function initialize()
    local ship = Player(sender).selectedObject
    if ship == nil or not valid(ship) then return 0,"","" end


    if ship.type ~= EntityType.Ship and ship.type ~= EntityType.Station then return 0,"","" end


    if not ship:hasScript("data/scripts/lib/entitydbg.lua") then
        ship:addScript("data/scripts/lib/entitydbg.lua")
    end
    terminate()
end