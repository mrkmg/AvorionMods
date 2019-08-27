local SimpleBuffer = {}
SimpleBuffer.__index = SimpleBuffer

local function new()
    return setmetatable({data = {}, index = 0, last = 0}, SimpleBuffer)
end

function SimpleBuffer:insert(element)
    self.last = self.index + 1
    self.data[self.last] = element
    self.index = self.index + 1
end

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})
