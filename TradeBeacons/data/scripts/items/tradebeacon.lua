-- TradeBeacons
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include ("stringutility")
include ("randomext")

-- namespace TradeBeacon
TradeBeacon = {}

function TradeBeacon.getLifespan(rarity)
    if rarity.value == 0 then
        return 1
    elseif rarity.value == 1 then
        return 1.5
    elseif rarity.value == 2 then
        return 2
    elseif rarity.value == 3 then
        return 3
    elseif rarity.value == 4 then
        return 5
    elseif rarity.value == 5 then
        return 8
    end

    return 0.5
end

function TradeBeacon.getPrice(rarity, seed)
    local lifeSpan = TradeBeacon.getLifespan(rarity)
    math.randomseed(seed)
    local lowEnd = 20000 * lifeSpan * lifeSpan
    return getInt(lowEnd, lowEnd + lowEnd * 0.25)
end

function TradeBeacon.getMaterial(rarity)
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

function TradeBeacon.getTraderAffinity(rarity)
    if rarity.value <= 0 then
        return 0
    end

    return rarity.value / 100
end

function TradeBeacon.create(item, rarity, seed)
    item.stackable = true
    item.depleteOnUse = true
    item.name = "Trade Beacon"%_t
    item.price = TradeBeacon.getPrice(rarity, seed)
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
    line.rtext = "${t}h"%_t%{t = TradeBeacon.getLifespan(rarity)}
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

function TradeBeacon.realActivate(craft, item)
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

    local plan = LoadPlanFromFile("data/plans/TradeBeacon.xml")

    plan:forceMaterial(TradeBeacon.getMaterial(item.rarity))

    local s = 15 / plan:getBoundingSphere().radius
    plan:scale(vec3(s, s, s))

    local color = ColorRGB(getFloat(0.25, 1), getFloat(0.25, 1), getFloat(0.25, 1))
    for i = 41,64 do
        plan:setBlockColor(i, color)
    end

    plan.accumulatingHealth = true

    desc.position = getPositionInFront(craft, 50)
    desc:setMovePlan(plan)
    desc.factionIndex = craft.factionIndex
    desc:setValue("lifespan", TradeBeacon.getLifespan(item.rarity))
    desc:setValue("traderAffinity", TradeBeacon.getTraderAffinity(item.rarity))

    local satellite = Sector():createEntity(desc)
    satellite:addScript("entity/tradebeacon.lua")
    local velocity = Velocity(satellite.index)
    velocity:addVelocity(craft.look * 5)
    return true
end

function TradeBeacon.remoteActivate(item)
    local craft = Entity()
    if not valid(craft) then return false end

    return TradeBeacon.realActivate(craft, item)
end

function TradeBeacon.activate(item)
    local craft = Player().craft
    if not craft then return false end

    return TradeBeacon.realActivate(craft, item)
end
