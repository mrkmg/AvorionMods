package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local PlanGenerator = include("plangenerator")
include("stringutility")

function getLifespan(rarity)
    if rarity.value == 1 then
        return 8
    elseif rarity.value == 2 then
        return 12
    elseif rarity.value == 3 then
        return 16
    elseif rarity.value == 4 then
        return 20
    elseif rarity.value == 5 then
        return 24
    elseif rarity.value == 6 then
        return 36
    elseif rarity.value == 7 then
        return 48
    end

    return 2
end

function getPrice(rarity, seed)
    math.randomseed(seed)

    if rarity.value == 1 then
        return getInt(5000, 10000)
    elseif rarity.value == 2 then
        return getInt(15000, 20000)
    elseif rarity.value == 3 then
        return getInt(50000, 70000)
    elseif rarity.value == 4 then
        return getInt(100000, 140000)
    elseif rarity.value == 5 then
        return getInt(300000, 350000)
    elseif rarity.value == 6 then
        return getInt(1000000, 1500000)
    elseif rarity.value == 7 then
        return getInt(10000000, 20000000)
    end

    return getInt(1000, 5000)
end

function getMaterial(rarity)
    if rarity.level == 2 then
        return Material(MaterialType.Titanium)
    elseif rarity.level == 3 then
        return Material(MaterialType.Naonite)
    elseif rarity.level == 4 then
        return Material(MaterialType.Trinium)
    elseif rarity.level == 5 then
        return Material(MaterialType.Xanion)
    elseif rarity.level == 6 then
        return Material(MaterialType.Ogonite)
    elseif rarity.level == 7 then
        return Material(MaterialType.Avorion)
    end
    return Material(MaterialType.Iron)
end

function create(item, rarity, seed)
    item.stackable = true
    item.depleteOnUse = true
    item.name = "Trade Beacon"%_t
    item.price = getPrice(rarity, seed)
    item.icon = "data/textures/icons/satellite.png"
    item.rarity = rarity
    item:setValue("subtype", "TradeBeacon")

    local tooltip = Tooltip()
    tooltip.icon = item.icon

    local title = "Trade Beacon"%_t

    local headLineSize = 25
    local headLineFontSize = 15
    local line = TooltipLine(headLineSize, headLineFontSize)
    line.ctext = title
    line.ccolor = item.rarity.color
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
    line.ltext = "Deploy this satellite in a sector"%_t
    tooltip:addLine(line)

    line = TooltipLine(18, 14)
    line.ltext = "to allow ships with advanced"%_t
    tooltip:addLine(line)

    line = TooltipLine(18, 14)
    line.ltext = "trading system to scan for routes."%_t
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

    local faction = Faction(craft.factionIndex)
    local plan = PlanGenerator.makeBeaconPlan(faction)

    plan:forceMaterial(getMaterial(item.rarity))

    local s = 15 / plan:getBoundingSphere().radius
    plan:scale(vec3(s, s, s))
    plan.accumulatingHealth = true

    desc.position = getPositionInFront(craft, 20)
    desc:setMovePlan(plan)
    desc.factionIndex = faction.index
    desc:setValue("lifespan", getLifespan(item.rarity))

    local satellite = Sector():createEntity(desc)
    satellite:addScript("entity/tradebeacon.lua")

    return true
end
