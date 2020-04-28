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
    obj = {rect = rect, children = {}}
    setmetatable(obj, GravyUINode)
    return obj
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

--[[
    (width: number, height: number)
    (box: Rect)
]]
return function(a, b)
    if b ~= nil then
        a = Rect(vec2(0, 0), vec2(a, b))
    end
    return GravyUINode:new(a)
end