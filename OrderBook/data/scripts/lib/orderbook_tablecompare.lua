-- Taken from https://stackoverflow.com/questions/20325332/how-to-check-if-two-tablesobjects-have-the-same-value-in-lua
-- 2020-04-22
function tablesEqual(tbl1, tbl2)
    if tbl1 == tbl2 then return true end
    local o1Type = type(tbl1)
    local o2Type = type(tbl2)
    if o1Type ~= o2Type then return false end
    if o1Type ~= 'table' then return false end

    local keySet = {}

    for key1, value1 in pairs(tbl1) do
        local value2 = tbl2[key1]
        if value2 == nil or tablesEqual(value1, value2) == false then
            return false
        end
        keySet[key1] = true
    end

    for key2, _ in pairs(tbl2) do
        if not keySet[key2] then return false end
    end
    return true
end

function allTablesEqual(tblOfTbls)
    if #tblOfTbls <= 1 then return true end

    local fTable = tblOfTbls[1]

    for i=2,#tblOfTbls do
        local cTable = tblOfTbls[i]
        if cTable and not tablesEqual(fTable, cTable) then 
            return false 
        end
    end

    return true
end