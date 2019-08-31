-- TradeBeacons
-- by Kevin Gravier (MrKMG)
-- MIT License 2019

local Queue = {}
Queue.__index = Queue

local function new(comparer)
    return setmetatable({
        data = {},
        nextIndex = 1,
        lastIndex = 0,
        count = 0,
        comparer = comparer
    }, Queue)
end

function Queue:insert(element)
    self.lastIndex = self.lastIndex + 1
    self.data[self.lastIndex] = element
    self.count = self.count + 1
end

function Queue:next()
    if self.nextIndex > self.lastIndex then
        return nil
    end
    local item = self.data[self.nextIndex]
    self.data[self.nextIndex] = nil
    self.nextIndex = self.nextIndex + 1
    self.count = self.count - 1
    return item
end

function Queue:length()
    return self.count
end

function Queue:isEmpty()
    return self.count == 0
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
