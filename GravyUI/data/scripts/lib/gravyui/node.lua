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
package.path = package.path .. ";data/scripts/lib/?.lua"

--== Library ==--

local GravyUINode = {
    ---- @type Rect
    rect = nil,
    parentNode = nil,
    childNodes = {},
}
--GravyUINode.__index = GravyUINode
function GravyUINode:__index(ind)
    return self.old__index(self.rect, ind) or GravyUINode[ind]
end

function GravyUINode:new(rect)
    local rectmeta = getmetatable(rect)
    local node = {rect = rect, old__index = rectmeta.__index}
    return setmetatable(node, GravyUINode)
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

    (width: number, height: number)
    (box: Rect)
return function(a, b)
    if b ~= nil then
        a = Rect(vec2(0, 0), vec2(a, b))
    end
    return GravyUINode:new(a)
end
]]

--[[
    The formatting on this return is very picky or it'll throw eof errors in other mods when adding plugins
    (width: number, height: number)
    (box: Rect)
]]
local call = function(_, a, b)
    if b ~= nil then
        a = Rect(vec2(0, 0), vec2(a, b))
    end
    return GravyUINode:new(a)
end
return setmetatable({}, {__call = call})
