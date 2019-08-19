package.path = package.path .. ";data/scripts/lib/?.lua"

function execute(sender, commandName, ...)
    Player(sender):addScriptOnce("debugTarget.lua")
    return 0, "", ""
end

function getDescription()
    return "Attach entitydbg to selected entity"
end

function getHelp()
    return "Attach entitydbg to selected entity"
end
