package.path = package.path .. ";data/scripts/lib/?.lua"

--== Library ==--

local GravyUINode = {
    ---- @type Rect
    rect = nil,
    parentNode = nil,
    childNodes = {}
}
GravyUINode.__index = GravyUINode

function GravyUINode:new(rect)
    return setmetatable({rect = rect}, GravyUINode)
end


function GravyUINode:child(rect)
    local child = self:new(rect)
    child.parentNode = self
    table.insert(self.childNodes, child)
    return child
end

GravyUINode.rows = include("gravyui/plugins/rows")
GravyUINode.cols = include("gravyui/plugins/cols")
GravyUINode.pad = include("gravyui/plugins/pad")
GravyUINode.grid = include("gravyui/plugins/grid")
GravyUINode.offset = include("gravyui/plugins/offset")

--[[
    The formatting on this return is very picky or it'll throw eof errors in other mods when adding plugins
    (width: number, height: number)
    (vec2 constructor)
    (box: Rect)
]]
local call = function(_, a, b)
    if b ~= nil then
        a = Rect(vec2(0, 0), vec2(a, b))
    end
    if a.__avoriontype == 'vec2' then
        a = Rect(vec2(0), a)
    end
    return GravyUINode:new(a)
end
return setmetatable({}, {__call = call})
