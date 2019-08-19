-- CraftOrdersLib - by Kevin Gravier (MrKMG)

local moddedCraftOrders = {}

function CraftOrders.registerModdedCraftOrder(id, orderDetails)
    if moddedCraftOrders[id] == nil then
        moddedCraftOrders[id] = orderDetails
    end
end

function CraftOrders.initUI()    
    local numModdedCraftOrders = 0
    for _,_ in pairs(moddedCraftOrders) do
        numModdedCraftOrders = numModdedCraftOrders + 1
    end

    local res = getResolution()
    local size = vec2(250, 370 + (numModdedCraftOrders * 20))

    local menu = ScriptUI()
    local window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    menu:registerWindow(window, "Orders"%_t)

    window.caption = "Craft Orders"%_t
    window.showCloseButton = 1
    window.moveable = 1

    local splitter = UIHorizontalMultiSplitter(Rect(window.size), 10, 10, 8 + numModdedCraftOrders)

    window:createButton(splitter:partition(0), "Idle"%_t, "onUserIdleOrder")
    window:createButton(splitter:partition(1), "Passive"%_t, "onUserPassiveOrder")
    window:createButton(splitter:partition(2), "Guard This Position"%_t, "onUserGuardOrder")
    window:createButton(splitter:partition(3), "Patrol Sector"%_t, "onUserPatrolOrder")
    window:createButton(splitter:partition(4), "Escort Me"%_t, "onUserEscortMeOrder")
    window:createButton(splitter:partition(5), "Attack Enemies"%_t, "onUserAttackEnemiesOrder")
    window:createButton(splitter:partition(6), "Mine"%_t, "onUserMineOrder")
    window:createButton(splitter:partition(7), "Salvage"%_t, "onUserSalvageOrder")
    window:createButton(splitter:partition(8), "Refine Ores"%_t, "onUserRefineOresOrder")

    local index = 9

    for _, craftOrder in pairs(moddedCraftOrders) do
        window:createButton(splitter:partition(index), craftOrder.title, craftOrder.callback)
        index = index + 1
    end
end

function CraftOrders.removeSpecialOrders()
    local entity = Entity()

    for index, name in pairs(entity:getScripts()) do
        --Fix for path issues on windows
        local fixedName = string.gsub(name, "\\", "/")
        if string.match(fixedName, "data/scripts/entity/ai/") then
            entity:removeScript(index)
        end
    end
end