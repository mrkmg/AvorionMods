return function(node, rowSplits, colSplits, rowMargin, colMargin)
    local nodes = {}
    for _, rowNode in pairs({node:rows(rowSplits, rowMargin)}) do
        table.insert(nodes, {rowNode:cols(colSplits, colMargin)})
    end
    return unpack(nodes)
end