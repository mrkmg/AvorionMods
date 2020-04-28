package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
include ("basesystem")
include ("randomext")
include ("utility")

FixedEnergyRequirement = false
Unique = true

local configCheckTimeout = 2
local configSkipTimeout = 5
local configRectColor = ColorRGB(1, 1, 1)

local checkTimeout = 0
local skipTimeout = 0
local wantsSkip = false
local skipTarget

---- @type SoundSource
local chargeSoundSource

function getMaxRange(seed, rarity, permanent)
    if rarity.value < 1 then return 0 end
    math.randomseed(seed)
    if permanent then
        return 1500 * rarity.value * getFloat(0.8, 1.2)
    end

    return 1000 * rarity.value * getFloat(0.6, 1.4)
end

function getIcon(seed, rarity)
    return "data/textures/icons/skip.png"
end

function getEnergy(seed, rarity, permanent)
    local num = getMaxRange(seed, rarity, permanent)
    if wantsSkip then
        return num * 30000000 / (1.2 ^ rarity.value)
    else
        return num * 3000000 / (1.2 ^ rarity.value)
    end
end

function onInstalled(seed, rarity, permanent)
    Player():registerCallback("onPreRenderHud", "onPreRenderHud")
    
    if onClient() then
        chargeSoundSource = SoundSource("skip", Entity().position.pos, 300)
        chargeSoundSource.volume = 1.0
    end
end

function onUninstalled(seed, rarity, permanent)
    if chargeSoundSource then
        chargeSoundSource:terminate()
    end
end

function getName(seed, rarity)
    return "Jump Drive Skip Targeter"%_t
end

function getPrice(seed, rarity)
    local num = getMaxRange(seed, rarity, true)
    return 8 * num * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity, permanent)
    return
    {
        {ltext = "Skip Distance"%_t, rtext = getRangeLabel(seed, rarity, permanent), icon = getIcon(seed, rarity), boosted = permanent}
    },
    {
        {ltext = "Skip Distance"%_t, rtext = getRangeLabel(seed, rarity, true), icon = getIcon(seed, rarity)}
    }
end

function getDescriptionLines(seed, rarity, permanent)
    return
    {
        {ltext = "Adds the ability for short distance, in system jumps."%_t, rtext = "", icon = ""},
        {ltext = "", rtext = "", icon = ""},
        {ltext = "To use: Select a target, point towards it, and"%_t, rtext = "", icon = ""},
        {ltext = "then press Control+Space."%_t, rtext = "", icon = ""},
        {ltext = ""%_t, rtext = "", icon = ""},
        {ltext = "Uses 10x power for 5s while charging the skip jump."%_t, rtext = "", icon = ""}
    }
end

function getComparableValues(seed, rarity)
    return 
        {
            name = "Skip Distance"%_t,
            key = "skip_distance", 
            value = getMaxRange(seed, rarity, false), 
            comp = UpgradeComparison.MoreIsBetter
        },{
            name = "Skip Distance"%_t,
            key = "skip_distance", 
            value = getMaxRange(seed, rarity, true), 
            comp = UpgradeComparison.MoreIsBetter
        }
end

function getUpdateInterval()
    if Entity():getPilotIndices() == nil then 
        return 5
    else
        return 0
    end
end

function updateClient(timeStep)
    if Entity():getPilotIndices() == nil then return end

    if not wantsSkip then
        if checkTimeout > 0 then
            checkTimeout = checkTimeout - timeStep
            return
        end
    
        local k = Keyboard()
        if k:keyPressed(KeyboardKey.Space) and (k:keyPressed(KeyboardKey.LControl) or k:keyPressed(KeyboardKey.RControl)) then
            checkTimeout = configCheckTimeout
            startSkip()
        end

        return
    end

    if skipTimeout > 0 then
        skipTimeout = skipTimeout - timeStep
        local r, e = validateSkip()
        if not r then
            chargeSoundSource:stop()
            wantsSkip = false
            sendError(e)
        end
        chargeSoundSource.position = Entity().position.pos
        return
    end

    executeSkip()
end

function validateSkip()
    local me = Entity()

    if not valid(skipTarget) then
        return false, "Target Not found."
    end

    local e = EnergySystem(me.index)
    if e.energy < 10 then
        return false, "Out of power, skip jump aborted."
    end

    local d = dot(me.position.look, normalize(skipTarget.position.pos - me.position.pos))

    if d < 0.995 then
        return false, "Must be facing target."
    end

    local dist = distance(me.position.pos, skipTarget.position.pos)
    if dist > getMaxRange(getSeed(), getRarity(), getPermanent()) then
        return false, "Out of range."
    end

    return true, ""
end

function onPreRenderHud()
    if wantsSkip then
        local res = getResolution()
        local ratio = 1 - skipTimeout / configSkipTimeout
        local c = round((ratio * 1000) % 100) / 50
        if c > 1 then c = 2 - c end
        c = c / 10
        local renderer = UIRenderer()
        renderer:renderRect(vec2(0,0), res, ColorARGB(ratio, c, c, c), 0)
        renderer:renderEntityTargeter(skipTarget, ColorRGB(0, 0.5, 1))
        renderer:display()
    end
end

function executeSkip()
    local me = Entity()
    local dist = distance(me.position.pos, skipTarget.position.pos)
    local offset = length(me.size) + length(skipTarget.size) * 2
    offset = math.min(300, offset)
    me:moveBy(me.position.look * dist - offset)
    wantsSkip = false
    chargeSoundSource:stop()
    playSound("boost_startship", 0, 1)
end

function startSkip()
    ----@type Entity       
    local me = Entity()
    if not me then return end
    
    if not me.selectedObject then
        return
    end

    local target = Entity(me.selectedObject.index)

    if not valid(target) then
        sendError("Invalid Target.")
        return
    end

    wantsSkip = true
    skipTimeout = configSkipTimeout
    skipTarget = target
    chargeSoundSource:play()
end

function getRangeLabel(seed, rarity, permanent)
    local p = getMaxRange(seed, rarity, permanent)
    return round(p/100, 2) .. "km"
end

function sendError(msg)
    if onClient() then
        invokeServerFunction("sendError", msg)
    else
        if callingPlayer then
            Player(callingPlayer):sendChatMessage("", ChatMessageType.Error, msg)
        end
    end
    
end
callable(Skip, "sendError")
