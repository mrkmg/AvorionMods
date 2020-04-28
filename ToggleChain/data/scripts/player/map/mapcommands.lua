
local _isEnqueueing = false
function MapCommands.isEnqueueing()
    return _isEnqueueing
end

function MapCommands.onGalaxyMapKeyboardEvent(key, pressed)
    if pressed then
        if key == KeyboardKey.LShift or key == KeyboardKey.RShift then
            _isEnqueueing = not _isEnqueueing
            playSound("interface/confirm_order", SoundType.UI, 0.75)
        end

    end
    
    if not pressed and not _isEnqueueing then
        MapCommands.runOrders()
    end
end

local MapCommands_hideOrderButtons_ToggleChain_orig = MapCommands.hideOrderButtons
function MapCommands.hideOrderButtons()
    MapCommands_hideOrderButtons_ToggleChain_orig()
    _isEnqueueing = false
end