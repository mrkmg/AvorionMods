local remasteredShips = {}
remasteredShips[-1] = {"swarmer"}
remasteredShips[1] = {"corvette_1", "corvette_2", "corvette_3", "corvette_4"}
remasteredShips[2] = {"frigate_1", "frigate_2"}
remasteredShips[3] = {"destroyer_1"}
remasteredShips[4] = {"cruiser_1", "cruiser_2"}
remasteredShips[5] = {"battle_carrier"}

function PlanGenerator.makeXsotanShipPlan(volume, material)
    local volumes = PlanGenerator.getMaxVolumes()
    local targetSize = 5

    if volume < volumes[3] then
        targetSize = 1
    elseif volume < volumes[4] then
        targetSize = 2
    elseif volume < volumes[5] then
        targetSize = 3
    elseif volume < volumes[6] then
        targetSize = 4
    else
        targetSize = 5
    end

    local targetList = remasteredShips[targetSize]
    local targetPlan = targetList[getInt(1, #targetList)]

    return PlanGenerator.makeXsotanShipPlanRemastered(targetPlan, volume, material)
end

function PlanGenerator.makeXsotanCarrierPlan(volume, material)
    return PlanGenerator.makeXsotanShipPlanRemastered("battle_carrier", volume, material)
end

function PlanGenerator.makeXsotanShipPlanRemastered(type, volume, material)
    local plan = LoadPlanFromFile("data/plans/xsotan_remastered/" .. type ..".xml")

    plan:setMaterialTier(material)
    
    local initialScale = volume / plan.volume

    local scale = initialScale
    if type == remasteredShips[1] then scale = initialScale * 2
    elseif type == remasteredShips[2] then scale = initialScale * 3
    elseif type == remasteredShips[3] then scale = initialScale * 3 
    elseif type == remasteredShips[4] then scale = initialScale * 3
    elseif type == remasteredShips[5] then scale = initialScale * 3
    end
    
    plan:scale(vec3(scale, scale, scale))
    return plan
end

-- From ShipUtility
function PlanGenerator.getMaxVolumes()
    local maxVolumes = {}

    local base = 2000
    local scale = 2.5

    -- base class (explorer)
    maxVolumes[1] = base * math.pow(scale, -3.0)
    maxVolumes[2] = base * math.pow(scale, -2.0)
    maxVolumes[3] = base * math.pow(scale, -1.0)
    maxVolumes[4] = base * math.pow(scale, 0.0)
    maxVolumes[5] = base * math.pow(scale, 1.0)
    maxVolumes[6] = base * math.pow(scale, 2.0)
    maxVolumes[7] = base * math.pow(scale, 2.5)
    maxVolumes[8] = base * math.pow(scale, 3.0)
    maxVolumes[9] = base * math.pow(scale, 3.5)
    maxVolumes[10] = base * math.pow(scale, 4.0)
    maxVolumes[11] = base * math.pow(scale, 4.5)
    maxVolumes[12] = base * math.pow(scale, 5.0)

    return maxVolumes
end