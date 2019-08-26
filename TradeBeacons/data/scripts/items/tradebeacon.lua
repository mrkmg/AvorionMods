package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local PlanGenerator = include("plangenerator")
include("stringutility")

function create(item, rarity)

    rarity = Rarity(RarityType.Exceptional)

    item.stackable = true
    item.depleteOnUse = true
    item.name = "Trade Beacon"%_t
    item.price = 100000
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
    local line = TooltipLine(14, 14)
    tooltip:addLine(line)

    local line = TooltipLine(18, 14)
    line.ltext = "Time"%_t
    line.rtext = "24h"%_t
    line.icon = "data/textures/icons/recharge-time.png"
    line.iconColor = ColorRGB(0.8, 0.8, 0.8)
    tooltip:addLine(line)

    -- empty line
    local line = TooltipLine(14, 14)
    tooltip:addLine(line)

    local line = TooltipLine(18, 14)
    line.ltext = "Can be deployed by the player."%_t
    tooltip:addLine(line)

    local line = TooltipLine(14, 14)
    tooltip:addLine(line)

    local line = TooltipLine(18, 14)
    line.ltext = "Deploy this satellite in a sector"%_t
    tooltip:addLine(line)

    local line = TooltipLine(18, 14)
    line.ltext = "to link the sector to your trade"%_t
    tooltip:addLine(line)

    local line = TooltipLine(18, 14)
    line.ltext = "routes."%_t
    tooltip:addLine(line)


    item:setTooltip(tooltip)

    return item
end

local function getPositionInFront(craft, distance)

    local position = craft.position
    local right = position.right
    local dir = position.look
    local up = position.up
    local position = craft.translationf

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
    local plan = PlanGenerator.makeStationPlan(faction)
    plan:forceMaterial(Material(MaterialType.Iron))

    local s = 15 / plan:getBoundingSphere().radius
    plan:scale(vec3(s, s, s))
    plan.accumulatingHealth = true

    desc.position = getPositionInFront(craft, 20)
    desc:setMovePlan(plan)
    desc.factionIndex = faction.index

    local satellite = Sector():createEntity(desc)
    satellite:addScript("entity/tradebeacon.lua")

    return true
end
