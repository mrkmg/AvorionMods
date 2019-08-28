package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local PlanGenerator = include("plangenerator")
include("stringutility")

function getLifespan(rarity)
    if rarity.value == 0 then
        return 1
    elseif rarity.value == 1 then
        return 2
    elseif rarity.value == 2 then
        return 4
    elseif rarity.value == 3 then
        return 8
    elseif rarity.value == 4 then
        return 16
    elseif rarity.value == 5 then
        return 32
    end

    return 0.5
end

function getPrice(rarity, seed)
    math.randomseed(seed)

    if rarity.value == 0 then
        return getInt(5000, 10000)
    elseif rarity.value == 1 then
        return getInt(15000, 20000)
    elseif rarity.value == 2 then
        return getInt(50000, 70000)
    elseif rarity.value == 3 then
        return getInt(300000, 400000)
    elseif rarity.value == 4 then
        return getInt(1000000, 1500000)
    elseif rarity.value == 5 then
        return getInt(5000000, 8000000)
    end

    return getInt(1000, 5000)
end

function getMaterial(rarity)
    if rarity.value == 0 then
        return Material(MaterialType.Titanium)
    elseif rarity.value == 1 then
        return Material(MaterialType.Naonite)
    elseif rarity.value == 2 then
        return Material(MaterialType.Trinium)
    elseif rarity.value == 3 then
        return Material(MaterialType.Xanion)
    elseif rarity.value == 4 then
        return Material(MaterialType.Ogonite)
    elseif rarity.value == 5 then
        return Material(MaterialType.Avorion)
    end
    return Material(MaterialType.Iron)
end

function getTraderAffinity(rarity)
    if rarity.value <= 0 then
        return 0
    end

    return rarity.value / 100
end

function create(item, rarity, seed)
    item.stackable = true
    item.depleteOnUse = true
    item.dropable = true
    item.tradeable = true
    item.name = "Trade Beacon"%_t
    item.price = getPrice(rarity, seed)
    item.icon = "data/textures/icons/satellite.png"
    item.rarity = rarity
    item:setValue("subtype", "TradeBeacon")

    local tooltip = Tooltip()
    tooltip.icon = item.icon

    local title = "Trade Beacon"%_t

    -- head line
    local line = TooltipLine(25, 15)
    line.ctext = title
    line.ccolor = rarity.color
    tooltip:addLine(line)

    -- rarity name
    line = TooltipLine(5, 12)
    line.ctext = tostring(rarity)
    line.ccolor = rarity.color
    tooltip:addLine(line)

    -- empty line
    line = TooltipLine(14, 14)
    tooltip:addLine(line)

    line = TooltipLine(18, 14)
    line.ltext = "Time"%_t
    line.rtext = "${t}h"%_t%{t = getLifespan(rarity)}
    line.icon = "data/textures/icons/recharge-time.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    -- empty line
    line = TooltipLine(14, 14)
    tooltip:addLine(line)

    line = TooltipLine(18, 14)
    line.ltext = "Can be deployed by the player."%_t
    tooltip:addLine(line)

    line = TooltipLine(14, 14)
    tooltip:addLine(line)

    line = TooltipLine(18, 14)
    line.ltext = "Deploy this satellite to allow"%_t
    tooltip:addLine(line)

    line = TooltipLine(18, 14)
    line.ltext = "ships with an advanced trading"%_t
    tooltip:addLine(line)

    line = TooltipLine(18, 14)
    line.ltext = "system to scan this sector."%_t
    tooltip:addLine(line)

    item:setTooltip(tooltip)

    return item
end

local function getPositionInFront(craft, distance)

    local position = craft.position
    local right = position.right
    local dir = position.look
    local up = position.up
    position = craft.translationf

    local pos = position + dir * (craft.radius + distance)

    return MatrixLookUpPosition(right, up, pos)
end

function activate(item)

    local craft = Player().craft
    if not craft then return false end

    local desc = EntityDescriptor()
    desc:addComponents(
            ComponentType.Plan,
            ComponentType.BspTree,
            ComponentType.Intersection,
            ComponentType.Asleep,
            ComponentType.DamageContributors,
            ComponentType.BoundingSphere,
            ComponentType.BoundingBox,
            ComponentType.Velocity,
            ComponentType.Physics,
            ComponentType.Scripts,
            ComponentType.ScriptCallback,
            ComponentType.Title,
            ComponentType.Owner,
            ComponentType.Durability,
            ComponentType.PlanMaxDurability,
            ComponentType.InteractionText,
            ComponentType.EnergySystem
    )

    local plan = PlanGenerator.makeBeaconPlan()

    plan:forceMaterial(getMaterial(item.rarity))

    local s = 15 / plan:getBoundingSphere().radius
    plan:scale(vec3(s, s, s))
    plan.accumulatingHealth = true

    desc.position = getPositionInFront(craft, 20)
    desc:setMovePlan(plan)
    desc.factionIndex = craft.factionIndex
    desc:setValue("lifespan", getLifespan(item.rarity))
    desc:setValue("traderAffinity", getTraderAffinity(item.rarity))

    local satellite = Sector():createEntity(desc)
    satellite:addScript("entity/tradebeacon.lua")

    return true
end
