local Queue = {}
Queue.__index = Queue

local function new(comparer)
    return setmetatable({
        data = {},
        index = 1,
        last = 0,
        comparer = comparer
    }, Queue)
end

function Queue:insert(element)
    self.last = self.last + 1
    self.data[self.last] = element
end

function Queue:next()
    if self.index > self.last then
        return nil
    end
    local item = self.data[self.index]
    self.data[self.index] = nil
    self.index = self.index + 1
    return item
end

function Queue:length()
    return self.last - self.index + 1
end

function Queue:isEmpty()
    return self:length() > 0
end

function Queue:contains(element)
    for _, dataElement in pairs(self.data) do
        if self.comparer ~= nil then
            if self.comparer(dataElement, element) then
                return true
            end
        elseif dataElement == element then
            return true
        end
    end

    return false
end

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})
